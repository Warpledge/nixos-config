#=====================================================================#
# BOOTLOADER CONFIGURATION (SYSTEMD-BOOT, KERNEL, INITRD)
#=====================================================================#
{
  config,
  pkgs,
  hostConfig,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Kernel Selection (controlled by hostConfig.kernel)
  #--------------------------------------------------------------------#
  boot.kernelPackages =
    if hostConfig.kernel == "zen" then pkgs.linuxPackages_zen
    else if hostConfig.kernel == "latest" then pkgs.linuxPackages_latest
    else if hostConfig.kernel == "xanmod" then pkgs.linuxPackages_xanmod
    else if hostConfig.kernel == "cachyos" then pkgs.cachyosKernels.linuxPackages-cachyos-latest
    else pkgs.linuxPackages_zen; # Default fallback

  #--------------------------------------------------------------------#
  #-- Boot Configuration
  #--------------------------------------------------------------------#
  boot = {
    tmp.cleanOnBoot = true; # Wipe /tmp on boot
    tmp.useTmpfs = true; # Store /tmp in RAM
    supportedFilesystems = ["ntfs"]; # Support NTFS (windows) filesystems
    consoleLogLevel = 0; # Suppress kernel boot messages
    kernelParams = [
      "quiet" # Suppress kernel messages on boot & shutdown
      "splash" # Show splash screen on boot & shutdown
      "rd.systemd.show_status=false" # Hide systemd status during initrd
      "rd.udev.log_level=3" # Reduce udev initrd logging
      "udev.log_priority=3" # Reduce udev boot logging
    ];
    loader = {
      systemd-boot = {
        enable = true; # Use systemd-boot EFI bootloader
        configurationLimit = 10; # Keep last 10 entries
        consoleMode = "max"; # Use full console resolution
      };
      efi.canTouchEfiVariables = true; # Allow EFI variable modification
    };
    initrd = {
      systemd.enable = true; # Use systemd in initrd
      verbose = false;
    };
    plymouth = {
      enable = true; # Show graphical boot splash screen
    };
  };

  #--------------------------------------------------------------------#
  #-- System Packages
  #--------------------------------------------------------------------#
  environment.systemPackages = [
    pkgs.sbctl # Secure Boot control utility
    config.boot.kernelPackages.cpupower # CPU frequency scaling tool
    pkgs.refind # Advanced boot manager
    pkgs.efibootmgr # EFI boot entry management
  ];

  #--------------------------------------------------------------------#
  #-- Systemd Boot Configuration
  #--------------------------------------------------------------------#
  systemd = {
    network.wait-online.enable = false; # Don't wait for network online at boot
    services = {
      nix-daemon = {
        environment = {
          TMPDIR = "/var/tmp"; # Use persistent tmp for nix daemon
        };
      };
      NetworkManager-wait-online.enable = false; # Skip NM online check at boot
      systemd-networkd.stopIfChanged = false; # Keep networkd running if changed
      systemd-resolved.stopIfChanged = false; # Keep DNS resolver running if changed
    };
  };

  #--------------------------------------------------------------------#
  #-- REFInd Boot Manager
  #--------------------------------------------------------------------#
  #--- REFInd is layered on top of systemd-boot for advanced boot management
  #--- https://wiki.nixos.org/wiki/REFInd
  #--- Installation on system:
  #---
  #---   sudo nix-shell -p refind efibootmgr
  #---   refind-install
}
