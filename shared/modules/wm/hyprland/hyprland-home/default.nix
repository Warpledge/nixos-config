#=====================================================================#
# HYPRLAND HOME MANAGER MODULE IMPORTS
#=====================================================================#
{
  imports = [
    #--- Core Configuration
    ./core

    #--- Scripts
    ./scripts/scripts.nix

    #--- Shell & Services
    ./shell/dms/core.nix
  ];
}
