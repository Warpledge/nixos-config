#=====================================================================#
# X SERVER CONFIGURATION (XSERVER, LIBINPUT)
#=====================================================================#
{pkgs, ...}: {
  #--- X Server Setup
  services = {
    xserver = {
      enable = false;
      xkb.layout = "us"; # read by COSMIC even with the server off
      excludePackages = with pkgs; [
        xterm
      ];
    };

    #--- Input Device Handling
    libinput = {
      enable = true;
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
  # Switching windowManager (gdm <-> greetd) leaves the old display manager's
  # unit masked, and switch-to-configuration only unmasks units it considers
  # active, so the new one cannot start. Unmask both before each activation.
  system.activationScripts.unmaskDisplayManagers = ''
    ${pkgs.systemd}/bin/systemctl unmask gdm.service greetd.service 2>/dev/null || true
  '';
}
