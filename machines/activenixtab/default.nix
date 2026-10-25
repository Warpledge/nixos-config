#=====================================================================#
# FLOW Z13 SYSTEM CONFIGURATION
#=====================================================================#
#- ASUS ROG Flow Z13 2025 (GZ302EA): Ryzen AI Max+ 395, Radeon 8060S,
#- 128 GB unified memory, MT7925 Wi-Fi, detachable folio keyboard.
{
  lib,
  machine,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Hardware
  #--------------------------------------------------------------------#
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;

  #--- Accelerometer, for auto-rotation (iio-niri in wm/niri.nix)
  hardware.sensor.iio.enable = true;

  #--- NPU driver
  boot.kernelModules = ["amdxdna"];

  boot.kernelParams = [
    "amd_pstate=active"
    # Let the GPU borrow up to 120 GiB of system RAM (GTT); keep UMA low in BIOS
    "ttm.pages_limit=31457280"
    "ttm.page_pool_size=31457280"
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
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = ["*"];
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
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  #--------------------------------------------------------------------#
  #-- Imports
  #--------------------------------------------------------------------#
  imports =
    [
      ./hardware/hardware-configuration.nix

      ../../modules
    ]
    #--- Disk-unlock lines setup.sh copied from the installer's configuration.nix
    ++ lib.optional (builtins.pathExists ./hardware/boot.nix) ./hardware/boot.nix
    ++ (lib.optional (machine.windowManager == "niri") ./wm/niri.nix);

  #--- kylerj's own apps and keybinds (KDE layout), on this machine only
  home-manager.users.kylerj.imports = [./home];
}
