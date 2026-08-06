#=====================================================================#
# COSMIC HOME MANAGER MODULE IMPORTS
#=====================================================================#
{
  imports = [
    #--- Core Configuration
    ./core/mime.nix

    #--- Shell & Panel
    ./shell/applets.nix
    ./shell/panel.nix
  ];
}
