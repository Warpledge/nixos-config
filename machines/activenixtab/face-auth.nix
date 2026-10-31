#=====================================================================#
# FACE AUTH (HOWDY)
#=====================================================================#
#- Face or password for sudo, polkit and the DMS lock screen. The login
#- screen keeps the password, which is what unlocks the GNOME keyring.
{
  config,
  lib,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Kernel Modules
  #--------------------------------------------------------------------#
  #--- The shared hardening module loads v4l2loopback at boot, which Howdy's
  #--- assertion rejects. OBS's virtual camera now needs a manual modprobe.
  boot.kernelModules.v4l2loopback = lib.mkForce false;

  #--------------------------------------------------------------------#
  #-- Howdy
  #--------------------------------------------------------------------#
  services.howdy = {
    enable = true;
    control = "sufficient";
    #--- The IR camera; /dev/videoN numbers can change
    settings.video.device_path = "/dev/v4l/by-path/pci-0000:c4:00.4-usb-0:1:1.2-video-index0";
    #--- IR frames are mostly dark; the default of 60 rejects whole scans as too dark
    settings.video.dark_threshold = 90;
    #--- Native height: the default of 320 shrinks frames, so faces must be very close
    settings.video.max_height = 480;
    settings.video.timeout = 6;
  };

  services.linux-enable-ir-emitter = {
    enable = true;
    device = "video2";
  };

  #--------------------------------------------------------------------#
  #-- PAM Services
  #--------------------------------------------------------------------#
  #--- On by default for every service; only the ones below opt in
  security.pam.howdy.enable = false;

  security.pam.services = {
    sudo.howdy.enable = true;
    polkit-1.howdy.enable = true;
    #--- DMS's lock screen uses this stack when /etc/pam.d/dankshell exists
    dankshell.howdy.enable = true;
    #--- DMS starts PAM on Enter, so password first: a typed one skips the scan
    #--- and an empty Enter fails through to Howdy
    dankshell.rules.auth.howdy.order =
      config.security.pam.services.dankshell.rules.auth.unix.order + 10;
  };

  #--------------------------------------------------------------------#
  #-- Polkit Sandbox
  #--------------------------------------------------------------------#
  #--- polkit's helper is denied all devices upstream; Howdy needs the camera
  systemd.services."polkit-agent-helper@".serviceConfig = {
    PrivateDevices = false;
    DeviceAllow = ["char-video4linux rw"];
  };
}
