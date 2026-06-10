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

  #--------------------------------------------------------------------#
  #-- Display Manager Mask Cleanup
  #--------------------------------------------------------------------#
  # Switching windowManager (gdm <-> greetd) leaves the previous display
  # manager's unit masked (/etc/systemd/system/<unit> -> /dev/null).
  # switch-to-configuration only unmasks units it considers "active", so a
  # masked-but-inactive unit never gets unmasked on the next switch, leaving
  # the new display manager unable to start. Clear both unconditionally
  # before each activation so the active config's DM re-enables cleanly.
  system.activationScripts.unmaskDisplayManagers = ''
    ${pkgs.systemd}/bin/systemctl unmask gdm.service greetd.service 2>/dev/null || true
  '';
}
