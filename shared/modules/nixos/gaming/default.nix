#=====================================================================#
# GAMING MODULE IMPORTS
#=====================================================================#
{
  lib,
  hostConfig,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Imports
  #--------------------------------------------------------------------#
  imports =
    [
      ./performance/esync.nix
      ./performance/gamemode.nix
      ./performance/kernel.nix
      ./tools/gamescope.nix
      ./tools/java.nix
    ]
    #--- Game Launchers (controlled by hostConfig)
    ++ lib.optionals hostConfig.gaming.steam [./launchers/steam.nix];
}
