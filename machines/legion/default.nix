#=====================================================================#
# LAPTOP SYSTEM CONFIGURATION
#=====================================================================#
{
  lib,
  pkgs,
  machine,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Laptop Settings (Top Level)
  #--------------------------------------------------------------------#
  #--- The hostname comes from settings.nix (hostName, else the folder name)

  #--- Minecraft servers (minecraft-servers/ is home-manager, so the port opens here)
  networking.firewall.allowedTCPPorts = [25566];

  #--- Logitech Mouse
  hardware.logitech.wireless.enable = true;
  environment.systemPackages = with pkgs; [
    solaar
    upower
    dmidecode # identify the laptop model
  ];

  #--- Power Management
  boot.kernelModules = ["battery" "ac"];
  boot.kernelParams = [
    "consoleblank=600" # Blank TTY screen after 10 minutes idle
    "amd_pstate=active" # EPP mode, which CPU_ENERGY_PERF_POLICY below needs
  ];

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
        # Legion platform profile, shown by the Fn+Q LED (performance=red,
        # balanced=white, low-power=blue); performance lifts the CPU power limit
        PLATFORM_PROFILE_ON_AC = "balanced";
        PLATFORM_PROFILE_ON_BAT = "low-power";

        # amd-pstate EPP: clock up at once for the server tick (TLP default is
        # balance_performance)
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

        # Aggressive PCIe link power states on battery (covers RTX 4070 PCI slot)
        PCIE_ASPM_ON_BAT = "powersupersave";

        # Runtime power management for all PCI devices; "on" (TLP's AC default)
        # keeps the 4070's audio function and PCIe port awake, so it never powers off
        RUNTIME_PM_ON_AC = "auto";
        RUNTIME_PM_ON_BAT = "auto";

        # WiFi power saving on battery
        WIFI_PWR_ON_BAT = "on";

        # Audio codec power saving
        SOUND_POWER_SAVE_ON_BAT = 1;
        SOUND_POWER_SAVE_CONTROLLER = "Y";

        # Lenovo conservation mode: stops charging at 60 or 80% (by model);
        # START is a dummy value on non-ThinkPads
        START_CHARGE_THRESH_BAT0 = 0;
        STOP_CHARGE_THRESH_BAT0 = 1;
      };
    };

    #--- Disable power-profiles-daemon (conflicts with TLP on laptop)
    power-profiles-daemon.enable = lib.mkForce false;

    logind = {
      settings = {
        Login = {
          HandlePowerKey = "ignore"; # Ignore power button (prevent accidental suspend)
          HandleLidSwitch = "ignore";
          HandleLidSwitchExternalPower = "ignore";
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

  #--------------------------------------------------------------------#
  #-- Imports
  #--------------------------------------------------------------------#
  imports =
    [
      ./hardware/gpu.nix
      ./hardware/hardware-configuration.nix
      ./hardware/swapfile.nix

      ../../modules
    ]
    #--- Disk-unlock lines setup.sh copied from the installer's configuration.nix
    ++ lib.optional (builtins.pathExists ./hardware/boot.nix) ./hardware/boot.nix
    ++ (lib.optional (machine.windowManager == "hyprland") ./wm/hyprland.nix)
    ++ (lib.optional (machine.windowManager == "niri") ./wm/niri.nix);

  #--- Laptop-specific home-manager modules (the servers live in the main
  #--- user's ~/Documents)
  home-manager.users.${machine.mainUser}.imports = [
    ./minecraft-servers
  ];
}
