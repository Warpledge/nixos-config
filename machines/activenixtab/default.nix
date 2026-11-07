#=====================================================================#
# FLOW Z13 SYSTEM CONFIGURATION
#=====================================================================#
#- ASUS ROG Flow Z13 2025 (GZ302EA): Ryzen AI Max+ 395, Radeon 8060S,
#- 128 GB unified memory, MT7925 Wi-Fi, detachable folio keyboard.
{
  lib,
  machine,
  pkgs,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Hardware
  #--------------------------------------------------------------------#
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;

  #--- Accelerometer, for auto-rotation (iio-niri in wm/niri.nix)
  hardware.sensor.iio.enable = true;

  #--- Logging in without the folio closed every touchpad, virtual too (CLAUDE.md)
  environment.etc."libinput/local-overrides.quirks".text = ''
    [ASUS Z13 tablet mode switch]
    MatchName=Asus WMI hotkeys
    ModelTabletModeSwitchUnreliable=1
  '';

  #--- NPU driver
  boot.kernelModules = ["amdxdna"];

  #--- GPU shared memory for local models (120 GiB GTT; keep UMA low in BIOS)
  #--- comes from localModels.gpuSharedGB in settings.nix
  boot.kernelParams = [
    "amd_pstate=active"
    "amdgpu.dcdebugmask=0x410" # PSR, Panel Replay off: testing post-resume lag, freeze
  ];

  #--- MT7925 Wi-Fi drops with PCIe power saving on some kernels
  boot.extraModprobeConfig = "options mt7925e disable_aspm=1";

  #--------------------------------------------------------------------#
  #-- Power & ASUS Controls
  #--------------------------------------------------------------------#
  #--- asusd: profiles, fan curves, keyboard and light bar (asusctl)
  services.asusd.enable = true;
  services.power-profiles-daemon.enable = true;

  #--------------------------------------------------------------------#
  #-- Input
  #--------------------------------------------------------------------#
  #--- Tapping Meta alone opens the launcher (Meta+Space)
  #- !name:On-screen keyboard: kept out of keyd as insurance. (Measured 2026-10-31:
  #- keyd never grabs uinput devices anyway; niri grabs them itself.)
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = ["*" "!name:On-screen keyboard"];
      settings.main.leftmeta = "overload(meta, M-space)";
    };
  };

  #--- Device-specific remaps (the Naga preset)
  services.input-remapper.enable = true;

  #--------------------------------------------------------------------#
  #-- Apps & Services
  #--------------------------------------------------------------------#
  services.tailscale.enable = true;
  virtualisation.waydroid.enable = true;

  #--- Run AppImages directly (double-click or ./app.AppImage)
  #- Lichii links libgcrypt but ships no libgpg-error, which the runner lacks
  programs.appimage = {
    enable = true;
    binfmt = true;
    package = pkgs.appimage-run.override {
      extraPkgs = p: [p.libgpg-error];
    };
  };

  #--------------------------------------------------------------------#
  #-- AppArmor
  #--------------------------------------------------------------------#
  #--- Prism can't write a file while its profile is loaded:
  #- flags=(attach_disconnected) in modules/nixos/security/apparmor/prismlauncher.nix
  #- makes linkat of Qt 6.12's unnamed temp files (QSaveFile) fail with ENOENT, so
  #- meta/index.json, translations and prismlauncher.cfg never save. Off until that
  #- flag is dropped (Warpledge's file; a fix for all users).
  security.apparmor.policies.prismlauncher.state = lib.mkForce "disable";

  #--------------------------------------------------------------------#
  #-- Imports
  #--------------------------------------------------------------------#
  imports =
    [
      ./hardware/hardware-configuration.nix
      ./face-auth.nix

      ../../modules
    ]
    #--- Disk-unlock lines setup.sh copied from the installer's configuration.nix
    ++ lib.optional (builtins.pathExists ./hardware/boot.nix) ./hardware/boot.nix
    ++ (lib.optional (machine.windowManager == "niri") ./wm/niri.nix);

  #--- kylerj's own apps and keybinds (KDE layout), on this machine only
  home-manager.users.kylerj.imports = [./home];
}
