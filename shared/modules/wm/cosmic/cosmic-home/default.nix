#=====================================================================#
# COSMIC HOME MANAGER MODULE IMPORTS
#=====================================================================#
{inputs, ...}: {
  imports = [
    #--- Declarative COSMIC Configuration
    # Provides the wayland.desktopManager.cosmic.* option surface.
    inputs.cosmic-manager.homeManagerModules.cosmic-manager

    #--- Core Configuration
    ./core/binds.nix
    ./core/mime.nix
    ./core/settings.nix

    #--- Shell & Panel
    ./shell/applets.nix
    ./shell/panel.nix

    #--- Themes
    ./themes
  ];
}
