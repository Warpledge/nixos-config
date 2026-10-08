#=====================================================================#
# DESKTOP PLATFORM SERVICES
#=====================================================================#
{pkgs, ...}: {
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
}
