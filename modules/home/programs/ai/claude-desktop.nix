#=====================================================================#
# CLAUDE DESKTOP - ANTHROPIC'S DESKTOP APP (CHAT, CODE)
#=====================================================================#
#- Anthropic's official Linux .deb, patched by the claude-desktop input.
#- The Code tab downloads its own Claude Code binary, which runs through
#- nix-ld (nixos/services/runtimes/runners.nix).
{
  inputs,
  pkgs,
  ...
}: {
  home.packages = [
    # Cowork's VM needs system-side firmware paths and the kvm group
    (pkgs.callPackage "${inputs.claude-desktop}/package.nix" {withCowork = false;})
  ];
}
