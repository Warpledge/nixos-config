#=====================================================================#
# CLAUDE DESKTOP - ANTHROPIC'S DESKTOP APP (CHAT, CODE)
#=====================================================================#
#- Anthropic's official Linux .deb, patched by the claude-desktop input.
#- The Code tab downloads its own Claude Code binary, which runs through
#- nix-ld (nixos/services/runtimes/runners.nix).
{
  config,
  inputs,
  lib,
  pkgs,
  user,
  ...
}: let
  # Cowork's VM needs system-side firmware paths and the kvm group
  claude-desktop =
    (pkgs.callPackage "${inputs.claude-desktop}/package.nix" {withCowork = false;})
    .overrideAttrs (old:
      {
        # Launch by name so the Mullvad split-tunnel wrapper on PATH applies
        postFixup =
          old.postFixup
          + ''
            sed -i 's|^Exec=[^ ]*|Exec=claude-desktop|' $out/share/applications/*.desktop
          '';
      }
      // lib.optionalAttrs user.claudeDesktop.matugen {
        nativeBuildInputs = old.nativeBuildInputs ++ [pkgs.asar];
        # Loads matugen-theme.js from the app's entry script; the original
        # app.asar.unpacked stays, so the repack's own unpacked copy is dropped
        postInstall =
          (old.postInstall or "")
          + ''
            res=$out/lib/claude-desktop/resources
            asar extract $res/app.asar app-src
            install -m644 ${./claude-desktop/matugen-theme.js} app-src/.vite/build/matugen-theme.js
            sed -i '1s|^"use strict";|&require("./matugen-theme.js");|' app-src/.vite/build/index.pre.js
            grep -q 'require("./matugen-theme.js")' app-src/.vite/build/index.pre.js \
              || { echo 'claude-desktop: index.pre.js no longer starts with "use strict";'; exit 1; }
            asar pack app-src repack/app.asar --unpack '{*.node,github-mcp-server}'
            cp repack/app.asar $res/app.asar
          '';
      });
in {
  #--- Read by the Mullvad split tunnel (nixos/security/mullvad/split-tunnel.nix)
  options.claude-desktop.package = lib.mkOption {
    type = lib.types.package;
    readOnly = true;
    description = "The Claude Desktop build in home.packages.";
  };

  config = {
    claude-desktop.package = claude-desktop;
    home.packages = [claude-desktop];

    matugen.templates = lib.mkIf user.claudeDesktop.matugen {
      claude-desktop = {
        input = ./claude-desktop/matugen.css.matugen;
        output = "${config.xdg.configHome}/claude-desktop/matugen.css";
      };
    };
  };
}
