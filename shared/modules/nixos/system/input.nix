#=====================================================================#
# INPUT DEVICES (LIBINPUT, XKB)
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Input Device Handling
  #--------------------------------------------------------------------#
  services.libinput = {
    enable = true;
    mouse = {
      accelProfile = "flat"; # No mouse acceleration (linear motion)
    };
  };

  #--------------------------------------------------------------------#
  #-- X Server
  #--------------------------------------------------------------------#
  services.xserver = {
    enable = false;
    xkb.layout = "us"; # read by COSMIC even with the server off
    excludePackages = with pkgs; [
      xterm
    ];
  };
}
