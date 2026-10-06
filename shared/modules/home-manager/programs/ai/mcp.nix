#=====================================================================#
# MCP SERVERS - SHARED BY CLAUDE CODE AND OPENCODE
#=====================================================================#
{
  config,
  lib,
  pkgs,
  ...
}: {
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
        env.CONTEXT7_API_KEY.file = "${config.xdg.configHome}/context7/api-key";
      };
    };
  };
}
