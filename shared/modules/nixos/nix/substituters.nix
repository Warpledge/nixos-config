#=====================================================================#
# CACHIX BINARY CACHE CONFIGURATION
#=====================================================================#
{
  #--------------------------------------------------------------------#
  #-- Substituters and Signing Keys
  #--------------------------------------------------------------------#
  nix.settings = {
    substituters = [
      "https://cache.nixos.org?priority=10" # Official NixOS cache
      "https://nix-community.cachix.org" # Community packages
      "https://nix-gaming.cachix.org" # Gaming packages
      "https://hyprland.cachix.org" # Hyprland WM
      "https://niri.cachix.org" # Niri WM
      "https://nixos-rocm.cachix.org" # AMD ROCM/GPU packages
      "https://claude-code.cachix.org" # Claude Code CLI
      "https://vicinae.cachix.org" # Community packages
      "https://ghostty.cachix.org" # Ghostty terminal
      "https://cache.garnix.io" # Garnix cache for affinity-nix
      "https://attic.xuyh0120.win/lantian" # CachyOS kernel
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "nixos-rocm.cachix.org-1:VEpsf7pRIijjd8csKjFNBGzkBqOmw8H9PRmgAq14LnE="
      "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
      "garnix.io:CTFPyKSLcx5PfjUjecm6qvvJC7ccXistiQ15g14FJh8="
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    ];
  };
}
