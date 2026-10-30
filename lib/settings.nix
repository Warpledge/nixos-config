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
    "battery.chargeLimit" = [null 60 70 80 90];
    "gpu.type" = [null "amd" "intel" "nvidia" "amd+nvidia" "intel+nvidia"];
  };
  #--- Lists whose items must come from a known set
  listChoices = {
    "blocklist.extra" = ["fakenews" "gambling" "porn" "social"];
    #--- localAi.code and .chat: models lib/local-models.nix lists
    "localAi.code" = lib.attrNames (import ./local-models.nix).code;
    "localAi.chat" = lib.attrNames (import ./local-models.nix).chat;
    #--- MangoHud.conf's display items (gaming/default.nix)
    "mangohud.show" = [
      "fps"
      "frametime"
      "frame_timing"
      "cpu_stats"
      "cpu_temp"
      "cpu_power"
      "cpu_mhz"
      "gpu_stats"
      "gpu_temp"
      "gpu_power"
      "gpu_core_clock"
      "gpu_name"
      "vram"
      "ram"
      "battery"
      "gamemode"
      "resolution"
      "time"
      "wine"
      "engine_version"
      "vulkan_driver"
      "show_fps_limit"
    ];
  };
  portLists = ["firewall.openTCPPorts" "firewall.openUDPPorts"];
  #--- Lists of domain names; the pattern is networking.stevenblack.whitelist's
  domainLists = ["blocklist.allow"];
  #--- Whole-number machine settings and the range each takes
  numberRanges = {
    "boot.menu.timeout" = [0 60];
    "boot.menu.entries" = [1 50];
    "mangohud.fontSize" = [8 64];
    "mangohud.background" = [0 100];
  };
  #--- Sets of named lists of text, e.g. userPackages = {Media = ["vlc"];};
  #--- a machine's users.<name> block replaces the user's whole set
  grouped = ["userPackages" "autostart"];
  #--- Sets of named text, e.g. env = {EDITOR = "zeditor";}; replaced the same way
  textSets = ["env" "mimeTypes"];
  #--- Changes to niri keybinds by id (wm/niri/home/core/keybinds.nix), also
  #--- replaced whole by a machine's users.<name> block
  keybindFields = {
    key = lib.isString;
    title = lib.isString;
    enable = lib.isBool;
    spawn = v: lib.isList v && v != [] && lib.all lib.isString v;
    action = lib.isString;
    argument = lib.isString;
  };
  keybindProblems = value:
    if !(lib.isAttrs value && lib.all lib.isAttrs (lib.attrValues value))
    then ["`keybinds` should be a set of sets, e.g. {terminal = {key = \"Mod+Alt+T\";};}"]
    else
      lib.concatLists (lib.mapAttrsToList (id: b: let
        at = "`keybinds.${id}`";
        custom = lib.hasPrefix "custom-" id;
        allowed =
          if custom
          then lib.attrNames keybindFields
          else ["key" "title" "enable"];
      in
        map (k: "${at} can't set ${k} (use ${lib.concatStringsSep ", " allowed})")
        (lib.filter (k: !(lib.elem k allowed)) (lib.attrNames b))
        ++ map (k: "`keybinds.${id}.${k}` has the wrong kind of value")
        (lib.filter (k: lib.elem k allowed && !(keybindFields.${k} b.${k})) (lib.attrNames b))
        ++ lib.optional (custom && !(b ? key && b ? title))
        "${at} needs a key and a title"
        ++ lib.optional (custom && (b ? spawn) == (b ? action))
        "${at} needs one of spawn or action"
        ++ lib.optional (b ? argument && !(b ? action))
        "${at} has an argument but no action")
      value);
  #--- Changes to niri window rules by id (wm/niri/home/core/window-rules.nix):
  #--- {enable = false;} or a whole rule; replaced whole by a users.<name> block
  windowRuleProblems = value: let
    matchList = v: lib.isList v && lib.all lib.isAttrs v;
  in
    if !(lib.isAttrs value && lib.all lib.isAttrs (lib.attrValues value))
    then ["`windowRules` should be a set of sets, e.g. {minecraft-fullscreen = {enable = false;};}"]
    else
      lib.concatLists (lib.mapAttrsToList (id: r: let
        at = "`windowRules.${id}`";
      in
        lib.optional (lib.hasPrefix "custom-" id && !(r ? matches))
        "${at} needs matches, a list of windows like [{app-id = \"^mpv$\";}]"
        ++ lib.optional (r ? matches && !(matchList r.matches))
        "${at}.matches should be a list of sets"
        ++ lib.optional (r ? excludes && !(matchList r.excludes))
        "${at}.excludes should be a list of sets"
        ++ lib.optional (r ? enable && !(lib.isBool r.enable))
        "${at}.enable should be true or false"
        ++ map (k: "${at}.${k} should be text in quotes")
        (lib.filter (k: r ? ${k} && !(lib.isString r.${k})) ["name" "note" "category"]))
      value);
  #--- Changes to the Mod+A side rail's apps by id (dms/plugins/side-rail/apps.nix);
  #--- replaced whole by a users.<name> block
  sideRailFields = {
    enable = lib.isBool;
    order = lib.isInt;
    width = v: lib.isInt v && v > 0;
    keepRunning = lib.isBool;
    unloadAfter = v: lib.isInt v && v > 0;
    name = lib.isString;
    icon = lib.isString;
    appId = lib.isString;
    url = lib.isString;
    command = v: lib.isList v && v != [] && lib.all lib.isString v;
  };
  sideRailProblems = value:
    if !(lib.isAttrs value && lib.all lib.isAttrs (lib.attrValues value))
    then ["`sideRail` should be a set of sets, e.g. {brave-ai = {enable = false;};}"]
    else
      lib.concatLists (lib.mapAttrsToList (id: e: let
        at = "`sideRail.${id}`";
        custom = lib.hasPrefix "custom-" id;
        allowed =
          if custom
          then lib.attrNames sideRailFields
          else ["enable" "order" "width" "keepRunning" "unloadAfter"];
      in
        map (k: "${at} can't set ${k} (use ${lib.concatStringsSep ", " allowed})")
        (lib.filter (k: !(lib.elem k allowed)) (lib.attrNames e))
        ++ map (k: "`sideRail.${id}.${k}` has the wrong kind of value")
        (lib.filter (k: lib.elem k allowed && !(sideRailFields.${k} e.${k})) (lib.attrNames e))
        ++ lib.optional (custom && !(e ? name))
        "${at} needs a name"
        ++ lib.optional (custom && e ? command && !(e ? appId))
        "${at} needs the appId its command's window opens with"
        ++ lib.optional (custom && (e ? url) == (e ? command))
        "${at} needs one of url or command")
      value);
  #--- Launch options and Proton build per Steam app id (gaming/steam-games.nix);
  #--- replaced whole by a users.<name> block
  steamGameProblems = value:
    if !(lib.isAttrs value && lib.all lib.isAttrs (lib.attrValues value))
    then ["`steamGames` should be a set of sets, e.g. {\"1245620\" = {launchOptions = \"%command%\";};}"]
    else
      lib.concatLists (lib.mapAttrsToList (id: g:
        lib.optional (builtins.match "[0-9]+" id == null)
        "`steamGames.${id}` should be a Steam app id, a number in quotes"
        ++ map (k: "`steamGames.${id}` can't set ${k} (use launchOptions, proton)")
        (lib.filter (k: !(lib.elem k ["launchOptions" "proton"])) (lib.attrNames g))
        ++ map (k: "`steamGames.${id}.${k}` should be text in quotes")
        (lib.filter (k: g ? ${k} && !(lib.isString g.${k})) ["launchOptions" "proton"]))
      value);
  userChoices =
    {
      wallpaper = ["carousel" "engine"];
      "mangohud.position" = ["top-left" "top-center" "top-right" "middle-left" "middle-right" "bottom-left" "bottom-center" "bottom-right"];
    }
    #--- defaultApps.<kind>: the app names lib/default-apps.nix lists
    // lib.mapAttrs' (kind: candidates: lib.nameValuePair "defaultApps.${kind}" (map (c: c.name) candidates))
    (import ./default-apps.nix {inherit lib;}).apps
    #--- localAi.edit: none, or a model lib/local-models.nix lists
    // {"localAi.edit" = [null] ++ lib.attrNames (import ./local-models.nix).edit;}
    #--- Claude Code; null leaves the setting to Claude Code
    // {
      "claude.model" = [null "opus" "sonnet" "haiku" "fable"];
      "claude.effort" = [null "low" "medium" "high" "xhigh" "max"];
      "claude.outputStyle" = [null "default" "Explanatory" "Learning" "Concise"];
      "claude.builtins.agentsMdFiles" = ["claude-md" "claude-md-or-agents-md" "claude-md-and-agents-md"];
    }
    #--- claude.skills, .agents and their models: each name the template lists
    // claudeChoices "skills" ["on" "name-only" "user-invocable-only" "off"]
    // claudeChoices "agents" ["on" "off"]
    // claudeChoices "skillModels" claudeModels
    // claudeChoices "agentModels" claudeModels;
  claudeModels = [null "inherit" "haiku" "sonnet" "opus" "fable"];
  claudeChoices = kind: values:
    lib.mapAttrs' (name: _: lib.nameValuePair "claude.${kind}.${name}" values) userDefaults.claude.${kind};

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

  #--- One line per entry of a textSets setting that isn't a name and text
  textSetProblems = name: value:
    if !(lib.isAttrs value)
    then ["`${name}` should be a set of text, e.g. {EDITOR = \"zeditor\";}"]
    else
      lib.concatLists (lib.mapAttrsToList (key: item: let
        at = "`${name}.${key}`";
        shape =
          builtins.match (
            if name == "env"
            then "[A-Za-z_][A-Za-z0-9_]*"
            else "[A-Za-z0-9.+-]+/[A-Za-z0-9.+-]+"
          )
          key;
      in
        lib.optional (shape == null)
        (
          if name == "env"
          then "${at} isn't a variable name (letters, digits and _ only)"
          else "${at} isn't a MIME type, e.g. application/x-cbz"
        )
        ++ lib.optional (!(lib.isString item)) "${at} should be text in quotes")
      value);

  #--- One line for each setting in `set` that `defaults` lacks or types differently
  problems = defaults: set: path:
    lib.concatLists (lib.mapAttrsToList (key: value: let
      at = path ++ [key];
      name = "`${lib.concatStringsSep "." at}`";
      dotted = lib.concatStringsSep "." at;
    in
      if !(defaults ? ${key})
      then ["${name} is not a setting (check the spelling against the _template file)"]
      else if defaults.${key} == null
      then []
      else if at == ["keybinds"]
      then keybindProblems value
      else if at == ["windowRules"]
      then windowRuleProblems value
      else if at == ["sideRail"]
      then sideRailProblems value
      else if at == ["steamGames"]
      then steamGameProblems value
      else if lib.elem dotted textSets
      then textSetProblems dotted value
      else if lib.elem dotted grouped
      then
        lib.optional (!(lib.isAttrs value && lib.all (l: lib.isList l && lib.all lib.isString l) (lib.attrValues value)))
        "${name} should be a set of lists of names in quotes, e.g. {Media = [\"vlc\"];}"
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
    portLists
    ++ lib.concatMap (path: let
      domain = v: lib.isString v && builtins.match "[a-zA-Z0-9_-]+([.][a-zA-Z0-9_-]+)+" v != null;
      wrong = lib.filter (v: !(domain v)) (listAt path set);
    in
      lib.optional (wrong != []) "`${path}` has ${builtins.toJSON wrong}; use domain names like \"example.com\"")
    domainLists
    ++ lib.concatLists (lib.mapAttrsToList (path: range: let
      value = lib.attrByPath (lib.splitString "." path) null set;
      low = builtins.elemAt range 0;
      high = builtins.elemAt range 1;
    in
      lib.optional (lib.isInt value && (value < low || value > high))
      "`${path}` is ${toString value}; use a number from ${toString low} to ${toString high}")
    numberRanges);

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
in rec {
  #--- The allowed values, for tools that edit the settings files
  inherit choices userChoices listChoices;

  #--------------------------------------------------------------------#
  #-- Machine
  #--------------------------------------------------------------------#
  #- `machine`: the machine's settings plus its folder name, with each user's
  #- final settings in machine.users. `anyUser`: each true/false user setting,
  #- true when at least one user on the machine has it on.
  forMachine = name:
    forSettings {
      inherit name;
      own = import ../machines/${name}/settings.nix;
      readUser = user: let
        path = ../users/${user}/settings.nix;
      in
        if builtins.pathExists path
        then import path
        else null;
    };

  #--- Same, from settings given as values (`readUser` returns null for none);
  #--- the flake's stranger check uses it
  forSettings = {
    name,
    own,
    readUser,
  }: let
    file = "machines/${name}/settings.nix";
    listed = own.users or {};
    names = lib.attrNames listed;
    userFile = user: "users/${user}/settings.nix";
    missing = lib.filter (user: readUser user == null) names;

    #--- Defaults, then the user's own file, then this machine's changes
    resolveUser = user: let
      own = readUser user;
      merged = lib.recursiveUpdate (lib.recursiveUpdate userDefaults own) listed.${user};
    in
      merged
      // lib.genAttrs (grouped ++ textSets ++ ["keybinds" "windowRules" "sideRail" "steamGames"]) (key: listed.${user}.${key} or own.${key} or userDefaults.${key})
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
    assert lib.all (user: report (userFile user) (problems userDefaults (readUser user) [])) names;
    assert lib.all (user: let
      final = machine.users.${user};
    in
      report (userFile user) (badChoices userChoices final
        ++ badLists final
        ++ lib.optional (builtins.match "[0-9A-Fa-f]{6}" final.mangohud.textColor == null)
        "`mangohud.textColor` is ${builtins.toJSON final.mangohud.textColor}; use six hex digits, e.g. \"00FF00\""))
    names;
    assert report file (lib.optional (!machine.users.${mainUser}.admin)
      "the main user `${mainUser}` needs admin = true (in ${userFile mainUser}), or nobody here can rebuild the system"); {
      inherit machine;
      anyUser = anyOf (lib.attrValues machine.users);
    };
}
