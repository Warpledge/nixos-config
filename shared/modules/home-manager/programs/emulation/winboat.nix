#=====================================================================#
# WINBOAT - WINDOWS APPLICATION RUNNER
#=====================================================================#
{
  config,
  lib,
  pkgs,
  hostConfig,
  ...
}: {
  config = lib.mkIf hostConfig.winboat.enable {
    #--------------------------------------------------------------------#
    #-- WinBoat Package Installation
    #--------------------------------------------------------------------#
    home.packages = with pkgs; [
      winboat
    ];

    #--------------------------------------------------------------------#
    #-- Desktop Integration
    #--------------------------------------------------------------------#
    # WinBoat is installed and will appear in application menus
    # Launch via: winboat or search in application launcher
  };
}
