#=====================================================================#
# NIRI HOME MANAGER MODULE IMPORTS
#=====================================================================#
{inputs, ...}: {
  #--------------------------------------------------------------------#
  #-- Imports
  #--------------------------------------------------------------------#
  imports = [
    inputs.niri.homeModules.niri

    #--- Addons
    ./niriswitcher.nix

    #--- Core Configuration
    ./core/binds.nix
    ./core/monitors.nix
    ./core/portals.nix
    ./core/rules.nix
    ./core/settings.nix
    ./core/xwayland.nix

    #--- Shell & Services
    ./dms
  ];
}
