#=====================================================================#
# CLAUDE CODE - ANTHROPIC AI CODING AGENT
#=====================================================================#
{
  lib,
  pkgs,
  hostConfig,
  ...
}: {
  config = lib.mkIf hostConfig.claude.enable {
    #--------------------------------------------------------------------#
    #-- Package Installation
    #--------------------------------------------------------------------#
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
        claude-security = "${official}/plugins/claude-security";
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
        hyprland-verify = ./skills/hyprland-verify;
        moku-bump = ./skills/moku-bump;
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
    #--- python3: the claude-security plugin's scripts
    home.packages = [pkgs.gitleaks pkgs.python3];
  };
}
