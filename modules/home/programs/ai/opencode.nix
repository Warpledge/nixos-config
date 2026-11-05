#=====================================================================#
# OPENCODE - OPEN SOURCE AI CODING AGENT
#=====================================================================#
{
  config,
  lib,
  machine,
  pkgs,
  user,
  ...
}: let
  parts = user.opencode.plugins;
  flag = on:
    if on
    then "1"
    else "0";
  #--- The plugin's parts read their switch from the file, so one turned off draws
  #--- nothing; the server part reads the sign-in either way
  plugin = pkgs.runCommandLocal "opencode-usage-bar" {} ''
    cp -r ${./opencode-usage-bar} $out
    chmod -R u+w $out
    substituteInPlace $out/tui.tsx --replace-fail __TUI__ ${flag parts.usageBar}
    substituteInPlace $out/server.ts \
      --replace-fail __FLAKE_PATH__ ${lib.escapeShellArg machine.flakePath} \
      --replace-fail __REBUILD_BADGE__ ${flag parts.rebuildBadge}
    substituteInPlace $out/gui-experimental.cjs \
      --replace-fail __DESKTOP_BAR__ ${flag parts.desktopBar} \
      --replace-fail __REBUILD_BADGE__ ${flag parts.rebuildBadge}
  '';
in {
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
      #--- Leaves opencode.json and cli.json writable, so TUI changes stick; the
      #--- blocks below still apply, through home-manager*.json and OPENCODE_*
      mutableSettings = true;
      settings.share = "disabled"; # No /share uploads to opencode.ai
      #--- nix owns the binary, so a self-update only fights the store
      settings.update = "disable";
      #--- cli.json, which OpenCode 2 reads instead of the ignored tui.json
      #--- Object form keeps the mode the old hand-written cli.json had
      cli.theme = {
        name = "dank"; # written by DMS's matugen (theme/matugen.nix)
        mode = "system";
      };
      #--- OpenCode sounds each event itself, so a DMS popup would add a second
      #--- sound. Sound stays on through cli.json; only the popup is dropped
      cli.attention.notifications = false;
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
        #--- AGENTS.md rules 1 and 6: a rebuild, a push, an amend or sudo is the
        #--- user's own step. These catch the usual spellings; they're no sandbox
        {
          action = "shell";
          resource = "nixm rebuild *";
          effect = "deny";
        }
        {
          action = "shell";
          resource = "nixm boot *";
          effect = "deny";
        }
        {
          action = "shell";
          resource = "nixos-rebuild *";
          effect = "deny";
        }
        {
          action = "shell";
          resource = "git push *";
          effect = "deny";
        }
        {
          action = "shell";
          resource = "git commit --amend *";
          effect = "deny";
        }
        {
          action = "shell";
          resource = "git rebase *";
          effect = "deny";
        }
        {
          action = "shell";
          resource = "sudo *";
          effect = "deny";
        }
        {
          action = "shell";
          resource = "git -C * push *";
          effect = "deny";
        }
        {
          action = "shell";
          resource = "git commit * --amend *";
          effect = "deny";
        }
        {
          action = "shell";
          resource = "nh os *";
          effect = "deny";
        }
        {
          action = "shell";
          resource = "./setup.sh *";
          effect = "deny";
        }
      ];

      #--- Formats each file a write or edit touches; the built-in nixfmt would
      #--- restyle the repo, and it runs before custom entries when it's installed
      settings.formatter = {
        nixfmt.disabled = true;
        alejandra = {
          command = [(lib.getExe pkgs.alejandra) "$FILE"];
          extensions = [".nix"];
        };
      };

      #--- Keeps more exact detail beside the summary, so a compaction doesn't
      #--- cost the todo list and the file quoted a few turns ago
      settings.compaction.keep.tokens = 24000;

      #--- Every rebuild rewrites these, and nothing in the repo reacts to them
      settings.watcher.ignore = [
        "result"
        "result-*"
        ".git/**"
        "**/__pycache__/**"
        "**/.ruff_cache/**"
      ];

      #--- todo backs the AGENTS.md todo rule; background_compaction writes the
      #--- summary before it's due, so a long task doesn't stall to make it
      settings.experimental = {
        todo = true;
        background_compaction = true;
      };

      #--- ~/.claude/agents is not one of OpenCode's agent folders, so these are
      #--- V2 copies of the four Claude Code subagents with the same prompts
      agents = ./opencode-agents;

      #--- Usage bars in the footer, from the Console session /connect created,
      #--- and the desktop app's rebuild badge
      settings.plugins =
        lib.optional (parts.usageBar || parts.desktopBar || parts.rebuildBadge) "${plugin}";

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
