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
      #--- Gaming
      ./gaming

      #--- Network
      ./network/blockers.nix
      ./network/core.nix

      #--- Nix Daemon & Tooling
      ./nix/core.nix
      ./nix/nh.nix
      ./nix/nixpkgs.nix
      ./nix/substituters.nix

      #--- Security & Hardening
      ./security/apparmor
      ./security/auditd.nix
      ./security/core.nix
      ./security/kernel.nix
      ./security/keyring.nix
      ./security/sudo.nix

      #--- System Services
      ./services/adb.nix
      ./services/desktop.nix
      ./services/keyd.nix
      ./services/power.nix
      ./services/runners.nix
      ./services/sound.nix

      #--- System Configuration
      ./system/bootloader.nix
      ./system/display-manager.nix
      ./system/documentation.nix
      ./system/input.nix
      ./system/locale.nix
      ./system/packages.nix
      ./system/shell.nix
      ./system/tweaks.nix
      ./system/user.nix
      ./system/wayland.nix
      ./system/zram.nix
    ]
    #--- ClamAV Antivirus (controlled by hostConfig)
    ++ lib.optionals hostConfig.clamav.enable [./services/clamav.nix]
    #--- Docker (controlled by hostConfig)
    ++ lib.optionals hostConfig.docker.enable [./services/docker.nix]
    #--- Flatpak (controlled by hostConfig; loaded for the Flatpak apps: twintail, moku)
    ++ lib.optionals (hostConfig.gameLaunchers.twintail || hostConfig.media.moku) [./services/flatpak.nix]
    #--- SSH Server (controlled by hostConfig)
    ++ lib.optionals hostConfig.ssh.enable [./services/ssh.nix]
    #--- Suwayomi Manga Server (controlled by hostConfig)
    ++ lib.optionals hostConfig.suwayomi.enable [./services/suwayomi.nix]
    #--- FlareSolverr for Moku's Cloudflare-protected sources (controlled by hostConfig)
    ++ lib.optionals hostConfig.media.moku [./services/flaresolverr.nix]
    #--- Moku Flatpak (controlled by hostConfig)
    ++ lib.optionals hostConfig.media.moku [./services/moku.nix]
    #--- Japanese Input Method (controlled by hostConfig)
    ++ lib.optionals hostConfig.japanese.ime [./system/japanese-ime.nix];
}
