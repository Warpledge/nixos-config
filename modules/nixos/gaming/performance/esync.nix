#=====================================================================#
# ESYNC/FSYNC OPTIMIZATION FOR WINE/PROTON
#=====================================================================#
{
  lib,
  machine,
  ...
}: {
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
  #--- For each user on the machine
  security.pam.loginLimits = lib.concatMap (name: [
    {
      domain = name;
      type = "hard";
      item = "nofile";
      value = "1048576"; # Hard limit: 1M file descriptors
    }
    {
      domain = name;
      type = "soft";
      item = "nofile";
      value = "1048576"; # Soft limit: 1M file descriptors
    }
  ]) (lib.attrNames machine.users);
}
