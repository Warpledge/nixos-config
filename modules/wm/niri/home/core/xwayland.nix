#=====================================================================#
# NIRI XWAYLAND SATELLITE CONFIGURATION
#=====================================================================#
{
  pkgs,
  lib,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Xwayland Satellite
  #--------------------------------------------------------------------#
  home.packages = [pkgs.xwayland-satellite];

  programs.niri.settings = {
    xwayland-satellite = {
      enable = true;
      # Pin the binary explicitly; niri otherwise resolves it from PATH.
      path = lib.getExe pkgs.xwayland-satellite;
    };
  };
}
