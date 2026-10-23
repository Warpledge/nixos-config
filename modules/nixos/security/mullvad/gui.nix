#=====================================================================#
# MULLVAD VPN GUI SETTINGS (HOME MANAGER)
#=====================================================================#
#- The tray app's own settings (~/.config/Mullvad VPN/gui_settings.json),
#- separate from the daemon's; the daemon's auto_connect (daemon.nix) raises
#- the tunnel at boot. The app rewrites the file on exit, so it's patched
#- with jq at activation: close the app before rebuilding.
#-
#- It starts from a systemd user unit, not an autostart entry: it registers
#- its tray icon once, so starting before the tray leaves it with no icon.
{
  lib,
  machine,
  ...
}: {
  #--- Every user on the machine gets the tray app
  home-manager.users =
    lib.mapAttrs (_: _: {
      lib,
      pkgs,
      ...
    }: let
      #--- dms.service being active is not the same as the bus name being
      #--- claimed, so poll for the name itself.
      waitForTray = pkgs.writeShellApplication {
        name = "wait-for-tray";
        runtimeInputs = [pkgs.systemd pkgs.coreutils pkgs.gnugrep];
        text = ''
          i=0
          while [ "$i" -lt 60 ]; do
            if busctl --user call org.freedesktop.DBus /org/freedesktop/DBus \
                 org.freedesktop.DBus NameHasOwner s org.kde.StatusNotifierWatcher \
                 2>/dev/null | grep -q 'b true'; then
              exit 0
            fi
            i=$((i + 1))
            sleep 0.5
          done
          echo "wait-for-tray: no StatusNotifierWatcher after 30s, starting anyway" >&2
        '';
      };
    in {
      #--------------------------------------------------------------------#
      #-- Launch App On Start-up
      #--------------------------------------------------------------------#
      systemd.user.services.mullvad-vpn-gui = {
        Unit = {
          Description = "Mullvad VPN tray app";
          After = ["graphical-session.target" "dms.service"];
          PartOf = ["graphical-session.target"];
        };
        Service = {
          Type = "simple";
          ExecStartPre = lib.getExe waitForTray;
          ExecStart = "${pkgs.mullvad-vpn}/bin/mullvad-vpn";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = ["graphical-session.target"];
      };

      #--------------------------------------------------------------------#
      #-- Auto-connect And Start Minimized
      #--------------------------------------------------------------------#
      home.activation.mullvadGuiSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
        gui="$HOME/.config/Mullvad VPN/gui_settings.json"

        if ${pkgs.procps}/bin/pgrep -f 'mullvad-vpn/resources/app[.]asar' >/dev/null 2>&1; then
          echo "mullvad-gui: app is running and rewrites gui_settings.json on exit."
          echo "mullvad-gui: close it and rebuild if autoConnect does not stick."
        fi

        $DRY_RUN_CMD mkdir -p "$(dirname "$gui")"

        if [ -s "$gui" ] && ${pkgs.jq}/bin/jq -e . "$gui" >/dev/null 2>&1; then
          tmp=$(mktemp)
          ${pkgs.jq}/bin/jq '.autoConnect = true | .startMinimized = true' "$gui" > "$tmp" \
            && $DRY_RUN_CMD mv "$tmp" "$gui" \
            || rm -f "$tmp"
        else
          # absent or corrupt: the app fills in the rest of its defaults
          $DRY_RUN_CMD cp ${pkgs.writeText "gui_settings.json" ''{"autoConnect":true,"startMinimized":true}''} "$gui"
          $DRY_RUN_CMD chmod 600 "$gui"
        fi
      '';
    })
    machine.users;
}
