#=====================================================================#
# NIRI NIXOS CONFIGURATION
#=====================================================================#
{
  pkgs,
  lib,
  inputs,
  username,
  ...
}: {
  imports = [inputs.dank-greeter.nixosModules.default];

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
      # command is set by programs.dms-greeter (mkDefault) below
      settings.default_session.user = "greeter";
    };
  };

  #--- DMS Greeter
  # Theme, wallpaper and settings are copied out of configHome into
  # /var/lib/dms-greeter on each greetd start, so they lag one restart.
  programs.dms-greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = "/home/${username}";
  };

  #--- The module's preStart chowns `*`, which skips dotfiles, so dirs left by an
  #--- older greeter install (different uid) lock the greeter out of its own cache
  #--- and it exits before creating a session.
  systemd.tmpfiles.settings."11-dms-greeter-own"."/var/lib/dms-greeter".Z = {
    user = "greeter";
    group = "greeter";
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

  #--- Strip GDK_BACKEND from the GNOME portal
  # It exposes Settings only when GDK_BACKEND is set, which kills FileChooser
  # and ScreenCast; variables.nix keeps the X11 fallback for everything else.
  systemd.user.services.xdg-desktop-portal-gnome = {
    overrideStrategy = "asDropin";
    serviceConfig.UnsetEnvironment = "GDK_BACKEND";
  };
}
