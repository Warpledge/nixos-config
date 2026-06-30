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
        # Legion platform profile — controls Fn+Q LED (balanced=white, low-power=blue)
        PLATFORM_PROFILE_ON_AC = "balanced";
        PLATFORM_PROFILE_ON_BAT = "low-power";

        # Aggressive PCIe link power states on battery (covers RTX 4070 PCI slot)
        PCIE_ASPM_ON_BAT = "powersupersave";

        # Runtime power management for all PCI devices on battery
        RUNTIME_PM_ON_BAT = "auto";

        # WiFi power saving on battery
        WIFI_PWR_ON_BAT = "on";

        # Audio codec power saving
        SOUND_POWER_SAVE_ON_BAT = 1;
        SOUND_POWER_SAVE_CONTROLLER = "Y";
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
