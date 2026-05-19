#=====================================================================#
# LAPTOP SYSTEM CONFIGURATION
#=====================================================================#
{
  lib,
  pkgs,
  username,
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
      ./swapfile.nix

      ../../shared/core.nix
    ]
    ++ (lib.optional (hostConfig.windowManager == "hyprland") ./wm/hyprland.nix)
    ++ (lib.optional (hostConfig.windowManager == "niri") ./wm/niri.nix);

  #--- Laptop-specific home-manager modules
  home-manager.users.${username}.imports = [
    ./minecraft-servers
  ];

  #--------------------------------------------------------------------#
  #-- Laptop Settings (Top Level)
  #--------------------------------------------------------------------#
  networking.hostName = "laptop";

  #--- Logitech Mouse
  hardware.logitech.wireless.enable = true;
  environment.systemPackages = with pkgs; [
    solaar
    upower
    dmidecode # Install dmidecode to identify the laptop model
  ];

  #--- Power Management
  boot.kernelModules = ["battery" "ac"];
  boot.kernelParams = ["consoleblank=600"]; # Blank TTY screen after 10 minutes idle

  #--- Prevent sleep/suspend when running server
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  services = {
    #--- TLP Power Management (Legion Slim 5 optimized for server)
    tlp = {
      enable = true;
      settings = {
        # CPU scaling driver - uses AMD's native power scaling
        CPU_SCALING_GOVERNOR_ON_AC = "amd-pstate";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

        # Turbo boost - enabled on AC for server performance, disabled on battery
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;

        # GPU power saving (AMD 680M + RTX 4070 hybrid)
        RADEON_DPM_PERF_LEVEL_ON_AC = "performance";
        RADEON_DPM_PERF_LEVEL_ON_BAT = "low";

        # Thermal thresholds - max performance on AC for server stability
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MAX_PERF_ON_BAT = 75;

        # Disable turbo throttling for consistent server performance
        SCHED_POWERSAVE = 0;
      };
    };

    #--- Disable power-profiles-daemon (conflicts with TLP on laptop)
    power-profiles-daemon.enable = lib.mkForce false;

    logind = {
      settings = {
        Login = {
          HandlePowerKey = "ignore"; # Ignore power button (prevent accidental suspend)
          LidSwitch = "ignore";
          LidSwitchExternalPower = "ignore";
          IdleAction = "ignore"; # Prevent idle suspend while server is running
          IdleActionSec = "0";
        };
      };
    };
    upower = {
      enable = true;
    };

    #--- Prevent display from going to sleep on AC power
    acpid = {
      enable = true;
    };
  };

  #--- Screen timeout on AC power (server-optimized)
  environment.etc."X11/xorg.conf.d/80-nohide.conf".text = ''
    Section "ServerFlags"
      Option "BlankTime" "0"
      Option "StandbyTime" "0"
      Option "SuspendTime" "0"
      Option "OffTime" "0"
    EndSection
  '';
}
