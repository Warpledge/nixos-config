#=====================================================================#
# CLAUDE CODE - ANTHROPIC AI CODING AGENT
#=====================================================================#
{
  lib,
  pkgs,
  user,
  ...
}: {
  config = lib.mkIf user.claude.enable {
    #--------------------------------------------------------------------#
    #-- Package Installation
    #--------------------------------------------------------------------#
    #--- An env var, not settings.env: setting programs.claude-code.settings makes
    #--- ~/.claude/settings.json read-only. DISABLE_TELEMETRY would drop feature flags.
    home.sessionVariables.DISABLE_ERROR_REPORTING = "1";

    programs.claude-code = {
      enable = true;
      enableMcpIntegration = true;

      #--- Official marketplace plugins, pinned; installed as plugin dirs,
      #--- not via settings.json
      plugins = let
        official = pkgs.fetchFromGitHub {
          owner = "anthropics";
          repo = "claude-plugins-official";
          rev = "d4226d062928f8d9505dbdeadd10217d23361052";
          hash = "sha256-gdxtwbZnIxc0l1379a9suBLvdUnWoptOsddJySFfxV0=";
        };
      in {
        claude-md-management = "${official}/plugins/claude-md-management";
        skill-creator = "${official}/plugins/skill-creator";
        claude-code-setup = "${official}/plugins/claude-code-setup";
        # Off: lists 9 agents every session and a scan costs heavy usage
        # claude-security = "${official}/plugins/claude-security";
      };

      #--- Repo-local skills and subagents (synced to every host through this module)
      skills = {
        add-app = ./skills/add-app;
        android-debloat-redo = ./skills/android-debloat-redo;
        apparmor-check = ./skills/apparmor-check;
        commit = ./skills/commit;
        disable-package = ./skills/disable-package;
        flake-update = ./skills/flake-update;
        freetube-sync = ./skills/freetube-sync;
        game-troubleshooting = ./skills/game-troubleshooting;
        moku-bump = ./skills/moku-bump;
        pr-review = ./skills/pr-review;
        rpgm-setup = ./skills/rpgm-setup;
        vn-setup = ./skills/vn-setup;
      };
      agents = {
        public-repo-auditor = ./agents/public-repo-auditor.md;
        prose-reviewer = ./agents/prose-reviewer.md;
        build-triager = ./agents/build-triager.md;
        docs-drift-auditor = ./agents/docs-drift-auditor.md;
      };

      #--- Language servers (go into the generated "hm" plugin, not settings.json)
      lspServers = {
        nix = {
          command = lib.getExe pkgs.nixd;
          extensionToLanguage.".nix" = "nix";
        };
        lua = {
          command = lib.getExe pkgs.lua-language-server;
          extensionToLanguage.".lua" = "lua";
        };
        bash = {
          command = lib.getExe pkgs.bash-language-server;
          args = ["start"];
          extensionToLanguage = {
            ".sh" = "shellscript";
            ".bash" = "shellscript";
          };
        };
        markdown = {
          command = lib.getExe pkgs.marksman;
          args = ["server"];
          extensionToLanguage.".md" = "markdown";
        };
      };
    };

    #--- gitleaks: the commit skill's secret scan
    #--- python3: the skill-creator and claude-security plugins' scripts
    #--- ruff: the edit hook's check on Omni Settings' Python
    home.packages = [pkgs.gitleaks pkgs.python3 pkgs.ruff];

    #--- Turn off Claude-drafted feedback (the SendFeedback tool)
    home.sessionVariables.CLAUDE_CODE_SEND_FEEDBACK = "0";
  };
}
