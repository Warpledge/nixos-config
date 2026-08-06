#=====================================================================#
# COSMIC NIXOS CONFIGURATION
#=====================================================================#
{
  pkgs,
  username,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Desktop Environment
  #--------------------------------------------------------------------#
  services = {
    desktopManager.cosmic = {
      enable = true;
      xwayland.enable = true; # X11 apps (Steam/Proton/Wine) under cosmic-comp
    };

    #--------------------------------------------------------------------#
    #-- Display Manager
    #--------------------------------------------------------------------#
    # cosmic-greeter is a greetd session, so the gdm/greetd unmask activation
    # script in shared/modules/nixos/system/xserver.nix already covers
    # switching to and from this WM.
    displayManager = {
      cosmic-greeter.enable = true;

      #--- Auto Login
      autoLogin = {
        enable = false;
        user = "${username}";
      };
    };
  };

  #--------------------------------------------------------------------#
  #-- PAM & Authentication
  #--------------------------------------------------------------------#
  #--- Unlock GPG keyring on login
  security.pam.services.cosmic-greeter.enableGnomeKeyring = true;
  security.pam.services.${username}.enableGnomeKeyring = true;

  #--------------------------------------------------------------------#
  #-- Excluded Base Packages
  #--------------------------------------------------------------------#
  # Only non-core packages are listed here. Excluding anything from the
  # module's `corePkgs` list (cosmic-comp, cosmic-files, cosmic-panel,
  # cosmic-settings, ...) makes the session fail to initialize and trips a
  # build warning, so leave those alone even when a replacement is installed.
  environment.cosmic.excludePackages = with pkgs; [
    cosmic-edit # superseded by editors.zed
    cosmic-player # superseded by media.mpv / celluloid
    cosmic-term # superseded by terminals.kitty
  ];

  #--------------------------------------------------------------------#
  #-- XDG Portal Configuration
  #--------------------------------------------------------------------#
  # Intentionally left to the upstream COSMIC module, which sets
  # xdg-desktop-portal-cosmic + -gtk and the matching configPackages.
  # shared/modules/nixos/system/wayland.nix only uses lib.mkDefault, so the
  # COSMIC portals win without an override here.
}
