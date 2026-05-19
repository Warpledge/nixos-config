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
  #-- Polkit Agent
  #--------------------------------------------------------------------#
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    Unit.Description = "polkit-gnome-authentication-agent-1";

    Install = {
      WantedBy = ["graphical-session.target"];
      Wants = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 3; # Wait 3 seconds before restarting to avoid thrashing
      TimeoutStopSec = 10;
    };
  };
}
