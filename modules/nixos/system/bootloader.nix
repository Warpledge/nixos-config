#=====================================================================#
# BOOTLOADER CONFIGURATION (SYSTEMD-BOOT, KERNEL, INITRD)
#=====================================================================#
{
  config,
  lib,
  pkgs,
  machine,
  ...
}: let
  #--- The generation the boot menu starts (0 is the newest), and the ESP the
  #--- installer writes its files and EFI variables to
  startOn = machine.boot.menu.default;
  esp = config.boot.loader.efi.efiSysMountPoint;
in {
  #--------------------------------------------------------------------#
  #-- Kernel Selection (controlled by kernel in machine settings)
  #--------------------------------------------------------------------#
  #--- "cachyos" is the x86-64-v3 build, so the host CPU must support x86-64-v3 (AVX2)
  boot.kernelPackages =
    if machine.kernel == "zen"
    then pkgs.linuxPackages_zen
    else if machine.kernel == "latest"
    then pkgs.linuxPackages_latest
    else if machine.kernel == "xanmod"
    then pkgs.linuxPackages_xanmod
    else if machine.kernel == "cachyos"
    then pkgs.cachyosKernels.linuxPackages-cachyos-latest-x86_64-v3
    else pkgs.linuxPackages_zen; # Default fallback

  #--------------------------------------------------------------------#
  #-- Boot Configuration
  #--------------------------------------------------------------------#
  boot = {
    tmp.cleanOnBoot = true;
    tmp.useTmpfs = true; # Store /tmp in RAM
    supportedFilesystems = ["ntfs"]; # Support NTFS (windows) filesystems
    consoleLogLevel = 0; # Suppress kernel boot messages
    kernelParams = [
      "quiet" # Suppress kernel messages on boot & shutdown
      "rd.systemd.show_status=false" # Hide systemd status during initrd
      "rd.udev.log_level=3" # Reduce udev initrd logging
      "udev.log_priority=3" # Reduce udev boot logging
    ];
    loader = {
      timeout = machine.boot.menu.timeout;
      systemd-boot = {
        enable = true;
        configurationLimit = machine.boot.menu.entries; # Generations the menu lists
        consoleMode = "max"; # Use full console resolution
        # An entry picked in the menu itself lives in an EFI variable that
        # outranks loader.conf, and the installer starts the newest generation:
        # clear both, then name the chosen one in loader.conf (entries are
        # named nixos-<content hash>.conf, so find it by its version line)
        extraInstallCommands =
          ''
            ${config.systemd.package}/bin/bootctl --esp-path=${esp} set-default ""
            ${config.systemd.package}/bin/bootctl --esp-path=${esp} set-timeout ""
          ''
          + lib.optionalString (startOn > 0) ''
            entry=$(
              for f in ${esp}/loader/entries/*.conf; do
                if ${pkgs.gnugrep}/bin/grep -qs "^version Generation ${toString startOn} " "$f" \
                  && ! ${pkgs.gnugrep}/bin/grep -qs "^title .*(" "$f"; then
                  echo "$f"
                  break
                fi
              done
            )
            if [ -n "$entry" ]; then
              ${pkgs.gnused}/bin/sed -i -E "s|^default .*|default $(${pkgs.coreutils}/bin/basename "$entry")|" \
                ${esp}/loader/loader.conf
            fi
          '';
      };
      efi.canTouchEfiVariables = true;
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
