#=====================================================================#
# NIXOS MODULE IMPORTS
#=====================================================================#
{
  lib,
  hostConfig,
  ...
}: {
  imports =
    [
      #--- Network
      ./network/blockers.nix
      ./network/core.nix

      #--- Nix Daemon & Tooling
      ./nix/core.nix
      ./nix/nh.nix
      ./nix/nixpkgs.nix
      ./nix/substituters.nix

      #--- Program Installation & Configuration
      ./programs/docker.nix
      ./programs/gaming/core.nix
      ./programs/flatpak.nix
      ./programs/utility.nix

      #--- Security & Hardening
      ./security/auditd.nix
      ./security/core.nix
      ./security/kernel.nix
      ./security/sudo.nix

      #--- System Services
      ./services/adb.nix
      ./services/gnome-services.nix
      ./services/keyd.nix
      ./services/power.nix
      ./services/runners.nix
      ./services/sound.nix

      #--- System Configuration
      ./system/bootloader.nix
      ./system/locale.nix
      ./system/shell.nix
      ./system/tweaks.nix
      ./system/user.nix
      ./system/wayland.nix
      ./system/xserver.nix
      ./system/zram.nix
    ]
    #--- VPN (controlled by hostConfig)
    ++ lib.optionals hostConfig.mullvad.enable [./network/mullvad.nix]
    #--- Waydroid Android Container (controlled by hostConfig)
    ++ lib.optionals hostConfig.waydroid.enable [./programs/waydroid.nix]
    #--- ClamAV Antivirus (controlled by hostConfig)
    ++ lib.optionals hostConfig.clamav.enable [./services/clamav.nix]
    #--- Sunshine Game Streaming (controlled by hostConfig)
    ++ lib.optionals hostConfig.sunshine.enable [./services/sunshine.nix]
    #--- Japanese Input Method (controlled by hostConfig)
    ++ lib.optionals hostConfig.japanese.ime [./system/japanese-ime.nix]
    #--- Cohesion Notes (Flatpak, controlled by hostConfig)
    ++ lib.optionals hostConfig.cohesion.enable [./programs/cohesion.nix];
}
