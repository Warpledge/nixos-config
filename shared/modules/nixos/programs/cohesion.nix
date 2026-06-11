#=====================================================================#
# COHESION (NOTION ALTERNATIVE, FLATPAK)
#=====================================================================#
{
  #--------------------------------------------------------------------#
  #-- Cohesion
  #--------------------------------------------------------------------#
  # Self-hostable Notion-style notes app. Not packaged in nixpkgs, so it ships
  # as a Flatpak — this list merges with shared/modules/nixos/programs/
  # flatpak.nix (services.flatpak must be enabled there).
  services.flatpak.packages = [
    "io.github.brunofin.Cohesion"
  ];
}
