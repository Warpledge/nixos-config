#=====================================================================#
# KYLERJ'S HOME (FLOW Z13)
#=====================================================================#
#- Home-manager modules for kylerj on this machine only, imported from
#- ../default.nix. Apps the user settings have no switch for, and the niri
#- keybinds carried over from KDE Plasma.
{...}: {
  #--------------------------------------------------------------------#
  #-- Imports
  #--------------------------------------------------------------------#
  imports = [
    ./apps.nix
    ./binds.nix
    ./config-reminder.nix
    ./godot-mcp.nix
    ./local-ai.nix
    ./unreal-engine.nix
  ];
}
