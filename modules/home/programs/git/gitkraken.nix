#=====================================================================#
# GITKRAKEN CONFIGURATION
#=====================================================================#
#- Git client with a commit graph; free plan covers local and public repos
{pkgs, ...}: {
  home.packages = [pkgs.gitkraken];
}
