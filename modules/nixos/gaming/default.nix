#=====================================================================#
# GAMING MODULE IMPORTS
#=====================================================================#
{
  lib,
  anyUser,
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
      ./tools/gamescope
      ./tools/java.nix
    ]
    #--- Game Launchers (system-wide once any user has gaming.steam)
    ++ lib.optionals anyUser.gaming.steam [./steam.nix];
}
