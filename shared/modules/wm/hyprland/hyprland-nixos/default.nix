#=====================================================================#
# HYPRLAND NIXOS CONFIGURATION
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Window Manager
  #--------------------------------------------------------------------#
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  #--------------------------------------------------------------------#
  #-- Greetd with Tuigreet Display Manager
  #--------------------------------------------------------------------#
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd start-hyprland";
        user = "greeter";
      };
    };
  };
}
