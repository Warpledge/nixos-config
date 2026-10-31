#=====================================================================#
# CLAUDE CODE - ANTHROPIC AI CODING AGENT
#=====================================================================#
{
  config,
  lib,
  pkgs,
  user,
  ...
}: let
  c = user.claude;
  #--- Anthropic's sample mods (Blast Radius, Replay Theater) share one repo
  playground = pkgs.fetchFromGitHub {
    owner = "anthropics";
    repo = "claude-code-playground";
    rev = "569c5283d9a0a7ee7938df85bb32e4f48cbb8c86";
    hash = "sha256-rOT2rtXNPayZQEkd2Gbr+9dxClaloxAOoOlDcZp3VQY=";
  };
  on = lib.filterAttrs (_: v: v);
  #--- Settings keys are camelCase (addApp), Claude Code's names kebab-case (add-app)
  kebab = s:
    lib.concatMapStrings (ch:
      if ch != lib.toLower ch
      then "-${lib.toLower ch}"
      else ch) (lib.stringToCharacters s);

  #--- A skill's or subagent's file with its frontmatter `model:` set; null keeps its own
  setModel = model: file: ''
    awk -v m=${lib.escapeShellArg model} '
      NR == 1 && /^---$/ { print; fm = 1; next }
      fm && /^model:/ { print "model: " m; done = 1; next }
      fm && /^---$/ { if (!done) print "model: " m; fm = 0 }
      { print }' ${file}'';
  skill = name: let
    src = ./skills + "/${kebab name}";
    model = c.skillModels.${name};
  in
    if model == null
    then src
    else
      pkgs.runCommand "skill-${kebab name}" {} ''
        cp -r ${src} $out && chmod -R u+w $out
        ${setModel model "${src}/SKILL.md"} > $out/SKILL.md
      '';
  agent = name: let
    src = ./agents + "/${kebab name}.md";
    model = c.agentModels.${name};
  in
    if model == null
    then src
    else pkgs.runCommand "${kebab name}.md" {} "${setModel model src} > $out";

  #--- claude.connectors keys -> the server names Claude Code gives them
  connectorNames = {
    gmail = "Gmail";
    googleCalendar = "Google Calendar";
    googleDrive = "Google Drive";
    claudeDocs = "Claude Docs";
  };

  #--- What the repo sets in ~/.claude/settings.json (mutable-merge.jq keeps
  #--- in-app changes); Omni Settings' reset on Claude Code puts these back
  declared =
    lib.filterAttrs (_: v: v != {} && v != []) {
      enabledPlugins = {
        "cc-plugin-you-should-know@builtin" = c.builtins.youShouldKnow;
        "cc-plugin-agents-md@builtin" = c.builtins.agentsMd;
      };
      pluginConfigs."cc-plugin-agents-md@builtin".options.instructionFiles = c.builtins.agentsMdFiles;
      skillOverrides =
        lib.mapAttrs' (n: v: lib.nameValuePair (kebab n) v) (lib.filterAttrs (_: v: v != "on") c.skills)
        // lib.mapAttrs' (n: _: lib.nameValuePair (kebab n) "off") (lib.filterAttrs (_: v: !v) c.accountSkills);
      deniedMcpServers =
        lib.mapAttrsToList (n: _: {serverName = "claude.ai ${connectorNames.${n}}";})
        (lib.filterAttrs (_: v: !v) c.connectors);
    }
    // lib.optionalAttrs (c.model != null) {inherit (c) model;}
    // lib.optionalAttrs (c.effort != null) {effortLevel = c.effort;}
    // lib.optionalAttrs (c.outputStyle != null) {inherit (c) outputStyle;}
    // lib.optionalAttrs c.statusLine {
      statusLine = {
        type = "command";
        command = "${pkgs.writeShellScript "claude-statusline" ''
          ${lib.getExe pkgs.jq} -r '"Context \(.context_window.used_percentage // 0 | floor)%"'
        ''}";
      };
    };
in {
  config = lib.mkIf c.enable {
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
      in
        #--- claude.plugins.<name>, each a folder in the official repo
        lib.mapAttrs' (n: _: lib.nameValuePair (kebab n) "${official}/plugins/${kebab n}")
        (on c.plugins);

      #--- Repo-local skills and subagents (synced to every host through this module),
      #--- one per name in claude.skills and claude.agents. A skill's visibility
      #--- goes through skillOverrides; an agent set off is left out.
      skills = lib.mapAttrs' (n: _: lib.nameValuePair (kebab n) (skill n)) c.skills;
      agents =
        lib.mapAttrs' (n: _: lib.nameValuePair (kebab n) (agent n))
        (lib.filterAttrs (_: v: v == "on") c.agents);

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
    #--- inotify-tools, pandoc, poppler-utils: File Tree's live updates and previews
    home.packages =
      [pkgs.gitleaks pkgs.python3 pkgs.ruff]
      ++ lib.optionals c.mods.fileTree [pkgs.inotify-tools pkgs.pandoc pkgs.poppler-utils];

    #--- Turn off Claude-drafted feedback (the SendFeedback tool)
    home.sessionVariables.CLAUDE_CODE_SEND_FEEDBACK = "0";

    #--------------------------------------------------------------------#
    #-- Mods and Settings
    #--------------------------------------------------------------------#
    #--- Mods, each behind claude.mods.<name>. Linked whole, not through
    #--- programs.claude-code.plugins: its per-file links fail the hooks path check
    home.file.".claude/skills/ribbon" = lib.mkIf c.mods.ribbon {
      source = pkgs.fetchFromGitHub {
        owner = "robonuggets";
        repo = "ribbon";
        rev = "eecb8f9e384e8ae0ebbafb85f5c6490e8d561f72";
        hash = "sha256-uSdT7j5ogCkuaIl7JYl8DQRXONEQGL8424cpie+KTK8=";
      };
    };
    #--- The patch adds the matugen skin and drops the daily update check
    home.file.".claude/skills/skins" = lib.mkIf c.mods.skins {
      source = pkgs.applyPatches {
        name = "claude-skins";
        src = pkgs.fetchFromGitHub {
          owner = "hellosverre";
          repo = "claude-skins";
          rev = "985ad63fdb3483bbb98f61cf57955cac3f56a449";
          hash = "sha256-xxwF6PSg8xPPXTs3J4DGpiq2N5k2CWBkK/32OnuYhHo=";
        };
        patches = [./mods/skins-matugen.patch];
      };
    };
    matugen.templates = lib.mkIf c.mods.skins {
      claude-skins = {
        input = ../../../theme/matugen/claude-skins.json;
        output = "${config.xdg.configHome}/claude-skins/matugen.json";
      };
    };
    home.file.".claude/skills/filetree" = lib.mkIf c.mods.fileTree {
      source = pkgs.fetchFromGitHub {
        owner = "data-goblin";
        repo = "claude-code-filetree";
        rev = "6bc23f6d824242bea16e53e097051bfa8bcd34a2";
        hash = "sha256-HXNdr4oCJ9kWEdeDHxUDZm+h1pihEk7anbaKUZzzXj8=";
      };
    };
    home.file.".claude/skills/savvy-progress" = lib.mkIf c.mods.savvyProgress {
      source = "${pkgs.fetchFromGitHub {
        owner = "JohnnyVizz";
        repo = "claude-kit";
        rev = "c871c153ead54ad9547cc717d0f3e5a676c73986";
        hash = "sha256-JbCloQU/u0hm9QtUVCQwOFBy0NDbtXMYO9yNPhPMgBw=";
      }}/plugins/savvy-progress";
    };
    home.file.".claude/skills/blast-radius" = lib.mkIf c.mods.blastRadius {
      source = "${playground}/claude-code/mods/blast-radius";
    };
    home.file.".claude/skills/replay-theater" = lib.mkIf c.mods.replayTheater {
      source = "${playground}/claude-code/mods/replay-theater";
    };

    #--- Merges `declared` into settings.json the way zed.nix does, so the rest
    #--- of the file and in-app changes stay
    home.activation.claudeSettings = lib.hm.dag.entryAfter ["writeBoundary"] (let
      jq = lib.getExe pkgs.jq;
    in ''
      dir="$HOME/.claude"
      declarative_file="$dir/declarative-settings.json"
      settings_file="$dir/settings.json"
      new_file=${pkgs.writeText "claude-declarative-settings.json" (builtins.toJSON declared)}

      if [[ -v DRY_RUN ]]; then
        echo "Would merge $new_file into $settings_file"
      else
        mkdir -p "$dir"
        if ! ${jq} -e . "$settings_file" > /dev/null 2>&1; then
          cp --no-preserve=mode "$new_file" "$settings_file"
        else
          ${jq} -e . "$declarative_file" > /dev/null 2>&1 \
            || echo '{}' > "$declarative_file"
          merged="$(${jq} --slurpfile old "$declarative_file" \
            --slurpfile new "$new_file" --argjson locked '[]' \
            -f ${../../../../lib/mutable-merge.jq} "$settings_file")"
          printf '%s\n' "$merged" > "$settings_file"
        fi
        # Also what Omni Settings' Claude Code reset puts back into settings.json
        cp --no-preserve=mode "$new_file" "$declarative_file"
      fi
    '');
  };
}
