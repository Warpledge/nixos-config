#=====================================================================#
# INPUT DEVICES (LIBINPUT, XKB, GAME CONTROLLERS)
#=====================================================================#
{
  pkgs,
  machine,
  ...
}: {
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
  #-- Game Controllers
  #--------------------------------------------------------------------#
  #--- User access to DualSense, Switch, 8BitDo and other pads outside Steam
  services.udev.packages = [pkgs.game-devices-udev-rules];

  #--------------------------------------------------------------------#
  #-- X Server
  #--------------------------------------------------------------------#
  services.xserver = {
    enable = false;
    xkb.layout = machine.keyboardLayout;
    excludePackages = with pkgs; [
      xterm
    ];
  };
}
