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
      settings.instructions = ["CLAUDE.md"]; # Load CLAUDE.md alongside AGENTS.md

      #--- Context7 indexes JS/Python framework docs; deepwiki and grep provide
      #--- upstream wiki docs and real-world code examples.
      settings.mcp.context7 = {
        type = "local";
        command = [(lib.getExe pkgs.context7-mcp)];
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
