#=====================================================================#
# UTILITY PROGRAMS AND SERVICES
#=====================================================================#
{pkgs, ...}: {
  #--- Core Programs
  programs = {
    dconf.enable = true; # DConf registry (used by GNOME)
  };

  #--- System Services
  services = {
    fwupd.enable = true; # Firmware update service
    gvfs.enable = true; # Virtual filesystem (mounting, trash, etc.)
    tumbler.enable = true; # Thumbnail generation
    dbus.enable = true; # System message bus
    fstrim.enable = true; # SSD TRIM optimization
    udisks2.enable = true; # Disk management
    gnome = {
      gnome-keyring.enable = true; # GNOME Keyring for password storage
    };
  };

  #--- Documentation
  documentation = {
    enable = true; # Keep man pages
    doc.enable = false; # Disable other docs (faster build)
    man.enable = true; # Enable man pages
    dev.enable = false; # Disable development docs
    info.enable = false; # Disable info docs
    nixos.enable = false; # Disable NixOS docs
  };

  #--------------------------------------------------------------------#
  #-- System Packages
  #--------------------------------------------------------------------#
  environment.systemPackages = with pkgs; [
    lshw # Hardware inspection
    bind.dnsutils # DNS utilities
    fd # File finder (faster than find)
    bc # Calculator
    gcc # C/C++ compiler
    git # Version control
    git-ignore # .gitignore templates
    xdg-utils # XDG desktop utilities
    wget # HTTP download utility
  ];
}
