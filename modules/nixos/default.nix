#=====================================================================#
# NIXOS MODULE IMPORTS
#=====================================================================#
{
  lib,
  machine,
  anyUser,
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
      ./security/auditd.nix
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
      ./system/user/config-repo.nix
    ]
    #--- Graphics drivers (controlled by machine settings; null: the machine's own files)
    ++ lib.optionals (machine.gpu.type != null) [./services/hardware/gpu.nix]
    #--- Mullvad VPN, system and home-manager halves (controlled by machine settings)
    ++ lib.optionals machine.mullvad.enable [./security/mullvad]
    #--- ClamAV Antivirus (controlled by machine settings)
    ++ lib.optionals machine.clamav.enable [./security/clamav.nix]
    #--- Docker (controlled by machine settings)
    ++ lib.optionals machine.docker.enable [./services/runtimes/docker.nix]
    #--- Flatpak (any user with a Flatpak app: hytale)
    ++ lib.optionals anyUser.gaming.hytale [./services/runtimes/flatpak.nix]
    #--- SSH Server (controlled by machine settings)
    ++ lib.optionals machine.ssh.enable [./services/ssh.nix]
    #--- Suwayomi Manga Server (controlled by machine settings)
    ++ lib.optionals machine.suwayomi.enable [./services/servers/suwayomi.nix]
    #--- Syncthing File Sync (controlled by machine settings)
    ++ lib.optionals machine.syncthing.enable [./services/servers/syncthing.nix]
    #--- Sunshine Game Streaming (controlled by machine settings)
    ++ lib.optionals machine.sunshine.enable [./services/servers/sunshine.nix]
    #--- FlareSolverr for Moku's Cloudflare-protected sources (any user with Moku)
    ++ lib.optionals anyUser.media.moku [./services/servers/flaresolverr.nix]
    #--- Japanese Input Method (any user with japanese.ime)
    ++ lib.optionals anyUser.japanese.ime [./system/language/japanese-ime.nix];
}
