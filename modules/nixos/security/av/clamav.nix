#=====================================================================#
# CLAMAV ANTIVIRUS CONFIGURATION
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- ClamAV Daemon & Updater
  #--------------------------------------------------------------------#
  services.clamav = {
    daemon.enable = true; # clamd background scanning daemon

    updater = {
      enable = true; # freshclam auto-updates virus definitions
      frequency = 2; # Check for definition updates twice daily
    };
  };

  #--------------------------------------------------------------------#
  #-- Packages
  #--------------------------------------------------------------------#
  environment.systemPackages = with pkgs; [
    clamav # CLI scanner (clamscan, clamdscan)
    clamtk # GUI frontend for ClamAV
  ];
}
