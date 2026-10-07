#=====================================================================#
# HYPRLAND NIXOS CONFIGURATION
#=====================================================================#
{
  inputs,
  username,
  ...
}: {
  imports = [inputs.dank-greeter.nixosModules.default];

  #--------------------------------------------------------------------#
  #-- Window Manager
  #--------------------------------------------------------------------#
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  #--------------------------------------------------------------------#
  #-- Display Manager
  #--------------------------------------------------------------------#
  services.greetd = {
    enable = true;
    # command is set by programs.dms-greeter (mkDefault) below
    settings.default_session.user = "greeter";
  };

  #--- DMS Greeter (mirrors niri-nixos)
  # Theme, wallpaper and settings are copied out of configHome into
  # /var/lib/dms-greeter on each greetd start, so they lag one restart.
  programs.dms-greeter = {
    enable = true;
    compositor.name = "hyprland";
    configHome = "/home/${username}";
  };

  #--- The module's preStart chowns `*`, which skips dotfiles, so dirs left by an
  #--- older greeter install (different uid) lock the greeter out of its own cache.
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
}
