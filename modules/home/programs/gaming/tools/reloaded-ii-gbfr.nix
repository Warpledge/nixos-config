#=====================================================================#
# RELOADED-II (GRANBLUE FANTASY RELINK) LAUNCHER
#=====================================================================#
#- Opens the Reloaded-II mod loader in GBFR's Proton prefix (appid 881020)
#- through protontricks-launch, since it's a Windows .exe. It handles the
#- code mods RelinkModOrganizer can't (a .dll, no data tree), which load at
#- game launch through the winmm ASI loader; this only opens its config.
#- Its installer puts it in ~/Desktop/Reloaded-II - Granblue Fantasy Relink/.
{pkgs, ...}: let
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
