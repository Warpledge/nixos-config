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
      #--- `allowBroken` skips only nixpkgs' automatic `meta.broken`; a package
      #--- flagged by hand in `meta.problems` needs a handler of its own
      problems.handlers."gtk+".broken = "warn"; # ir-lv2's GUI is gtk2
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
      #--- opencode 2.2.5's node_modules hash is stale; drop once NixOS/nixpkgs#582675
      #--- lands. opencode-desktop inherits node_modules from this package
      (_: prev: {
        opencode = prev.opencode.overrideAttrs (old: {
          node_modules = old.node_modules.overrideAttrs {
            outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
          };
        });
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
