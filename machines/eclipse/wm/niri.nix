#=====================================================================#
# NIRI SETTINGS (DESKTOP-SPECIFIC)
#=====================================================================#
#- For every user on this machine
{
  lib,
  machine,
  ...
}: let
  numbers = lib.range 1 9;
  mainBar = builtins.head (lib.importJSON ../../../modules/wm/niri/home/dms/settings.json).barConfigs;
in {
  home-manager.users =
    lib.mapAttrs (_: _: {
      programs.niri.settings = {
        #--------------------------------------------------------------------#
        #-- Monitors
        #--------------------------------------------------------------------#
        outputs = {
          #--- Main monitor - Dell AW2725D OLED (2560x1440@279.961Hz)
          "DP-2" = {
            mode = {
              width = 2560;
              height = 1440;
              refresh = 279.961;
            };
            position = {
              x = 0;
              y = 0;
            };
            scale = 1.0;
            # VRR only for windows matched in rules.nix
            variable-refresh-rate = "on-demand";
          };

          #--- Secondary monitor - LG ULTRAGEAR (2560x1440@143.973Hz)
          "DP-3" = {
            mode = {
              width = 2560;
              height = 1440;
              refresh = 143.973;
            };
            position = {
              x = 2560;
              y = 0;
            };
            scale = 1.0;
            variable-refresh-rate = "on-demand";
          };
        };

        #--------------------------------------------------------------------#
        #-- Workspaces & App Placement
        #--------------------------------------------------------------------#
        #--- 1-6 on DP-2, 7-9 on DP-3, as in hyprland.nix
        workspaces = lib.genAttrs (map toString numbers) (name: {
          open-on-output =
            if lib.toInt name <= 6
            then "DP-2"
            else "DP-3";
        });

        #--- Number keys go to the named workspaces, not per-monitor indexes
        binds = lib.mkMerge (map (n: let
            name = toString n;
          in {
            # Forcing the action alone keeps the cheatsheet title from binds.nix
            "Mod+${name}".action = lib.mkForce {focus-workspace = name;};
            "Mod+Shift+${name}".action = lib.mkForce {move-column-to-workspace = name;};
          })
          numbers);

        #--- Same placement as Hyprland's windowrules/workspaces.nix
        window-rules = [
          {
            matches = [{app-id = "^steam$";}];
            open-on-workspace = "6";
          }
          {
            matches = [{app-id = "(?i)^spotify$";}];
            open-on-workspace = "8";
          }
          {
            matches = [{app-id = "(?i)goofcord$";}];
            open-on-workspace = "9";
          }
        ];
      };

      #--------------------------------------------------------------------#
      #-- DMS Bars
      #--------------------------------------------------------------------#
      #--- The OLED (DP-2) gets an auto-hiding copy of the main bar
      dms.extraSettings.barConfigs = [
        (mainBar
          // {
            screenPreferences = ["DP-3"];
            showOnLastDisplay = false;
          })
        (mainBar
          // {
            id = "oled";
            name = "OLED Bar";
            autoHide = true;
            screenPreferences = ["DP-2"];
            showOnLastDisplay = false;
          })
      ];
    })
    machine.users;
}
