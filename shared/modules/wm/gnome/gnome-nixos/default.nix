#=====================================================================#
# GNOME NIXOS CONFIGURATION
#=====================================================================#
{
  pkgs,
  username,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Display Manager
  #--------------------------------------------------------------------#
  services = {
    xserver.excludePackages = [pkgs.xterm];

    #--- Desktop Manager
    desktopManager = {
      gnome = {
        enable = true; # gnome desktop environment
        sessionPath = [pkgs.libgtop];
      };
    };

    #--- Display Manager
    displayManager.gdm.enable = true;

    #--- GNOME Services
    avahi.enable = false; # printing
    gnome = {
      # core-apps.enable = false; # core base apps
      localsearch.enable = false; # file trackers
    };

  };

  #--------------------------------------------------------------------#
  #-- PAM & Authentication
  #--------------------------------------------------------------------#
  security.pam.services.gdm.enableGnomeKeyring = true;
  security.pam.services.${username}.enableGnomeKeyring = true;

  #--------------------------------------------------------------------#
  #-- System Packages
  #--------------------------------------------------------------------#
  environment.systemPackages = with pkgs; [
    #--- Astra Monitor Extension Dependencies
    nethogs
    iw
    iotop
    libgtop
  ];

  #--------------------------------------------------------------------#
  #-- Excluded Base Packages
  #--------------------------------------------------------------------#
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour # Welcome/tutorial app for new GNOME users
    epiphany # Web browser
    geary # Email reader
    gnome-contacts # Contact manager
    gnome-connections # Remote desktop client
    gnome-weather # Weather forecast app
    gnome-maps # Maps and navigation
    gnome-music # Music player
    gnome-system-monitor # System resource monitor
    gnome-disk-utility # Disk management tool
    gnome-console # Terminal emulator
    gnome-font-viewer # Font preview utility
    totem # Video player
    cheese # Webcam application
    simple-scan # Document scanner
    yelp # Help browser
    gnome-bluetooth # Bluetooth manager
    gnome-terminal # Traditional terminal emulator
    orca # Screen reader
    # snapshot # Screenshot utility
    # seahorse # Password and encryption key manager
    papers
  ];
}
