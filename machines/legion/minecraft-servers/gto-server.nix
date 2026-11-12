#=====================================================================#
# GTO-SERVER - GREGTECH ODYSSEY SERVER LAUNCHER
#=====================================================================#
#- Manages the GregTech Odyssey server via a persistent tmux session.
#- Running `gtoserver` attaches to an existing session or starts a new one.
#- The server auto-restarts on crash with a 12 second countdown.
#- Clean shutdown (exit 0) stops the restart loop.
#-
#- Commands:
#-   gtoserver        — Start server or attach to running session
#-   gtoserver log    — Tail the latest server log
#-   gtoserver stop   — Send /stop to the running server
#-   gtoserver status — Show whether the server session is running
#-
#- Server path: ~/Documents/Minecraft_Servers/GregTech.Odyssey-0.6.0-dev27-server
#- Session name: gregtech-odyssey
#- Forge: 1.20.1-47.4.20
#-
#- The folder, Forge included, is built on the desktop with `gto server`
#- (docs/personal/gaming/minecraft_servers/GregTech-Odyssey/0.6.0/server.md).
#- One-time setup in it:
#-   echo "eula=true" > eula.txt
{pkgs, ...}: let
  serverDir = "$HOME/Documents/Minecraft_Servers/GregTech.Odyssey-0.6.0-dev27-server";
  sessionName = "gregtech-odyssey";

  startScript =
    pkgs.writeShellScript "gtoserver-start"
    ''
      cd "$1"

      while true; do
          # Same GC as the client instance (0.6.0/java-and-launch.md)
          ${pkgs.jdk25}/bin/java \
              -Xms12G \
              -Xmx12G \
              -XX:+UseZGC \
              -XX:+UseCompactObjectHeaders \
              -XX:+AlwaysPreTouch \
              -XX:+PerfDisableSharedMem \
              @libraries/net/minecraftforge/forge/1.20.1-47.4.20/unix_args.txt \
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

  gto-server =
    pkgs.writeShellScriptBin "gtoserver"
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
          echo "[gtoserver] No log file found at $SERVER_DIR/logs/"
        fi
      }

      _stop() {
        if _session_running; then
          echo "[gtoserver] Sending /stop to session '$SESSION'..."
          ${pkgs.tmux}/bin/tmux send-keys -t "$SESSION" "/stop" Enter
        else
          echo "[gtoserver] No running session '$SESSION' found."
          exit 1
        fi
      }

      _status() {
        if _session_running; then
          echo "[gtoserver] Session '$SESSION' is running."
        else
          echo "[gtoserver] Session '$SESSION' is not running."
        fi
      }

      case "''${1:-}" in
        log) _log ;;
        stop) _stop ;;
        status) _status ;;
        "")
          if _session_running; then
            echo "[gtoserver] Session '$SESSION' already running. Attaching..."
            ${pkgs.tmux}/bin/tmux attach-session -t "$SESSION"
          else
            echo "[gtoserver] Starting server in tmux session '$SESSION'..."
            ${pkgs.tmux}/bin/tmux new-session -d -s "$SESSION" -c "$SERVER_DIR" \
              "${startScript} $SERVER_DIR"
            echo "[gtoserver] Server started. Attaching..."
            ${pkgs.tmux}/bin/tmux attach-session -t "$SESSION"
          fi
          ;;
        *)
          echo "Usage: gtoserver [log|stop|status]"
          exit 1
          ;;
      esac
    '';
in {
  home.packages = [gto-server];
}
