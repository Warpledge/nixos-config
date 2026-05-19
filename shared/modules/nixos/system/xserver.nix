#=====================================================================#
# X SERVER CONFIGURATION (XSERVER, LIBINPUT)
#=====================================================================#
{pkgs, ...}: {
  #--- X Server Setup
  services = {
    xserver = {
      enable = true; # Disable X11 server
      xkb.layout = "us"; # US keyboard layout
      excludePackages = with pkgs; [
        xterm
      ];
    };

    #--- Input Device Handling
    libinput = {
      enable = true; # Enable libinput for input device handling
      mouse = {
        accelProfile = "flat"; # No mouse acceleration (linear motion)
      };
    };
  };

  #--- Systemd Shutdown Timeout
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "10s";
  };
}
