#=====================================================================#
# TFG-SERVER - TERRAFIRMAGREG MODERN SERVER LAUNCHER
#=====================================================================#
#- Manages the TerraFirmaGreg Modern server via a persistent tmux session.
#- Running `tfg` attaches to an existing session or starts a new one.
#- The server auto-restarts on crash with a 12 second countdown.
#- Clean shutdown (exit 0) stops the restart loop.
#-
#- Commands:
#-   tfg        — Start server or attach to running session
#-   tfg log    — Tail the latest server log
#-   tfg stop   — Send /stop to the running server
#-   tfg status — Show whether the server session is running
#-
#- Server path: ~/Documents/Minecraft_Servers/TerraFirmaGreg-Modern-0.12.5
#- Session name: terrafirmagreg-modern
#- Forge: 1.20.1-47.4.13
#-
#- One-time setup (run before first launch):
#-   cd ~/Documents/Minecraft_Servers/TerraFirmaGreg-Modern-0.12.5
#-   java -jar minecraft_server.jar nogui   # installs Forge, then exit
#-   echo "eula=true" > eula.txt
{pkgs, ...}: let
  serverDir = "$HOME/Documents/Minecraft_Servers/TerraFirmaGreg-Modern-0.12.5";
  sessionName = "terrafirmagreg-modern";

  startScript =
    pkgs.writeShellScript "tfg-start"
    ''
      cd "$1"

      while true; do
          ${pkgs.jdk21}/bin/java \
              -Xms12288M \
              -Xmx12288M \
              --add-modules=jdk.incubator.vector \
              -XX:+UseG1GC \
              -XX:+ParallelRefProcEnabled \
              -XX:MaxGCPauseMillis=200 \
              -XX:+UnlockExperimentalVMOptions \
              -XX:+DisableExplicitGC \
              -XX:+AlwaysPreTouch \
              -XX:G1NewSizePercent=40 \
              -XX:G1MaxNewSizePercent=50 \
              -XX:G1HeapRegionSize=16M \
              -XX:G1ReservePercent=15 \
              -XX:G1HeapWastePercent=5 \
              -XX:G1MixedGCCountTarget=4 \
              -XX:InitiatingHeapOccupancyPercent=15 \
              -XX:G1MixedGCLiveThresholdPercent=90 \
              -XX:G1RSetUpdatingPauseTimePercent=5 \
              -XX:SurvivorRatio=32 \
              -XX:+PerfDisableSharedMem \
              -XX:MaxTenuringThreshold=1 \
              -Dusing.aikars.flags=https://mcflags.emc.gs \
              -Daikars.new.flags=true \
              @libraries/net/minecraftforge/forge/1.20.1-47.4.13/unix_args.txt \
              nogui

          EXIT_CODE=$?
          echo ""
          echo "Server stopped with exit code: $EXIT_CODE"
          echo "$(date): Server stopped (exit code $EXIT_CODE)" >> server_crashes.log

          if [ $EXIT_CODE -eq 0 ]; then
              echo "Clean shutdown detected. Not restarting."
              break
          fi

          echo "Crash detected! Press Ctrl+C to stop, otherwise restarting in:"
          for i in 12 11 10 9 8 7 6 5 4 3 2 1; do
              echo "$i..."
              sleep 1
          done
          echo "Restarting now!"
      done
    '';

  tfg-server =
    pkgs.writeShellScriptBin "tfg"
    # bash
    ''
      SESSION="${sessionName}"
      SERVER_DIR="${serverDir}"

      _session_running() {
        ${pkgs.tmux}/bin/tmux has-session -t "$SESSION" 2>/dev/null
      }

      _log() {
        local logfile="$SERVER_DIR/logs/latest.log"
        if [[ -f "$logfile" ]]; then
          tail -f "$logfile"
        else
          echo "[tfg] No log file found at $SERVER_DIR/logs/"
        fi
      }

      _stop() {
        if _session_running; then
          echo "[tfg] Sending /stop to session '$SESSION'..."
          ${pkgs.tmux}/bin/tmux send-keys -t "$SESSION" "/stop" Enter
        else
          echo "[tfg] No running session '$SESSION' found."
          exit 1
        fi
      }

      _status() {
        if _session_running; then
          echo "[tfg] Session '$SESSION' is running."
        else
          echo "[tfg] Session '$SESSION' is not running."
        fi
      }

      case "''${1:-}" in
        log) _log ;;
        stop) _stop ;;
        status) _status ;;
        "")
          if _session_running; then
            echo "[tfg] Session '$SESSION' already running. Attaching..."
            ${pkgs.tmux}/bin/tmux attach-session -t "$SESSION"
          else
            echo "[tfg] Starting server in tmux session '$SESSION'..."
            ${pkgs.tmux}/bin/tmux new-session -d -s "$SESSION" -c "$SERVER_DIR" \
              "${startScript} $SERVER_DIR"
            echo "[tfg] Server started. Attaching..."
            ${pkgs.tmux}/bin/tmux attach-session -t "$SESSION"
          fi
          ;;
        *)
          echo "Usage: tfg [log|stop|status]"
          exit 1
          ;;
      esac
    '';
in {
  home.packages = [tfg-server];
}
