#=====================================================================#
# NIRI KEYBIND OPTION
#=====================================================================#
# Modules add binds to niri.keybinds by id; this turns them into niri's binds
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption types;
  enabled = lib.filter (b: b.enable) (lib.attrValues config.niri.keybinds);
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
