#=====================================================================#
# NIRI SETTINGS (DESKTOP-SPECIFIC)
#=====================================================================#
{
  lib,
  username,
  ...
}: let
  numbers = lib.range 1 9;
in {
  # Monitor configuration is now handled in:
  # modules/wm/niri/home/core/monitors.nix

  #--------------------------------------------------------------------#
  #-- Workspaces & App Placement
  #--------------------------------------------------------------------#
  home-manager.users.${username}.programs.niri.settings = {
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
        "Mod+${name}" = lib.mkForce {action.focus-workspace = name;};
        "Mod+Shift+${name}" = lib.mkForce {action.move-column-to-workspace = name;};
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
}
