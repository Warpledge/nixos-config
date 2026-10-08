#=====================================================================#
# MCP SERVERS - SHARED BY CLAUDE CODE AND OPENCODE
#=====================================================================#
{
  config,
  lib,
  pkgs,
  ...
}: let
  #--- One file per server; opencode.nix reads the context7 key from here too
  tokenDir = "${config.home.homeDirectory}/.nixos-config-mcp";
in {
  #--------------------------------------------------------------------#
  #-- Server Definitions
  #--------------------------------------------------------------------#
  programs.mcp = {
    enable = true;
    servers = {
      nixos.command = lib.getExe pkgs.mcp-nixos;

      #--- Key is read from this file at launch, so it never enters the store or the repo
      context7 = {
        command = lib.getExe pkgs.context7-mcp;
        env.CONTEXT7_API_KEY.file = "${tokenDir}/context7";
      };

      #--- Fine-grained token (public repos, read-only), same file-at-launch pattern
      github = {
        command = lib.getExe pkgs.github-mcp-server;
        args = ["stdio" "--read-only"];
        env.GITHUB_PERSONAL_ACCESS_TOKEN.file = "${tokenDir}/github";
      };

      #--- Remote and keyless: Q&A over a public repo's generated wiki
      deepwiki.url = "https://mcp.deepwiki.com/mcp";

      #--- Remote and keyless: regex code search across public GitHub repos
      grep.url = "https://mcp.grep.app";
    };
  };

  #--------------------------------------------------------------------#
  #-- Token Placeholders
  #--------------------------------------------------------------------#
  # Creates the folder and empty owner-only files on a fresh host;
  # never overwrites a token
  home.activation.mcpTokenFiles = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run install -d -m 700 "${tokenDir}"
    for f in github context7; do
      [ -e "${tokenDir}/$f" ] || run install -m 600 /dev/null "${tokenDir}/$f"
    done
  '';
}
