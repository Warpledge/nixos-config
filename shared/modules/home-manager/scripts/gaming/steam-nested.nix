#=====================================================================#
# STEAM-NESTED - STEAM CLIENT IN A NESTED LABWC COMPOSITOR
#=====================================================================#
#- Steam client build 1788400362 (2026-09-03) dismisses its own menus
#- and context menus instantly under niri + xwayland-satellite. Running
#- the client inside a nested stacking WM restores normal X11 focus
#- semantics and the menus work again.
#-
#- labwc, not gamescope: gamescope exports GAMESCOPE_WAYLAND_DISPLAY,
#- which makes Steam start in Big Picture and hang on "Switch to Desktop".
{pkgs, ...}: let
  steam-nested =
    pkgs.writeShellScriptBin "steam-nested"
    # bash
    ''
      if pgrep -x steam > /dev/null 2>&1; then
        echo "[steam-nested] Steam is already running; a second launch would only"
        echo "[steam-nested] raise the existing window. Run 'steam -shutdown' first."
        exit 1
      fi

      exec ${pkgs.labwc}/bin/labwc -t "Steam" -S "steam $*"
    '';
in {
  home.packages = [steam-nested];

  xdg.desktopEntries.steam-nested = {
    name = "Steam (Nested)";
    comment = "Steam client in a nested labwc compositor (working menus)";
    exec = "steam-nested";
    icon = "steam";
    terminal = false;
    categories = ["Game"];
  };
}
