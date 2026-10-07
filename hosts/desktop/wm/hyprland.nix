#=====================================================================#
# HYPRLAND SETTINGS (DESKTOP-SPECIFIC)
#=====================================================================#
{username, ...}: {
  #--------------------------------------------------------------------#
  #-- Display & Input Configuration
  #--------------------------------------------------------------------#
  home-manager.users.${username} = {
    wayland.windowManager.hyprland.settings = {
      #--- Monitors (Dell AW2725D OLED + LG ULTRAGEAR)
      # Mode strings must stay in sync with scripts/toggle_hdr.sh
      monitor = [
        # Dell AW2725D OLED - Primary (DP-2)
        {
          output = "DP-2";
          mode = "2560x1440@280";
          position = "0x0";
          scale = 1.0;
          bitdepth = 10;
        }
        # LG ULTRAGEAR - Secondary (DP-3)
        {
          output = "DP-3";
          mode = "2560x1440@144";
          position = "2560x0";
          scale = 1.0;
          bitdepth = 10;
        }
        # Fallback
        {
          output = "";
          mode = "preferred";
          position = "auto";
          scale = "auto";
        }
      ];

      #--- Workspaces (1-6 on DP-2, 7-9 on DP-3)
      workspace_rule = map (n: {
        workspace = toString n;
        monitor =
          if n <= 6
          then "DP-2"
          else "DP-3";
        default = n == 1 || n == 7;
      }) (builtins.genList (i: i + 1) 9);

      config = {
        #--- XWayland
        xwayland.force_zero_scaling = true;

        #--- Input Devices
        cursor.no_hardware_cursors = false;
      };
    };
  };
}
