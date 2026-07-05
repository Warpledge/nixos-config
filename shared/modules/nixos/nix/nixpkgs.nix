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
        "electron-38.8.4" # Required by nixcord/discord (EOL but still in use)
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
    ];
  };
}
