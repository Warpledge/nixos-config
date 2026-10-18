#=====================================================================#
# DESKTOP SYSTEM CONFIGURATION
#=====================================================================#
{
  lib,
  machine,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Desktop Settings (Top Level)
  #--------------------------------------------------------------------#
  #--- The hostname comes from settings.nix (hostName, else the folder name)

  hardware = {
    #--- Bluetooth
    bluetooth.enable = true;
    bluetooth.powerOnBoot = true;

    #--- DDC/CI monitor brightness, for DMS's brightness slider and keys
    i2c.enable = true;
  };
  #--- Every user: access to /dev/i2c-* (above)
  users.users = lib.mapAttrs (_: _: {extraGroups = ["i2c"];}) machine.users;

  #--- CPU Frequency Scaling Optimization for Ryzen 7 5800X3D
  #--- The 5800X3D benefits from staying in performance mode during gaming
  powerManagement = {
    cpuFreqGovernor = "performance";
  };

  #--- Disable suspend (GPU/compositor fails to resume properly on RX 9070 XT)
  systemd.sleep.settings.Sleep.AllowSuspend = lib.mkForce false;
  services.logind.settings.Login = {
    HandleSuspendKey = "ignore";
    HandlePowerKey = "poweroff";
    IdleAction = "ignore";
  };

  #--------------------------------------------------------------------#
  #-- Imports
  #--------------------------------------------------------------------#
  imports =
    [
      ./hardware/gpu.nix
      ./hardware/hardware-configuration.nix
      ./hardware/storage.nix

      ../../modules
    ]
    ++ (lib.optional (machine.windowManager == "hyprland") ./wm/hyprland.nix)
    ++ (lib.optional (machine.windowManager == "niri") ./wm/niri.nix);
}
