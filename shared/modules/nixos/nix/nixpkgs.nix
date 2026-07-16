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

      #--- AppArmor 5.0.0 reload fix (upstream regression)
      # apparmor 5.0.0 moved rc.apparmor.functions from apparmor-parser to
      # apparmor-init, but aa-remove-unknown still resolves it against the
      # parser output, breaking `apparmor.service` reload during activation.
      # apparmor-parser is only used to locate that file, so point it at
      # apparmor-init. Remove once fixed in nixpkgs.
      (_final: prev: {
        apparmor-utils = prev.apparmor-utils.override {
          apparmor-parser = prev.apparmor-init;
        };
      })
    ];
  };
}
