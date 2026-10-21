#=====================================================================#
# MACHINE AND USER SETTINGS LOADER
#=====================================================================#
#- Reads machines/<name>/settings.nix and the settings.nix of each user it
#- lists. The two _template files hold every setting there is: anything a
#- file leaves out is off (false), empty or null. A typo or a wrong kind
#- of value stops the build with a message naming the file and the setting.
{lib}: let
  #--------------------------------------------------------------------#
  #-- Defaults
  #--------------------------------------------------------------------#
  #--- A template with every true/false turned off
  allOff = value:
    if lib.isBool value
    then false
    else if lib.isAttrs value
    then lib.mapAttrs (_: allOff) value
    else value;

  machineDefaults = allOff (removeAttrs (import ../machines/_template/settings.nix) ["users"]);
  userDefaults = allOff (import ../users/_template/settings.nix);

  #--- Settings that take one of a few values
  choices = {
    windowManager = ["niri"];
    kernel = ["zen" "latest" "xanmod" "cachyos"];
    cursor = ["bibata" "catppuccin"];
    cursorSize = [24 32 48 64];
    "gpu.type" = [null "amd" "intel" "nvidia" "amd+nvidia" "intel+nvidia"];
  };
  #--- Lists whose items must come from a known set
  listChoices = {
    "blocklist.extra" = ["fakenews" "gambling" "porn" "social"];
    #--- localAi.code and .chat: models lib/local-models.nix lists
    "localAi.code" = lib.attrNames (import ./local-models.nix).code;
    "localAi.chat" = lib.attrNames (import ./local-models.nix).chat;
  };
  portLists = ["firewall.openTCPPorts" "firewall.openUDPPorts"];
  userChoices =
    {
      wallpaper = ["carousel" "engine"];
    }
    #--- defaultApps.<kind>: the app names lib/default-apps.nix lists
    // lib.mapAttrs' (kind: candidates: lib.nameValuePair "defaultApps.${kind}" (map (c: c.name) candidates))
    (import ./default-apps.nix {inherit lib;}).apps
    #--- localAi.edit: none, or a model lib/local-models.nix lists
    // {"localAi.edit" = [null] ++ lib.attrNames (import ./local-models.nix).edit;};

  #--------------------------------------------------------------------#
  #-- Checks
  #--------------------------------------------------------------------#
  describe = value:
    if lib.isBool value
    then "true or false"
    else if lib.isString value
    then "text in quotes"
    else if lib.isList value
    then "a list in [ ]"
    else if lib.isInt value
    then "a whole number"
    else "a set in { }";

  #--- One line for each setting in `set` that `defaults` lacks or types differently
  problems = defaults: set: path:
    lib.concatLists (lib.mapAttrsToList (key: value: let
      at = path ++ [key];
      name = "`${lib.concatStringsSep "." at}`";
    in
      if !(defaults ? ${key})
      then ["${name} is not a setting (check the spelling against the _template file)"]
      else if defaults.${key} == null
      then []
      else if lib.isAttrs defaults.${key} && lib.isAttrs value
      then problems defaults.${key} value at
      else if builtins.typeOf value != builtins.typeOf defaults.${key}
      then ["${name} should be ${describe defaults.${key}}"]
      else [])
    set);

  badChoices = choices: set:
    lib.concatLists (lib.mapAttrsToList (path: allowed: let
      value = lib.attrByPath (lib.splitString "." path) null set;
      show = lib.concatMapStringsSep ", " builtins.toJSON allowed;
    in
      lib.optional (!(lib.elem value allowed)) "`${path}` is ${builtins.toJSON value}; use one of ${show}")
    choices);

  #--- One line per list setting holding an item it can't take
  listAt = path: set: let
    value = lib.attrByPath (lib.splitString "." path) [] set;
  in
    if lib.isList value
    then value
    else [];
  badLists = set:
    lib.concatLists (lib.mapAttrsToList (path: allowed: let
      wrong = lib.filter (v: !(lib.elem v allowed)) (listAt path set);
    in
      lib.optional (wrong != [])
      "`${path}` has ${builtins.toJSON wrong}; use only ${lib.concatMapStringsSep ", " builtins.toJSON allowed}")
    listChoices)
    ++ lib.concatMap (path: let
      wrong = lib.filter (v: !(lib.isInt v && v >= 1 && v <= 65535)) (listAt path set);
    in
      lib.optional (wrong != []) "`${path}` has ${builtins.toJSON wrong}; use port numbers from 1 to 65535")
    portLists;

  #--- Stops evaluation with every problem found in `file`
  report = file: lines:
    lib.assertMsg (lines == []) "\n${file}:\n${lib.concatMapStrings (line: "  - ${line}\n") lines}";

  #--- True/false settings OR-ed across users; other settings have no such value
  anyOf = values:
    if lib.all lib.isBool values
    then lib.any lib.id values
    else if lib.all lib.isAttrs values
    then lib.zipAttrsWith (_: anyOf) values
    else null;
in {
  #--- The allowed values, for tools that edit the settings files
  inherit choices userChoices listChoices;

  #--------------------------------------------------------------------#
  #-- Machine
  #--------------------------------------------------------------------#
  #- `machine`: the machine's settings plus its folder name, with each user's
  #- final settings in machine.users. `anyUser`: each true/false user setting,
  #- true when at least one user on the machine has it on.
  forMachine = name: let
    file = "machines/${name}/settings.nix";
    own = import ../machines/${name}/settings.nix;
    listed = own.users or {};
    names = lib.attrNames listed;
    userFile = user: "users/${user}/settings.nix";
    missing = lib.filter (user: !builtins.pathExists ../users/${user}/settings.nix) names;

    #--- Defaults, then the user's own file, then this machine's changes
    resolveUser = user:
      lib.recursiveUpdate
      (lib.recursiveUpdate userDefaults (import ../users/${user}/settings.nix))
      listed.${user}
      // {name = user;};

    merged = lib.recursiveUpdate machineDefaults (removeAttrs own ["users"]);
    mainUser =
      if merged.mainUser != null
      then merged.mainUser
      else if lib.length names == 1
      then lib.head names
      else null;

    machine =
      merged
      // {
        inherit name mainUser;
        users = lib.genAttrs names resolveUser;
        hostName =
          if merged.hostName != null
          then merged.hostName
          else name;
        flakePath =
          if merged.flakePath != null
          then merged.flakePath
          else "/etc/nixos-config";
      };

    machineProblems =
      problems machineDefaults (removeAttrs own ["users"]) []
      ++ lib.optional (names == []) "`users` is empty; list at least one, e.g. users = {alice = {};};"
      ++ map (user: "`users.${user}`: there is no ${userFile user} (run ./setup.sh add-user)") missing
      ++ lib.concatMap (user: map (line: "in `users.${user}`: ${line}") (problems userDefaults listed.${user} [])) names
      ++ lib.optional (mainUser == null && names != []) "several users are listed, so set mainUser to the one who owns this config"
      ++ lib.optional (mainUser != null && !(listed ? ${mainUser})) "mainUser `${toString mainUser}` is not listed in `users`"
      ++ lib.optional (!lib.isString merged.stateVersion) "set stateVersion (in quotes) to the system.stateVersion line in /etc/nixos/configuration.nix"
      ++ badChoices choices merged
      ++ badLists merged;
  in
    assert report file machineProblems;
    assert lib.all (user: report (userFile user) (problems userDefaults (import ../users/${user}/settings.nix) [])) names;
    assert lib.all (user: report (userFile user) (badChoices userChoices machine.users.${user})) names;
    assert report file (lib.optional (!machine.users.${mainUser}.admin)
      "the main user `${mainUser}` needs admin = true (in ${userFile mainUser}), or nobody here can rebuild the system"); {
      inherit machine;
      anyUser = anyOf (lib.attrValues machine.users);
    };
}
