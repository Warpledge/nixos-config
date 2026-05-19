#=====================================================================#
# HYPRLAND SETTINGS (DESKTOP-SPECIFIC)
#=====================================================================#
{
  username,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Display & Input Configuration
  #--------------------------------------------------------------------#
  home-manager.users.${username} = {
    wayland.windowManager.hyprland.settings = {
      #--- Monitors (Dell AW2725D OLED + LG ULTRAGEAR)
      monitor = [
        "DP-2, 2560x1440@280, 0x0, 1.0, bitdepth, 10" # Dell AW2725D OLED - Primary (DP-2)
        "DP-3, 2560x1440@144, 2560x0, 1.0, bitdepth, 10" # LG ULTRAGEAR - Secondary (DP-3)
        ", preferred, auto, auto" # Fallback
      ];

      #--- Workspaces
      workspace = [
        "1, monitor:DP-2, default:true"
        "2, monitor:DP-2"
        "3, monitor:DP-2"
        "4, monitor:DP-2"
        "5, monitor:DP-2"
        "6, monitor:DP-2"
        "7, monitor:DP-3, default:true"
        "8, monitor:DP-3"
        "9, monitor:DP-3"
      ];

      #--- XWayland
      xwayland.force_zero_scaling = true;

      #--- Input Devices
      cursor.no_hardware_cursors = false;
    };
  };
}
