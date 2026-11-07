#=====================================================================#
# KYLERJ'S HOME (FLOW Z13)
#=====================================================================#
#- Home-manager modules for kylerj on this machine only, imported from
#- ../default.nix. Apps the user settings have no switch for, Dolphin's
#- terminal, and the niri keybinds carried over from KDE Plasma.
{...}: {
  #--------------------------------------------------------------------#
  #-- Imports
  #--------------------------------------------------------------------#
  imports = [
    ./apps.nix
    ./binds.nix
    ./config-reminder.nix
    ./dolphin.nix
    ./ghostty.nix
    ./godot-mcp.nix
    ./local-ai.nix
    ./on-screen-input
    ./unreal-engine.nix
    ./vscodium.nix
  ];
}
