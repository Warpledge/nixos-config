#=====================================================================#
# GNOME SERVICES CONFIGURATION
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- DBus GNOME Service Packages
  #--------------------------------------------------------------------#
  services = {
    dbus.packages = with pkgs; [
      gcr_3 # Credentials Manager; ships the org.gnome.keyring.*Prompter dbus services (gcr_4 ships none)
      gnome-keyring # Keyring service for credential storage
      gnome-settings-daemon # Settings Daemon
      libsecret # Service for secure credential storage
    ];
  };
}
