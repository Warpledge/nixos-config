#=====================================================================#
# NIRI MONITOR CONFIGURATION
#=====================================================================#
{hostname, ...}: let
  #--- Desktop monitors
  desktopMonitors = {
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
    };
  };

  #--- Laptop monitors - Legion Slim 5 internal panel (2560x1600@165Hz)
  laptopMonitors = {
    #--- Primary display
    "eDP-1" = {
      mode = {
        width = 2560;
        height = 1600;
        refresh = 165.0;
      };
      position = {
        x = 0;
        y = 0;
      };
      scale = 1.1;
    };

    #--- Alternative primary display (appears as eDP-2 on some boots)
    "eDP-2" = {
      mode = {
        width = 2560;
        height = 1600;
        refresh = 165.0;
      };
      position = {
        x = 0;
        y = 0;
      };
      scale = 1.1;
    };
  };

  #--- Select monitors based on hostname
  monitors =
    if hostname == "desktop"
    then desktopMonitors
    else if hostname == "laptop"
    then laptopMonitors
    else {};
in {
  programs.niri.settings = {
    outputs = monitors;
  };
}
