#=====================================================================#
# DESKTOP PLATFORM SERVICES
#=====================================================================#
{
  lib,
  pkgs,
  anyUser,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- DConf Registry
  #--------------------------------------------------------------------#
  programs.dconf.enable = true;

  #--------------------------------------------------------------------#
  #-- Services
  #--------------------------------------------------------------------#
  services = {
    fwupd.enable = true; # Firmware update service
    gvfs.enable = true; # Virtual filesystem (mounting, trash, etc.)
    tumbler.enable = true; # Thumbnail generation
    dbus.enable = true; # System message bus
    fstrim.enable = true; # SSD TRIM optimization
    udisks2.enable = true; # Disk management
  };

  #--------------------------------------------------------------------#
  #-- GIO Modules
  #--------------------------------------------------------------------#
  #- Without glib-networking GIO falls back to GDummyTlsBackend and every
  #- libsoup/WebKitGTK app fails HTTPS. gvfs and dconf above contribute the
  #- other GIO_EXTRA_MODULES entries.
  environment.sessionVariables.GIO_EXTRA_MODULES = ["${pkgs.glib-networking}/lib/gio/modules"];

  #--------------------------------------------------------------------#
  #-- Nautilus Terminal Entry
  #--------------------------------------------------------------------#
  #--- Right-click entry in Nautilus that opens kitty in that folder
  programs.nautilus-open-any-terminal = {
    enable = anyUser.fileBrowsers.nautilus;
    terminal = "kitty";
  };

  #--- The module points Nautilus at nautilus-python's extensions alone, which
  #--- drops Nautilus' own image and media property pages; this loads both
  environment.sessionVariables.NAUTILUS_4_EXTENSION_DIR = lib.mkIf anyUser.fileBrowsers.nautilus (lib.mkForce "${pkgs.symlinkJoin {
    name = "nautilus-extensions";
    paths = [pkgs.nautilus pkgs.nautilus-python];
    stripPrefix = "/lib/nautilus/extensions-4";
  }}");
}
