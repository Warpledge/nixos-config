#=====================================================================#
# NIRI HOME MANAGER MODULE IMPORTS
#=====================================================================#
{inputs, ...}: {
  imports = [
    inputs.niri.homeModules.niri

    #--- Addons
    ./addons/niriswitcher.nix

    #--- Core Configuration
    ./core/binds.nix
    ./core/monitors.nix
    ./core/rules.nix
    ./core/settings.nix
    ./core/xwayland.nix

    #--- Shell & Services
    ./shell/dms/core.nix
  ];
}
