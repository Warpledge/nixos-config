#=====================================================================#
# NIRI KEYBIND OPTION
#=====================================================================#
# Modules add binds to niri.keybinds by id; this applies the user's keybinds
# setting (Omni Settings' Keybinds page) and turns them into niri's binds
{
  config,
  lib,
  user,
  ...
}: let
  inherit (lib) mkOption types;

  #--- Actions whose number argument niri reads as an index, not a name
  indexActions = [
    "focus-workspace"
    "move-column-to-workspace"
    "move-window-to-workspace"
    "focus-column"
    "focus-window-in-column"
    "move-column-to-index"
    "move-workspace-to-index"
  ];
  argOf = name: o:
    if (o.argument or "") == ""
    then {}
    else if lib.elem name indexActions && builtins.match "[0-9]+" o.argument != null
    then lib.toInt o.argument
    else o.argument;
  actionOf = o:
    if o ? spawn
    then {inherit (o) spawn;}
    else {${o.action} = argOf o.action o;};

  #--- The config's binds with the user's changes, then the user's own binds
  defaults = lib.mapAttrs (_: b: removeAttrs b ["_module"]) config.niri.keybinds;
  changed = lib.mapAttrs (id: b:
    b // lib.filterAttrs (k: _: lib.elem k ["key" "title" "enable"]) (user.keybinds.${id} or {}))
  defaults;
  #--- A winsKey bind turns off the other config binds on its key, except ones
  #--- whose key or on/off the user's keybinds setting chose
  wonKeys = map (b: lib.toLower b.key) (lib.filter (b: b.winsKey && b.enable) (lib.attrValues changed));
  won = lib.mapAttrs (id: b:
    if
      !b.winsKey
      && lib.elem (lib.toLower b.key) wonKeys
      && !(user.keybinds ? ${id}.key || user.keybinds ? ${id}.enable)
    then b // {enable = false;}
    else b)
  changed;
  custom = lib.mapAttrs (id: o: {
    inherit id;
    inherit (o) key title;
    action = actionOf o;
    group = "Yours";
    hidden = false;
    allowWhenLocked = false;
    allowInhibiting = true;
    enable = o.enable or true;
  }) (lib.filterAttrs (id: _: lib.hasPrefix "custom-" id) user.keybinds);
  final = won // custom;
  enabled = lib.filter (b: b.enable) (lib.attrValues final);
in {
  #--------------------------------------------------------------------#
  #-- Option
  #--------------------------------------------------------------------#
  options.niri.keybinds = mkOption {
    default = {};
    description = "niri binds by id, so an override survives a key change.";
    type = types.attrsOf (types.submodule ({name, ...}: {
      options = {
        id = mkOption {
          type = types.str;
          default = name;
          readOnly = true;
        };
        key = mkOption {type = types.str;};
        # The Mod+/ cheatsheet title (DMS), also the bind's label in Omni Settings
        title = mkOption {type = types.str;};
        action = mkOption {type = types.attrs;};
        group = mkOption {
          type = types.str;
          default = "Other";
        };
        # Left off the cheatsheet
        hidden = mkOption {
          type = types.bool;
          default = false;
        };
        allowWhenLocked = mkOption {
          type = types.bool;
          default = false;
        };
        allowInhibiting = mkOption {
          type = types.bool;
          default = true;
        };
        enable = mkOption {
          type = types.bool;
          default = true;
        };
        # Turns off the config's other binds on this key instead of failing the build
        winsKey = mkOption {
          type = types.bool;
          default = false;
        };
      };
    }));
  };

  #--------------------------------------------------------------------#
  #-- Niri Binds
  #--------------------------------------------------------------------#
  config = {
    programs.niri.settings.binds = lib.listToAttrs (map (b:
      lib.nameValuePair b.key ({
          inherit (b) action;
          hotkey-overlay =
            if b.hidden
            then {hidden = true;}
            else {inherit (b) title;};
        }
        // lib.optionalAttrs b.allowWhenLocked {allow-when-locked = true;}
        // lib.optionalAttrs (!b.allowInhibiting) {allow-inhibiting = false;}))
    enabled);

    #--- For Omni Settings' Keybinds page: each bind as built, with the config's
    #--- own key, title and on/off, niri's action names and the changes applied
    xdg.configFile."omni-settings/niri-keybinds.json".text = builtins.toJSON {
      overrides = user.keybinds;
      binds = lib.mapAttrsToList (id: b:
        b
        // {
          default = {inherit (defaults.${id} or b) key title enable;};
          custom = custom ? ${id};
        })
      final;
      # niri-flake's list misses some that take an argument; the binds' own fill in
      actions = lib.sort lib.lessThan (lib.unique (lib.filter (a: a != "recent-windows")
        (lib.attrNames config.lib.niri.actions
          ++ indexActions
          ++ lib.concatMap (b: lib.attrNames b.action) (lib.attrValues defaults))));
    };

    #------------------------------------------------------------------#
    #-- Assertions
    #------------------------------------------------------------------#
    assertions = let
      # niri reads modifier and key names case-insensitively
      byKey = lib.groupBy (b: lib.toLower b.key) enabled;
      clashes = lib.filterAttrs (_: bs: lib.length bs > 1) byKey;
      # A string spawn runs its first word only; arguments go in a list
      badSpawn = map (b: b.id) (lib.filter (b:
        lib.isString (b.action.spawn or null) && lib.hasInfix " " b.action.spawn)
      enabled);
    in [
      {
        assertion = clashes == {};
        message = "niri keybinds share a key: ${lib.concatStringsSep "; " (lib.mapAttrsToList
          (_: bs: "${(lib.head bs).key} (${lib.concatMapStringsSep ", " (b: b.id) bs})")
          clashes)}.";
      }
      {
        assertion = badSpawn == [];
        message = "niri keybind(s) ${lib.concatStringsSep ", " badSpawn} pass a spawn command with arguments as a string; use a list, e.g. [\"playerctl\" \"play-pause\"].";
      }
    ];
  };
}
