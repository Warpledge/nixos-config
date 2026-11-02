#=====================================================================#
# NIRI SESSION (NIXOS)
#=====================================================================#
{
  pkgs,
  lib,
  config,
  inputs,
  machine,
  ...
}: let
  # niri-flake's git build, for 10-bit output (docs/todo/niri-10-bit.md)
  niri = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
  configHome = "/home/${machine.mainUser}";
  cursorIcons = "${config.stylix.cursor.package}/share/icons";
in {
  imports = [inputs.dux-greeter.nixosModules.default];

  #--------------------------------------------------------------------#
  #-- Window Manager
  #--------------------------------------------------------------------#
  programs.niri = {
    enable = true;
    package = niri;
  };

  #--------------------------------------------------------------------#
  #-- Display Manager
  #--------------------------------------------------------------------#
  services = {
    displayManager.sessionPackages = [niri];
    greetd = {
      enable = true;
      # command is set by programs.dms-greeter (mkDefault) below
      settings.default_session.user = "greeter";
    };
  };

  #--- DMS Greeter
  # Theme, wallpaper and settings are copied out of configHome (the main
  # user's) into /var/lib/dms-greeter on each greetd start, so they lag one restart.
  programs.dms-greeter = {
    enable = true;
    compositor.name = "niri";
    inherit configHome;

    #--- DMS writes these from the desktop's monitor, input and cursor
    #--- settings; the greeter's niri config includes the copies (below).
    configFiles = [
      "${configHome}/.config/niri/dms/outputs.kdl"
      "${configHome}/.config/niri/dms/input.kdl"
      "${configHome}/.config/niri/dms/cursor.kdl"
    ];
  };

  #--- dux-greeter's built-in niri config has no cursor or outputs, so it
  #--- loads the "default" cursor and each monitor's preferred mode (60 Hz
  #--- on the OLED). Its launcher includes this file. The DMS fragments are
  #--- copied into /var/lib/dms-greeter at greetd start, like the theme.
  systemd.services.greetd.environment.XCURSOR_PATH = cursorIcons;
  #--- PAM's XCURSOR_PATH points at the system profile, which has no theme
  #--- beyond hicolor; Stylix installs the cursor only in user profiles.
  environment.systemPackages = [config.stylix.cursor.package];
  environment.etc."greetd/niri_overrides.kdl".text = ''
    cursor {
        xcursor-theme "${config.stylix.cursor.name}"
        xcursor-size ${toString config.stylix.cursor.size}
    }

    include optional=true "/var/lib/dms-greeter/cursor.kdl"
    include optional=true "/var/lib/dms-greeter/outputs.kdl"
    include optional=true "/var/lib/dms-greeter/input.kdl"
  '';

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
  security.pam.services.${machine.mainUser}.enableGnomeKeyring = true;

  #--------------------------------------------------------------------#
  #-- Auto Login
  #--------------------------------------------------------------------#
  services.displayManager.autoLogin = {
    enable = false;
    user = machine.mainUser;
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
    # The default PATH hides user apps, which blanks the Open With dialog
    enableDefaultPath = false;
    serviceConfig.UnsetEnvironment = "GDK_BACKEND";
  };
}
