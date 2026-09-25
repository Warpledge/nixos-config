#=====================================================================#
# HOME MANAGER SERVICES
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Clipboard History
  #--------------------------------------------------------------------#
  services = {
    cliphist = {
      enable = true;
      allowImages = true;
    };

    #--------------------------------------------------------------------#
    #-- GNOME Keyring Service
    #--------------------------------------------------------------------#
    gnome-keyring = {
      enable = true;
    };

    #--------------------------------------------------------------------#
    #-- GPG Auth Agent
    #--------------------------------------------------------------------#
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
      pinentry.package = pkgs.pinentry-gnome3;
    };
  };

  #--------------------------------------------------------------------#
  #-- Break gpg-agent SSH ordering cycle
  #--------------------------------------------------------------------#
  #--- Drop default deps to break a startup ordering cycle: the service
  #--- runs both after and before basic.target. It doesn't need basic.target.
  systemd.user.services.set-SSH_AUTH_SOCK.Unit.DefaultDependencies = false;
}
