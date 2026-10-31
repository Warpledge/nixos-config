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
      ./system/user/omni-settings-helper.nix
    ]
    #--- Gaming: GameMode, gamescope, Java, scx_lavd (any user with a gaming.* app)
    ++ lib.optionals (lib.any lib.id (lib.attrValues anyUser.gaming)) [./gaming]
    #--- Graphics drivers (controlled by machine settings; null: the machine's own files)
    ++ lib.optionals (machine.gpu.type != null) [./services/hardware/gpu.nix]
    ++ lib.optionals (machine.localModels.gpuSharedGB != null) [./services/hardware/gpu-shared-memory.nix]
    #--- Caps Lock remap, Bluetooth and printing (controlled by machine settings)
    ++ lib.optionals machine.capsLockRemap [./services/hardware/keyd.nix]
    ++ lib.optionals machine.bluetooth.enable [./services/hardware/bluetooth.nix]
    ++ lib.optionals machine.printing.enable [./services/hardware/printing.nix]
    ++ lib.optionals (machine.battery.chargeLimit != null) [./services/hardware/battery.nix]
    #--- Mullvad VPN, system and home-manager halves (controlled by machine settings)
    ++ lib.optionals machine.mullvad.enable [./security/mullvad]
    #--- ClamAV Antivirus (controlled by machine settings)
    ++ lib.optionals machine.clamav.enable [./security/clamav.nix]
    #--- Docker (controlled by machine settings)
    ++ lib.optionals machine.docker.enable [./services/runtimes/docker.nix]
    #--- Flatpak, with Flatseal (controlled by machine settings)
    ++ lib.optionals machine.flatpak.enable [./services/runtimes/flatpak.nix]
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
    ++ lib.optionals anyUser.openWebui.enable [./services/servers/open-webui.nix]
    #--- adb and the Android debloater (any user with androidDev)
    ++ lib.optionals anyUser.androidDev.enable [./services/hardware/adb.nix]
    #--- Japanese Input Method (any user with japanese.ime)
    ++ lib.optionals anyUser.japanese.ime [./system/language/japanese-ime.nix];
}
