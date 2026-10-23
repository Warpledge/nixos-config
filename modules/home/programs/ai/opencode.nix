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
      #--- Hides OpenCode Zen's free models that keep or train on prompts
      #--- (opencode.ai/docs/zen). v2 ignores `whitelist`; "deprecated" becomes v2's
      #--- `disabled`, so a free model added later shows until it's listed here
      settings.provider.opencode.models = lib.genAttrs [
        "big-pickle"
        "beam-free"
        "flint-40b-free"
        "mimo-v2.6-flash-free"
        "mimo-v2.5-free"
        "exo-free"
        "nemotron-3-ultra-free"
        "nemotron-3.5-lightning-free"
        "nemotron-3.5-super-vl-free"
      ] (_: {status = "deprecated";});
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
