#=====================================================================#
# ARRPC — DISCORD RICH PRESENCE / GAME DETECTION SERVER
#=====================================================================#
# Standalone arRPC replaces Vesktop's bundled (older, weaker) scanner.
# It binds the discord-ipc socket for apps that push presence (Heroic),
# AND scans running processes against Discord's detectable-games list to
# report Steam/Proton titles. Vesktop reads it via the Vencord
# "WebRichPresence (arRPC)" plugin (ws://127.0.0.1:1337).
#
# NOTE: turn OFF Vesktop's built-in "Rich Presence (arRPC)" toggle so the
# two don't fight over the discord-ipc-0 socket.
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- User Service
  #--------------------------------------------------------------------#
  systemd.user.services.arrpc = {
    Unit.Description = "arRPC — open Discord RPC server (game detection)";

    Install = {
      WantedBy = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.arrpc}/bin/arrpc";
      Restart = "on-failure";
      RestartSec = 5; # Wait before restarting to avoid thrashing
    };
  };
}
