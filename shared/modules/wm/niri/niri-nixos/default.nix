#=====================================================================#
# NIRI NIXOS CONFIGURATION
#=====================================================================#
{
  pkgs,
  lib,
  username,
  inputs,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Window Manager
  #--------------------------------------------------------------------#
  programs.niri.enable = true;

  #--------------------------------------------------------------------#
  #-- Display Manager
  #--------------------------------------------------------------------#
  services = {
    displayManager.sessionPackages = [pkgs.niri];
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${lib.getExe pkgs.tuigreet} --time --asterisks --remember --cmd niri-session";
          user = "greeter";
        };
      };
    };
  };

  #--------------------------------------------------------------------#
  #-- PAM & Authentication
  #--------------------------------------------------------------------#
  #--- Unlock GPG keyring on login
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.${username}.enableGnomeKeyring = true;

  #--------------------------------------------------------------------#
  #-- Auto Login
  #--------------------------------------------------------------------#
  services.displayManager.autoLogin = {
    enable = false;
    user = "${username}";
  };

  #--------------------------------------------------------------------#
  #-- XDG Portal Configuration
  #--------------------------------------------------------------------#
  xdg.portal = {
    config = {
      common = {
        default = lib.mkForce ["gnome" "gtk"];
        "org.freedesktop.impl.portal.ScreenCast" = "gnome";
        "org.freedesktop.impl.portal.Screenshot" = "gnome";
        "org.freedesktop.impl.portal.RemoteDesktop" = "gnome";
      };
    };
    extraPortals = lib.mkForce [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
  };
}
