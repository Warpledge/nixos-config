#=====================================================================#
# OPENCODE - OPEN SOURCE AI CODING AGENT
#=====================================================================#
{
  config,
  lib,
  pkgs,
  user,
  ...
}: {
  config = lib.mkIf user.opencode.enable {
    #--- It reads the skills from ~/.agents/skills (agent-skills.nix); without this
    #--- it also lists the same ones from Claude Code's ~/.claude/skills
    home.sessionVariables.OPENCODE_DISABLE_CLAUDE_CODE_SKILLS = "1";

    #--------------------------------------------------------------------#
    #-- Package Installation
    #--------------------------------------------------------------------#
    programs.opencode = {
      enable = true;
      enableMcpIntegration = true;
      settings.share = "disabled"; # No /share uploads to opencode.ai
      tui.theme = "dank"; # written by DMS's matugen (theme/matugen.nix)
      #--- OpenCode Zen's free models whose provider keeps no data and doesn't train
      #--- on it (opencode.ai/docs/zen); the rest are hidden
      settings.provider.opencode.whitelist = [
        "deepseek-v4.1-flash-free"
        "glm-5.3-flash-free"
        "longcat-2.5-preview-free"
        "jev-1.13-free"
      ];
      #--- Ask before touching paths outside the project (v1's default; v2 allows),
      #--- except /tmp, where local models keep scratch notes. The last match wins
      settings.permissions = [
        {
          action = "external_directory";
          resource = "*";
          effect = "ask";
        }
        {
          action = "external_directory";
          resource = "/tmp/*";
          effect = "allow";
        }
      ];

      #--- Context7 indexes JS/Python framework docs; deepwiki and grep provide
      #--- upstream wiki docs and real-world code examples.
      #--- Overrides replace the whole entry, so the full server is restated here.
      settings.mcp.context7 = {
        type = "local";
        command = [(lib.getExe pkgs.context7-mcp)];
        # Same file as tokenDir in mcp.nix
        environment.CONTEXT7_API_KEY = "{file:${config.home.homeDirectory}/.nixos-config-mcp/context7}";
        enabled = true;
      };

      settings.mcp.deepwiki = {
        type = "remote";
        url = "https://mcp.deepwiki.com/mcp";
        enabled = true;
      };
      settings.mcp.grep = {
        type = "remote";
        url = "https://mcp.grep.app";
        enabled = true;
      };
    };
  };
}
