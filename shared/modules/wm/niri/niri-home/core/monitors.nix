#=====================================================================#
# NIRI MONITOR CONFIGURATION
#=====================================================================#
{
  hostname,
  lib,
  ...
}:
let
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

  #--- Laptop monitor (defaults, can be overridden by host-specific config)
  laptopMonitors = {
    "eDP-1" = {
      mode = {
        width = lib.mkDefault 2560;
        height = lib.mkDefault 1600;
        refresh = lib.mkDefault 165.0;
      };
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
