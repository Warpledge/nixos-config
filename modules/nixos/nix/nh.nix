#=====================================================================#
# NIX HELPER (NH) AND BUILD MONITORING
#=====================================================================#
{
  pkgs,
  machine,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Nix Helper Configuration
  #--------------------------------------------------------------------#
  programs.nh = {
    enable = true; # Enable nh (Nix Helper)
    clean = {
      enable = true;
      extraArgs = "--keep-since 5d --keep 5"; # Keep 5 days + 5 generations
    };
    flake = machine.flakePath; # flakePath in the machine's settings.nix
  };

  #--------------------------------------------------------------------#
  #-- Build Monitoring Tools
  #--------------------------------------------------------------------#
  environment.systemPackages = with pkgs; [
    nix-output-monitor # Monitor Nix builds with stats
    nvd # Show differences between NixOS generations
  ];
}
