#=====================================================================#
# TWINTAIL LAUNCHER (FLATPAK)
#=====================================================================#
{
  #--------------------------------------------------------------------#
  #-- TwintailLauncher
  #--------------------------------------------------------------------#
  # Open-source gacha game launcher. Not packaged in nixpkgs, so it ships as a
  # Flatpak — this list merges with shared/modules/nixos/programs/flatpak.nix
  # (services.flatpak must be enabled there).
  services.flatpak.packages = [
    "app.twintaillauncher.ttl"
  ];
}
