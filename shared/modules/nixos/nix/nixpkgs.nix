#=====================================================================#
# NIXPKGS CONFIGURATION
#=====================================================================#
{inputs, ...}: {
  #--------------------------------------------------------------------#
  #-- Package Compatibility Settings
  #--------------------------------------------------------------------#
  nixpkgs = {
    config = {
      allowBroken = true; # Allow broken packages (for development/edge cases)
      allowUnsupportedSystem = true; # Allow packages on unsupported systems
      allowUnfree = true; # Allow unfree packages (proprietary software)
      permittedInsecurePackages = [
        "electron-40.10.5" # Required by nixcord/discord (EOL but still in use)
        "pnpm-10.29.2" # Build-time dep of astro-language-server (zed.nix)
        "pnpm-10.34.0" # Build-time dep of vue-language-server (zed.nix)
      ];
      showDerivationWarnings = []; # Disable derivation warnings
    };

    #--------------------------------------------------------------------#
    #-- Overlays
    #--------------------------------------------------------------------#
    overlays = [
      inputs.nur.overlays.default # NUR (Nix User Repository)
      inputs.claude-code.overlays.default # Claude Code CLI
      inputs.affinity-nix.overlays.default # Affinity Suite (Photo, Designer, Publisher)

      #--- niri libdisplay-info version pin (upstream regression)
      # nixpkgs bumped libdisplay-info to 0.4.0, but niri's vendored Rust
      # deps require < 0.4.0. Pin niri to the same libdisplay-info_0_2
      # fallback already used by weston/cosmic-comp for this reason.
      # Remove once niri's Cargo deps are updated upstream.
      (_final: prev: {
        niri = prev.niri.override {
          libdisplay-info = prev.libdisplay-info_0_2;
        };
      })
    ];
  };
}
