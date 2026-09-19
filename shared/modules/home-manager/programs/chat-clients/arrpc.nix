#=====================================================================#
# ARRPC — DISCORD RICH PRESENCE / GAME DETECTION SERVER
#=====================================================================#
# Standalone arRPC, replacing Vesktop's bundled scanner: it binds the
# discord-ipc socket for apps that push presence (Heroic) and scans running
# processes against Discord's detectable-games list for Steam/Proton titles.
# Vesktop reads it over ws://127.0.0.1:1337 via the Vencord
# "WebRichPresence (arRPC)" plugin, so turn Vesktop's own "Rich Presence
# (arRPC)" toggle OFF or the two fight over the discord-ipc-0 socket.
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
