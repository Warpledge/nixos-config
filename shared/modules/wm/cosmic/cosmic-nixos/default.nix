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
    # cosmic-greeter is a greetd session, already covered by the unmask
    # activation script in shared/modules/nixos/system/xserver.nix.
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
  # Non-core packages only — excluding anything from the module's `corePkgs`
  # list (cosmic-comp, cosmic-files, cosmic-panel, cosmic-settings, ...)
  # breaks session startup.
  environment.cosmic.excludePackages = with pkgs; [
    cosmic-edit # superseded by editors.zed
    cosmic-player # superseded by media.mpv / celluloid
    cosmic-term # superseded by terminals.kitty
  ];

  #--------------------------------------------------------------------#
  #-- XDG Portal Configuration
  #--------------------------------------------------------------------#
  # Left to the upstream COSMIC module; wayland.nix uses mkDefault so the
  # COSMIC portals win without an override here.
}
