#=====================================================================#
# DESKTOP SYSTEM CONFIGURATION
#=====================================================================#
{
  lib,
  hostConfig,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Imports
  #--------------------------------------------------------------------#
  imports =
    [
      ./gpu.nix
      ./hardware-configuration.nix

      ../../shared/core.nix
    ]
    ++ (lib.optional (hostConfig.windowManager == "hyprland") ./wm/hyprland.nix)
    ++ (lib.optional (hostConfig.windowManager == "niri") ./wm/niri.nix);

  #--------------------------------------------------------------------#
  #-- Desktop Settings (Top Level)
  #--------------------------------------------------------------------#
  networking.hostName = "desktop";

  #--- Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  #--- Optimize for L3 cache
  boot.kernel.sysctl = {
    #--- Optimize scheduling for big cache
    "kernel.sched_migration_cost_ns" = 5000000; # 5ms
    "kernel.sched_min_granularity_ns" = 3000000; # 3ms
  };

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
}
