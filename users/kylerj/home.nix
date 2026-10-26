#=====================================================================#
# KYLERJ'S HOME
#=====================================================================#
#- Ky's own home-manager config on every machine, imported by
#- modules/default.nix: global rules and game-dev skills for the agents.
{
  config,
  lib,
  ...
}: let
  #--- claude.ai skills synced to Claude Code that opencode should load too
  syncedSkills = ["tmodloader"];
  syncedLinks = "${config.home.homeDirectory}/.local/share/opencode-synced-skills";
in {
  #--------------------------------------------------------------------#
  #-- Agent Rules and Skills
  #--------------------------------------------------------------------#
  #--- ~/.config/opencode/AGENTS.md, read in every project
  programs.opencode.context = ./agents/opencode-global.md;

  programs.opencode.skills = {
    godot = ./skills/godot;
    tmodloader-workflow = ./skills/tmodloader-workflow;
  };

  programs.claude-code.skills = {
    godot = ./skills/godot;
    tmodloader-workflow = ./skills/tmodloader-workflow;
  };

  #--- The synced folder's name holds an account id, so link each skill to a
  #--- fixed path; opencode ignores the other synced skills (Claude-only tools)
  programs.opencode.settings.skills.paths = [syncedLinks];

  home.activation.linkSyncedSkills = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run mkdir -p ${syncedLinks}
    for skill in ${lib.concatStringsSep " " syncedSkills}; do
      src=$(find ${config.home.homeDirectory}/.claude/skills/synced -mindepth 2 \
        -maxdepth 2 -type d -name "$skill" 2>/dev/null | head -n 1)
      if [ -n "$src" ]; then
        run ln -sfn "$src" ${syncedLinks}/"$skill"
      fi
    done
  '';
}
