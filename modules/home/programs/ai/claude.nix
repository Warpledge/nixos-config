#=====================================================================#
# CLAUDE CODE - ANTHROPIC AI CODING AGENT
#=====================================================================#
{
  lib,
  pkgs,
  user,
  ...
}: let
  c = user.claude;
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
    // lib.optionalAttrs (c.outputStyle != null) {inherit (c) outputStyle;};
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
    home.packages = [pkgs.gitleaks pkgs.python3 pkgs.ruff];

    #--- Turn off Claude-drafted feedback (the SendFeedback tool)
    home.sessionVariables.CLAUDE_CODE_SEND_FEEDBACK = "0";

    #--------------------------------------------------------------------#
    #-- Mods and Settings
    #--------------------------------------------------------------------#
    #--- Repo mods, each behind claude.mods.<name>. Linked whole, not through
    #--- programs.claude-code.plugins: its per-file links fail the hooks path check
    home.file.".claude/skills/band" = lib.mkIf c.mods.band {source = ./mods/band;};

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
