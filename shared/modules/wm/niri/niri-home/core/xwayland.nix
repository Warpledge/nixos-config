#=====================================================================#
# NIRI XWAYLAND SATELLITE CONFIGURATION
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Xwayland Satellite
  #--------------------------------------------------------------------#
  home.packages = with pkgs; [xwayland-satellite];

  programs.niri.settings = {
    xwayland-satellite = {
      enable = true;
    };
  };
}
