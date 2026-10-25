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
      allowUnsupportedSystem = true;
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
      inputs.claude-code.overlays.default
      inputs.affinity-nix.overlays.default # Affinity Suite (Photo, Designer, Publisher)
      #--- mcp-nixos 3.1+ on its own FastMCP 4 set. nixpkgs' mcp-types reads the final
      #--- mcp's version, which upstream's extension decides from mcp-types: pin it to
      #--- nixpkgs' mcp first or the set recurses
      (final: _: {
        mcp-nixos = inputs.mcp-nixos.lib.mkMcpNixos {
          pkgs = final;
          python3Packages = final.python3Packages.overrideScope (_: pyPrev: {
            mcp-types = pyPrev.mcp-types.override {inherit (pyPrev) mcp;};
          });
        };
      })
      #--- Python mcp 2 fallout; drop once nixpkgs fixes it
      (_: prev: {
        pythonPackagesExtensions =
          prev.pythonPackagesExtensions
          ++ [
            (_: pyPrev: {
              # One test reads mcp 1's structuredContent (open-webui, via chromadb)
              posthog = pyPrev.posthog.overridePythonAttrs (old: {
                disabledTests =
                  (old.disabledTests or [])
                  ++ ["test_prepare_tool_result_delivers_into_call_tool_result_models"];
              });
            })
          ];
      })
    ];
  };
}
