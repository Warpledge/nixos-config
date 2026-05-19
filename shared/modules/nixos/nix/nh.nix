#=====================================================================#
# NIX HELPER (NH) AND BUILD MONITORING
#=====================================================================#
{
  pkgs,
  username,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Nix Helper Configuration
  #--------------------------------------------------------------------#
  programs.nh = {
    enable = true; # Enable nh (Nix Helper)
    clean = {
      enable = true; # Enable automatic cleanup
      extraArgs = "--keep-since 5d --keep 5"; # Keep 5 days + 5 generations
    };
    flake = "/home/${username}/nixos-config"; # Flake location
  };

  #--------------------------------------------------------------------#
  #-- Build Monitoring Tools
  #--------------------------------------------------------------------#
  environment.systemPackages = with pkgs; [
    nix-output-monitor # Monitor Nix builds with stats
    nvd # Show differences between NixOS generations
  ];
}
