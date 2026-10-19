#=====================================================================#
# CLAUDE DESKTOP - ANTHROPIC'S DESKTOP APP (CHAT, CODE)
#=====================================================================#
#- Anthropic's official Linux .deb, patched by the claude-desktop input.
#- The Code tab downloads its own Claude Code binary, which runs through
#- nix-ld (nixos/services/runtimes/runners.nix).
{
  inputs,
  lib,
  pkgs,
  ...
}: let
  # Cowork's VM needs system-side firmware paths and the kvm group
  claude-desktop =
    (pkgs.callPackage "${inputs.claude-desktop}/package.nix" {withCowork = false;})
    .overrideAttrs (old: {
      # Launch by name so the Mullvad split-tunnel wrapper on PATH applies
      postFixup =
        old.postFixup
        + ''
          sed -i 's|^Exec=[^ ]*|Exec=claude-desktop|' $out/share/applications/*.desktop
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
  };
}
