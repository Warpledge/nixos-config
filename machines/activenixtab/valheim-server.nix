#=====================================================================#
# VALHEIM DEDICATED SERVER
#=====================================================================#
#- Ky's Gale profile ("Doobie Canoe With Friends") as a modded server,
#- hidden from the public list; friends join by IP. The "Valheim Server"
#- desktop entry starts it and shows the console; closing that window
#- stops it. The world is seeded from Steam Cloud once, then the server
#- owns it in worlds/.
{
  config,
  pkgs,
  ...
}: let
  user = "kylerj";
  base = "/home/${user}/.local/share/valheim-server";
  steamDs = "/home/${user}/.local/share/Steam/steamapps/common/Valheim dedicated server";
  galeProfile = "/home/${user}/.local/share/com.kesomannen.gale/valheim/profiles/Doobie Canoe With Friends";
  cloudWorlds = "/home/${user}/.local/share/Steam/userdata/11321497/892970/remote/worlds";
  world = "NewAsgard2026";
  log = "${base}/logs/server.log";

  #--- Stage Steam's install and the mod profile beside a writable save dir
  prepare = pkgs.writeShellApplication {
    name = "valheim-server-prepare";
    runtimeInputs = [pkgs.coreutils pkgs.rsync];
    text = ''
      mkdir -p "${base}/game/BepInEx" "${base}/worlds" "${base}/logs"

      #--- Steam's files, leaving the ones the mod profile supplies
      rsync -a --delete --exclude=/BepInEx --exclude=/doorstop_libs \
        --exclude=/doorstop_config.ini "${steamDs}/" "${base}/game/"

      #--- The mod set follows Ky's Gale profile, so client and server match
      rsync -a --delete "${galeProfile}/BepInEx/plugins/" "${base}/game/BepInEx/plugins/"
      rsync -a --delete "${galeProfile}/BepInEx/patchers/" "${base}/game/BepInEx/patchers/"
      rsync -a "${galeProfile}/BepInEx/core/" "${base}/game/BepInEx/core/"
      #--- Only new mods get a .cfg; the server's own configs stay as they are
      rsync -a --ignore-existing "${galeProfile}/BepInEx/config/" "${base}/game/BepInEx/config/"
      rsync -a "${galeProfile}/doorstop_libs/" "${base}/game/doorstop_libs/"
      install -m 644 "${galeProfile}/doorstop_config.ini" "${base}/game/doorstop_config.ini"

      #--- Seed the world once; resyncing would overwrite progress
      if [ ! -d "${base}/worlds/worlds_local/${world}" ]; then
        mkdir -p "${base}/worlds/worlds_local"
        rsync -a "${cloudWorlds}/${world}" "${base}/worlds/worlds_local/"
      fi
    '';
  };

  #--- Password comes from ${base}/env, not this public repo; -logfile - puts
  #--- Unity's console on stdout, which systemd appends to the log file
  launch = pkgs.writeShellScript "valheim-server-launch" ''
    set -eu
    export DOORSTOP_ENABLED=1
    export DOORSTOP_TARGET_ASSEMBLY=./BepInEx/core/BepInEx.Preloader.dll
    export LD_LIBRARY_PATH=${base}/game/doorstop_libs:${base}/game/linux64
    export LD_PRELOAD=libdoorstop_x64.so
    exec ./valheim_server.x86_64 \
      -name "The Doobie Canoe" \
      -port 2456 \
      -world ${world} \
      -password "$VALHEIM_PASSWORD" \
      -savedir ${base}/worlds \
      -public 0 \
      -logfile -
  '';

  #--- The desktop entry's window: start the server, follow the console,
  #--- stop it again when the window goes away
  console = pkgs.writeShellApplication {
    name = "valheim-console";
    runtimeInputs = [pkgs.coreutils pkgs.systemd];
    text = ''
      started=0
      stop() {
        if [ "$started" = 1 ]; then
          systemctl --no-block stop valheim-server.service
        fi
      }
      trap stop EXIT
      trap 'exit 0' HUP INT TERM
      if systemctl is-active --quiet valheim-server.service; then
        echo "The Doobie Canoe is already running; this window only follows it."
      else
        started=1
        if systemctl start valheim-server.service; then
          echo
          echo "The Doobie Canoe is starting. Friends add this machine's IP and 2456."
          echo "Close this window to stop the server."
        else
          echo "The server failed to start; its log follows."
        fi
        echo
      fi
      tail -n 100 -F ${log}
    '';
  };

  #--- Packs the mods, world and a start script for a non-Nix machine
  export = pkgs.writeShellApplication {
    name = "valheim-export";
    runtimeInputs = [pkgs.coreutils pkgs.gnutar pkgs.gzip pkgs.systemd];
    text = ''
            if systemctl is-active --quiet valheim-server.service; then
              echo "The server is running. Close its console window first, so the world is not mid-save."
              printf '\nPress Enter to close.\n'
              read -r _
              exit 1
            fi
            out="/home/${user}/valheim-server-$(date +%Y%m%d).tar.gz"
            stage=$(mktemp -d)
            trap 'rm -rf "$stage"' EXIT
            bundle="$stage/valheim-server"
            mkdir -p "$bundle"
            cp -a ${base}/game/BepInEx "$bundle/"
            cp -a ${base}/game/doorstop_libs "$bundle/"
            cp -a ${base}/game/doorstop_config.ini "$bundle/"
            cp -a ${base}/worlds "$bundle/"
            sed 's/^VALHEIM_PASSWORD=//' ${base}/env > "$bundle/password"
            chmod 600 "$bundle/password"

            cat > "$bundle/start.sh" <<'EOF'
      #!/bin/sh
      set -eu
      here=$(cd "$(dirname "$0")" && pwd)
      if [ -n "$VALHEIM_GAME" ]; then
        game=$VALHEIM_GAME
      else
        game="$HOME/.local/share/Steam/steamapps/common/Valheim dedicated server"
      fi
      if [ ! -x "$game/valheim_server.x86_64" ]; then
        echo "No Valheim dedicated server in: $game"
        echo "Install it in Steam (Library, filter Tools), or set VALHEIM_GAME."
        exit 1
      fi
      if command -v rsync >/dev/null 2>&1; then
        rsync -a --delete "$here/BepInEx/" "$game/BepInEx/"
        rsync -a "$here/doorstop_libs/" "$game/doorstop_libs/"
      else
        cp -a "$here/BepInEx" "$here/doorstop_libs" "$game/"
      fi
      cp -f "$here/doorstop_config.ini" "$game/doorstop_config.ini"
      cd "$game"
      export DOORSTOP_ENABLED=1
      export DOORSTOP_TARGET_ASSEMBLY=./BepInEx/core/BepInEx.Preloader.dll
      export LD_LIBRARY_PATH="$game/doorstop_libs:$game/linux64"
      export LD_PRELOAD=libdoorstop_x64.so
      password=$(cat "$here/password")
      exec ./valheim_server.x86_64 -name "The Doobie Canoe" -port 2456 -world ${world} \
        -password "$password" -savedir "$here/worlds" -public 0 -logfile -
      EOF
            chmod +x "$bundle/start.sh"

            cat > "$bundle/README.txt" <<'EOF'
      The Doobie Canoe - Valheim dedicated server

      Requirements
        Steam, with "Valheim Dedicated Server" installed (Library, filter Tools).
        The game files are not in this archive; they come from Steam.

      Run it
        tar xzf valheim-server-YYYYMMDD.tar.gz -C ~
        ~/valheim-server/start.sh

        If Steam keeps the server elsewhere:
        VALHEIM_GAME="/path/to/Valheim dedicated server" ~/valheim-server/start.sh

      What start.sh does
        Copies BepInEx and the doorstop files into the Steam install, then runs
        valheim_server.x86_64 with -savedir pointing at worlds/ in this folder.

      Network
        Open UDP 2456-2458 in the machine's firewall.
        Forward UDP 2456-2458 on the router to this machine.
        Friends add the public IP and :2456 in Valheim's server list; the server
        stays off the public list. The password is in the file "password".
        With CGNAT (WAN IP 100.64.x.x) forwarding cannot work.

      The world
        worlds/worlds_local/NewAsgard2026. Copy worlds/ while the server is
        stopped to back it up. Admins are SteamID64s in worlds/adminlist.txt.

      Mods
        Players need the same Gale profile, "Doobie Canoe With Friends".
        To update, replace BepInEx/ in this folder with a newer export.
      EOF

            tar -C "$stage" -czf "$out" valheim-server
            echo
            echo "Wrote $out"
            ls -lh "$out"
            echo
            echo "Copy it across, then: tar xzf <file> -C ~ && ~/valheim-server/start.sh"
            printf '\nPress Enter to close.\n'
            read -r _
    '';
  };
in {
  #--- Forward the same range on the router to this machine
  networking.firewall.allowedUDPPorts = [2456 2457 2458];

  #--- The console window starts and stops this one unit without a password prompt
  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") == "valheim-server.service" &&
          subject.user == "${user}") {
        return polkit.Result.YES;
      }
    });
  '';

  #--- systemd opens the log before ExecStartPre runs, so these must exist first
  systemd.tmpfiles.rules = [
    "d ${base}/logs 0755 ${user} users -"
    "d ${base}/game 0755 ${user} users -"
    "d ${base}/worlds 0755 ${user} users -"
  ];

  systemd.services.valheim-server = {
    description = "Valheim dedicated server (modded: Doobie Canoe With Friends)";
    wants = ["network-online.target" "valheim-server-inhibit.service"];
    after = ["network-online.target" "valheim-server-inhibit.service"];
    #--- A rebuild leaves a running server alone; new scripts apply the next
    #--- time the console window starts it
    restartIfChanged = false;
    serviceConfig = {
      User = user;
      WorkingDirectory = "${base}/game";
      EnvironmentFile = "-${base}/env";
      ExecStartPre = "${prepare}/bin/valheim-server-prepare";
      ExecStart = "${launch}";
      StandardOutput = "append:${log}";
      StandardError = "append:${log}";
      Restart = "always";
      RestartSec = 15;
      TimeoutStopSec = 180;
    };
  };

  #--- Blocked while the server runs, released when it stops
  systemd.services.valheim-server-inhibit = {
    description = "Hold off idle and lid sleep while the Valheim server runs";
    partOf = ["valheim-server.service"];
    unitConfig.StopWhenUnneeded = true;
    #--- No restart on rebuild, so the sleep lock never blinks
    restartIfChanged = false;
    serviceConfig = {
      Type = "simple";
      ExecStart = "${config.systemd.package}/bin/systemd-inhibit --what=idle:sleep:handle-lid-switch --who=valheim-server --why=ValheimServerRunning --mode=block ${pkgs.coreutils}/bin/sleep infinity";
      Restart = "no";
    };
  };

  home-manager.users.kylerj = {
    home.packages = [console export];
    xdg.desktopEntries = {
      valheim-server = {
        name = "Valheim Server";
        comment = "Start the modded Valheim server and follow its console";
        exec = "ghostty --class=valheim-console -e ${console}/bin/valheim-console";
        icon = "applications-games";
        terminal = false;
        categories = ["Game"];
      };
      valheim-export = {
        name = "Export Valheim Server";
        comment = "Pack the mods and world for another machine";
        exec = "ghostty --class=valheim-export -e ${export}/bin/valheim-export";
        icon = "accessories-archiver";
        terminal = false;
        categories = ["Game"];
      };
    };
  };
}
