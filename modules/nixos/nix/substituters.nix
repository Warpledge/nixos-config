#=====================================================================#
# CACHIX BINARY CACHE CONFIGURATION
#=====================================================================#
{
  #--------------------------------------------------------------------#
  #-- Substituters and Signing Keys
  #--------------------------------------------------------------------#
  #- A key is trusted for any path its cache serves, so list only caches the inputs use
  nix.settings = {
    substituters = [
      "https://cache.nixos.org?priority=10" # Official NixOS cache
      "https://nix-community.cachix.org" # Community packages
      "https://niri.cachix.org" # Niri WM
      "https://niri-epireyn.cachix.org" # Niri WM, epireyn's niri-flake builds
      "https://claude-code.cachix.org" # Claude Code CLI
      "https://moku.cachix.org" # Moku manga/anime reader + Tsunagu backend
      # "https://cache.garnix.io" # Garnix cache for affinity-nix
      # CachyOS kernel cache; off since 2026-10-07 (server refuses connections)
      # "https://attic.xuyh0120.win/lantian"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "niri-epireyn.cachix.org-1:tlVyFN7CtsDT+ZcLPS+ekFWeT1X6X4OqvWqbBMyIzFA="
      "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
      "moku.cachix.org-1:EnMXp6/uQVI6IRbKW0xEQylSYoV2N4vszOsoW6/Pq1s="
      # "garnix.io:CTFPyKSLcx5PfjUjecm6qvvJC7ccXistiQ15g14FJh8="
      # Re-enable with the lantian substituter above
      # "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    ];
  };
}
