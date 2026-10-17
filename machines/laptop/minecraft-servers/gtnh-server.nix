#=====================================================================#
# GTNH-SERVER - GREGTECH NEW HORIZONS SERVER LAUNCHER
#=====================================================================#
#- Manages the GTNH server via a persistent tmux session.
#- Running `gtnh` attaches to an existing session or starts a new one.
#- The server auto-restarts on crash with a 12 second countdown.
#- Clean shutdown (exit 0) stops the restart loop.
#-
#- Commands:
#-   gtnh        — Start server or attach to running session
#-   gtnh log    — Tail the latest server log
#-   gtnh stop   — Send /stop to the running server
#-   gtnh status — Show whether the server session is running
#-
#- Server path: ~/Documents/Minecraft_Servers/GT_New_Horizons_2.8.4_Server_Modified
#- Session name: gtnh
{pkgs, ...}: let
  serverDir = "$HOME/Documents/Minecraft_Servers/GT_New_Horizons_2.8.4_Server_Modified";
  sessionName = "gtnh";

  startScript = pkgs.writeShellScript "gtnh-start" ''
      while true; do
          java \
              -Xms10G \
              -Xmx12G \
              -XX:+UseG1GC \
              -XX:+ParallelRefProcEnabled \
              -XX:MaxGCPauseMillis=200 \
              -XX:+UnlockExperimentalVMOptions \
              -XX:+DisableExplicitGC \
              -XX:G1NewSizePercent=30 \
              -XX:G1MaxNewSizePercent=40 \
              -XX:G1HeapRegionSize=16M \
              -XX:G1ReservePercent=20 \
              -XX:G1HeapWastePercent=5 \
              -XX:G1MixedGCCountTarget=4 \
              -XX:InitiatingHeapOccupancyPercent=15 \
              -XX:G1MixedGCLiveThresholdPercent=90 \
              -XX:G1RSetUpdatingPauseTimePercent=5 \
              -XX:SurvivorRatio=32 \
              -XX:+AlwaysPreTouch \
              -XX:+PerfDisableSharedMem \
              -XX:+UseTransparentHugePages \
              -Dfml.readTimeout=180 \
              -Dfml.loginTimeout=60 \
              @java9args.txt \
              -jar lwjgl3ify-forgePatches.jar nogui

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

  gtnh-server =
    pkgs.writeShellScriptBin "gtnh"
    # bash
    ''
      SESSION="${sessionName}"
      SERVER_DIR="${serverDir}"

      _session_running() {
        ${pkgs.tmux}/bin/tmux has-session -t "$SESSION" 2>/dev/null
      }

      _log() {
        local logfile="$SERVER_DIR/logs/fml-server-latest.log"
        if [[ -f "$logfile" ]]; then
          tail -f "$logfile"
        else
          echo "[gtnh] No log file found at $SERVER_DIR/logs/"
        fi
      }

      _stop() {
        if _session_running; then
          echo "[gtnh] Sending /stop to session '$SESSION'..."
          ${pkgs.tmux}/bin/tmux send-keys -t "$SESSION" "/stop" Enter
        else
          echo "[gtnh] No running session '$SESSION' found."
          exit 1
        fi
      }

      _status() {
        if _session_running; then
          echo "[gtnh] Session '$SESSION' is running."
        else
          echo "[gtnh] Session '$SESSION' is not running."
        fi
      }

      case "''${1:-}" in
        log) _log ;;
        stop) _stop ;;
        status) _status ;;
        "")
          if _session_running; then
            echo "[gtnh] Session '$SESSION' already running. Attaching..."
            ${pkgs.tmux}/bin/tmux attach-session -t "$SESSION"
          else
            echo "[gtnh] Starting server in tmux session '$SESSION'..."
            ${pkgs.tmux}/bin/tmux new-session -d -s "$SESSION" -c "$SERVER_DIR" \
              "${startScript}"
            echo "[gtnh] Server started. Attaching..."
            ${pkgs.tmux}/bin/tmux attach-session -t "$SESSION"
          fi
          ;;
        *)
          echo "Usage: gtnh [log|stop|status]"
          exit 1
          ;;
      esac
    '';
in {
  home.packages = [gtnh-server];
}
