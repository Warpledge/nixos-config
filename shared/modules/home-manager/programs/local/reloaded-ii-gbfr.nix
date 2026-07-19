#=====================================================================#
# RELOADED-II (GRANBLUE FANTASY RELINK) LAUNCHER
#=====================================================================#
#- Launcher entry for the Reloaded-II mod loader installed into GBFR's
#- Proton prefix (appid 881020). Unlike RelinkModOrganizer (a native
#- Linux binary), Reloaded-II is a Windows .exe, so it runs through Wine
#- via protontricks-launch against the game's own prefix.
#-
#- Reloaded-II covers the code/hook mods RMO can't: memory-hook mods that
#- ship a .dll and no GBFR/data tree (e.g. Mastery Point Multiplier, Smart
#- Synthesis). Those inject at game launch via the deployed winmm ASI
#- loader; this entry only opens the config GUI to add/enable/toggle mods.
#-
#- The bundle lives on the Linux side at
#- ~/Desktop/Reloaded-II - Granblue Fantasy Relink/ (created by the
#- Setup-Linux.exe installer, kept out of the repo like other local apps).
{
  pkgs,
  ...
}: let
  #-- Windows exe launched inside the GBFR Proton prefix
  appId = "881020";
  exePath = "$HOME/Desktop/Reloaded-II - Granblue Fantasy Relink/Reloaded-II.exe";

  #-- Wrapper: run the exe in the game's prefix via protontricks-launch
  reloaded-ii-gbfr =
    pkgs.writeShellScriptBin "reloaded-ii-gbfr"
    ''
      # Niri launcher-spawned processes don't inherit DISPLAY, and Wine's
      # GUI needs an X server (XWayland is on :0).
      export DISPLAY="''${DISPLAY:-:0}"
      exec protontricks-launch --appid ${appId} "${exePath}" "$@"
    '';
in {
  #--------------------------------------------------------------------#
  #-- Wrapper Package
  #--------------------------------------------------------------------#
  home.packages = [reloaded-ii-gbfr];

  #--------------------------------------------------------------------#
  #-- Desktop Entry
  #--------------------------------------------------------------------#
  xdg.desktopEntries.reloaded-ii-gbfr = {
    name = "Reloaded-II (Granblue Relink)";
    comment = "Reloaded-II mod loader for Granblue Fantasy: Relink";
    exec = "reloaded-ii-gbfr";
    icon = "applications-games";
    terminal = false;
    categories = ["Game" "Utility"];
  };
}
