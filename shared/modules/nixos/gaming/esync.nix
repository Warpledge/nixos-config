#=====================================================================#
# ESYNC/FSYNC OPTIMIZATION FOR WINE/PROTON
#=====================================================================#
{username, ...}: {
  #--------------------------------------------------------------------#
  #-- System File Descriptor Limits
  #--------------------------------------------------------------------#
  systemd.settings.Manager = {
    DefaultLimitNOFILE = "1048576:1048576"; # System-wide FD limit (for Esync/Fsync)
  };
  systemd.user.settings.Manager = {
    DefaultLimitNOFILE = "1048576:1048576"; # User systemd FD limit (for Esync/Fsync)
  };

  #--------------------------------------------------------------------#
  #-- NTSync Device Permissions
  #--------------------------------------------------------------------#
  services.udev.extraRules = ''
    KERNEL=="ntsync", TAG+="uaccess"
  '';

  #--------------------------------------------------------------------#
  #-- User File Descriptor Limits
  #--------------------------------------------------------------------#
  security.pam.loginLimits = [
    {
      domain = "${username}";
      type = "hard";
      item = "nofile";
      value = "1048576"; # Hard limit: 1M file descriptors
    }
    {
      domain = "${username}";
      type = "soft";
      item = "nofile";
      value = "1048576"; # Soft limit: 1M file descriptors
    }
  ];
}
