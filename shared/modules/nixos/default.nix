#=====================================================================#
# NIXOS MODULE IMPORTS
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
      #--- Gaming
      ./gaming

      #--- Network
      ./network

      #--- Nix Daemon & Tooling
      ./nix

      #--- Security & Hardening
      ./security/apparmor
      ./security/audit/auditd.nix
      ./security/auth/keyring.nix
      ./security/auth/sudo.nix
      ./security/hardening

      #--- System Services
      ./services/desktop.nix
      ./services/hardware/adb.nix
      ./services/hardware/keyd.nix
      ./services/hardware/power.nix
      ./services/hardware/sound.nix
      ./services/runtimes/runners.nix

      #--- System Configuration
      ./system/bootloader.nix
      ./system/documentation.nix
      ./system/packages.nix
      ./system/desktop/input.nix
      ./system/desktop/wayland.nix
      ./system/language/locale.nix
      ./system/tuning/tweaks.nix
      ./system/tuning/zram.nix
      ./system/user/shell.nix
      ./system/user/user.nix
    ]
    #--- Mullvad VPN, system and home-manager halves (controlled by hostConfig)
    ++ lib.optionals hostConfig.mullvad.enable [./security/vpn/mullvad]
    #--- ClamAV Antivirus (controlled by hostConfig)
    ++ lib.optionals hostConfig.clamav.enable [./security/av/clamav.nix]
    #--- Docker (controlled by hostConfig)
    ++ lib.optionals hostConfig.docker.enable [./services/runtimes/docker.nix]
    #--- Flatpak (controlled by hostConfig; loaded for the Flatpak apps: hytale)
    ++ lib.optionals hostConfig.gaming.hytale [./services/runtimes/flatpak.nix]
    #--- SSH Server (controlled by hostConfig)
    ++ lib.optionals hostConfig.ssh.enable [./services/ssh.nix]
    #--- Suwayomi Manga Server (controlled by hostConfig)
    ++ lib.optionals hostConfig.suwayomi.enable [./services/servers/suwayomi.nix]
    #--- Syncthing File Sync (controlled by hostConfig)
    ++ lib.optionals hostConfig.syncthing.enable [./services/servers/syncthing.nix]
    #--- FlareSolverr for Moku's Cloudflare-protected sources (controlled by hostConfig)
    ++ lib.optionals hostConfig.media.moku [./services/servers/flaresolverr.nix]
    #--- Japanese Input Method (controlled by hostConfig)
    ++ lib.optionals hostConfig.japanese.ime [./system/language/japanese-ime.nix];
}
