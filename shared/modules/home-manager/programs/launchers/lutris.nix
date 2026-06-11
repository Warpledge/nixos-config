#=====================================================================#
# LUTRIS
#=====================================================================#
{pkgs, ...}: {
  # Wine-based launcher with per-game prefixes — also drives DLSite/DMM
  # visual-novel installers (see .notes/gaming/launcher-env-variables.md).
  home.packages = [pkgs.lutris];
}
