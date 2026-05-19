#=====================================================================#
# GNOME SERVICES CONFIGURATION
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- DBus GNOME Service Packages
  #--------------------------------------------------------------------#
  services = {
    dbus.packages = with pkgs; [
      gcr # Credentials Manager for password/certificate handling
      gnome-keyring # Keyring service for credential storage
      gnome-settings-daemon # Settings Daemon
      libsecret # Service for secure credential storage
    ];
  };
}
