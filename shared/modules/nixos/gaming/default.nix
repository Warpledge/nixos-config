#=====================================================================#
# GAMING MODULE IMPORTS
#=====================================================================#
{
  lib,
  hostConfig,
  ...
}: {
  imports =
    [
      ./esync.nix
      ./gamemode.nix
      ./gamescope.nix
      ./java.nix
      ./kernel.nix
    ]
    #--- Game Launchers (controlled by hostConfig)
    ++ lib.optionals hostConfig.gameLaunchers.steam [./steam.nix]
    ++ lib.optionals hostConfig.gameLaunchers.twintail [./twintail.nix];
}
