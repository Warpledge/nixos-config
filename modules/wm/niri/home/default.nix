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
    ./nirius.nix

    #--- Core Configuration
    ./core/binds.nix
    ./core/blur-presets.nix
    ./core/portals.nix
    ./core/rules.nix
    ./core/settings.nix
    ./core/xwayland.nix

    #--- Shell & Services
    ./dms
  ];
}
