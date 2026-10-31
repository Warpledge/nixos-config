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
        enabled = user.claude.mcp.context7;
      };

      settings.mcp.deepwiki = {
        type = "remote";
        url = "https://mcp.deepwiki.com/mcp";
        enabled = user.claude.mcp.deepwiki;
      };
      settings.mcp.grep = {
        type = "remote";
        url = "https://mcp.grep.app";
        enabled = user.claude.mcp.grep;
      };
      #--- Off: opencode loads every tool schema up front and GitHub's are the bulk;
      #--- the local models use `gh` instead
      settings.mcp.github = {
        type = "local";
        command = [(lib.getExe pkgs.github-mcp-server) "stdio" "--read-only"];
        enabled = false;
      };
    };
  };
}
