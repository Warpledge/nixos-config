#=====================================================================#
# OPENCODE - OPEN SOURCE AI CODING AGENT
#=====================================================================#
{
  config,
  lib,
  pkgs,
  hostConfig,
  ...
}: {
  config = lib.mkIf hostConfig.opencode.enable {
    #--------------------------------------------------------------------#
    #-- Package Installation
    #--------------------------------------------------------------------#
    programs.opencode = {
      enable = true;
      enableMcpIntegration = true;

      #--- Off for the local model: context7 indexes JS/Python framework docs, and its
      #--- ~4.9KB of tool schemas ship in every request (nixos is ~6.7KB).
      #--- Overrides replace the whole entry, so the full server is restated here.
      settings.mcp.context7 = {
        type = "local";
        command = [(lib.getExe pkgs.context7-mcp)];
        environment.CONTEXT7_API_KEY = "{file:${config.home.homeDirectory}/.nixos-config-mcp/context7}"; # tokenDir in mcp.nix
        enabled = false;
      };

      #--- Off for the local model too, to keep their tool schemas out of its context
      settings.mcp.deepwiki = {
        type = "remote";
        url = "https://mcp.deepwiki.com/mcp";
        enabled = false;
      };
      settings.mcp.grep = {
        type = "remote";
        url = "https://mcp.grep.app";
        enabled = false;
      };
    };
  };
}
