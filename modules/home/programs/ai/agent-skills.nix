#=====================================================================#
# AGENT SKILLS - THE REPO'S SKILLS FOR OPENCODE AND ZED
#=====================================================================#
#- Links each skill in ./skills into ~/.agents/skills, the global folder
#- Zed's agent and opencode both read. Claude Code gets the same skills in
#- ~/.claude/skills (claude.nix), which opencode is told to skip (opencode.nix).
{lib, ...}: {
  home.file = lib.mapAttrs' (name: _:
    lib.nameValuePair ".agents/skills/${name}" {source = ./skills + "/${name}";})
  (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./skills));
}
