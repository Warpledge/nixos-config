#=====================================================================#
# OPENCODE DESKTOP
#=====================================================================#
# OpenCode's official desktop app: a Claude Desktop-style GUI that runs
# the same server and shares your sessions and config with the opencode
# CLI. Built from upstream in nixpkgs.
{pkgs, ...}: {
  home.packages = [pkgs.opencode-desktop];
}
