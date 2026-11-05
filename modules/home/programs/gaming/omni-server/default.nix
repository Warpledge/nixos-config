#=====================================================================#
# OMNI SERVER CONFIGURATION
#=====================================================================#
#- QML app (Quickshell) that runs modded Minecraft servers from their folders:
#- headless through systemd user units, with live stats, console, players and
#- GUI editors. CLAUDE.md here says how it fits together.
{
  pkgs,
  lib,
  ...
}: let
  omni = ../../system/omni-settings/qml;
  #--- Omni Settings' parts this app is built from; a change there reaches both
  shared = [
    "Backend"
    "Chip"
    "ConfirmDialog"
    "Field"
    "Fmt"
    "Icon"
    "IconButton"
    "LineGraph"
    "OutlineButton"
    "Pill"
    "Section"
    "Segmented"
    "Sheet"
    "Theme"
    "Tip"
    "TitleTip"
    "Toggle"
  ];
  #--- Picked per server on the Settings page; a server stores the number, not a store
  #--- path, so garbage collection can't break it
  javas = {
    "8" = pkgs.jdk8;
    "17" = pkgs.jdk17;
    "21" = pkgs.jdk21;
    "25" = pkgs.jdk25;
  };
  javasJson = builtins.toJSON (lib.mapAttrs (_: jdk: "${jdk}/bin/java") javas);

  omni-server = pkgs.stdenvNoCC.mkDerivation {
    pname = "omni-server";
    version = "1.0";
    src = ./src;
    nativeBuildInputs = [pkgs.makeWrapper];
    installPhase = ''
      runHook preInstall
      share=$out/share/omni-server
      install -Dm644 -t $share *.py
      # Python can't cache bytecode in the store, so each call would recompile
      ${pkgs.python3}/bin/python3 -m compileall -q --invalidation-mode unchecked-hash $share
      cp -r ${./addons} $share/addons
      chmod -R u+w $share/addons
      install -Dm644 -t $share/qml ${./qml}/*.qml
      ${lib.concatMapStringsSep "\n" (n: "install -Dm644 -t $share/qml ${omni}/${n}.qml") shared}
      substitute ${./qml/Config.qml.in} $share/qml/Config.qml \
        --subst-var-by backend $out/bin/omni-server-backend
      for f in $share/qml/[A-Z]*.qml; do
        n=$(basename $f .qml)
        grep -q '^pragma Singleton' $f && echo "singleton $n 1.0 $n.qml" || echo "$n 1.0 $n.qml"
      done > $share/qml/qmldir
      #--- The window; `omni-server console <name>` is the terminal view
      mkdir -p $out/bin
      cat > $out/bin/omni-server <<EOF
      #!${pkgs.runtimeShell}
      if [ "\''${1:-}" = console ]; then
        exec $out/bin/omni-server-backend "\$@"
      fi
      exec ${pkgs.quickshell}/bin/qs -p $share/qml/shell.qml
      EOF
      chmod +x $out/bin/omni-server
      #--- The backend the QML calls, the service's runner and its monitor
      for tool in api:omni-server-backend runner:omni-server-run monitor:omni-server-monitor; do
        makeWrapper ${pkgs.python3}/bin/python3 $out/bin/''${tool#*:} \
          --add-flags $share/''${tool%%:*}.py \
          --set OMNI_SERVER_JAVAS ${lib.escapeShellArg javasJson} \
          --prefix PATH : ${lib.makeBinPath [pkgs.zenity pkgs.systemd]}:/run/current-system/sw/bin
      done
      runHook postInstall
    '';
  };
in {
  options.omni-server.package = lib.mkOption {
    type = lib.types.package;
    readOnly = true;
    description = "The Omni Server build in home.packages.";
  };

  config.omni-server.package = omni-server;

  config.home.packages = [omni-server];

  #--------------------------------------------------------------------#
  #-- Server Units
  #--------------------------------------------------------------------#

  #--- The server's stdin. PartOf: once the server stops so does this, or a write
  #--- to the FIFO would start it again
  config.systemd.user.sockets."omni-server@" = {
    Unit = {
      Description = "Omni Server: stdin for %i";
      PartOf = ["omni-server@%i.service"];
    };
    Socket = {
      ListenFIFO = "%t/omni-server/%i.stdin";
      RemoveOnStop = true;
      DirectoryMode = "0700";
      SocketMode = "0600";
    };
  };

  config.systemd.user.services."omni-server@" = {
    Unit = {
      Description = "Omni Server: %i";
      Requires = ["omni-server@%i.socket"];
      Wants = ["omni-server-monitor@%i.service"];
      After = ["omni-server@%i.socket"];
      # Crash-looping stops by itself rather than loading a broken world forever
      StartLimitIntervalSec = 600;
      StartLimitBurst = 5;
      # A rebuild mustn't restart a running server; the new build applies next start
      X-SwitchMethod = "keep-old";
    };
    Service = {
      ExecStartPre = "${omni-server}/bin/omni-server-run prestart %i";
      ExecStart = "${omni-server}/bin/omni-server-run run %i";
      # Sends `stop` and waits, so a logout or shutdown saves the world
      ExecStop = "${omni-server}/bin/omni-server-run stop %i";
      TimeoutStopSec = 300;
      KillMode = "mixed";
      SuccessExitStatus = 143;
      Restart = "on-failure";
      RestartSec = 12;
      StandardInput = "socket";
      # A file, not the journal: GTNH's 40k startup lines would hit its rate limit
      StandardOutput = "append:%S/omni-server/%i/console.log";
      StandardError = "inherit";
    };
    # No Install section: home-manager would try to start the bare template (CLAUDE.md)
  };

  config.systemd.user.services."omni-server-monitor@" = {
    Unit = {
      Description = "Omni Server: stats for %i";
      BindsTo = ["omni-server@%i.service"];
      # Before: a stop reverses this, so it outlives the server and reads its last lines,
      # which name the dimensions (src/logparse.py)
      Before = ["omni-server@%i.service"];
      X-SwitchMethod = "keep-old";
    };
    Service = {
      ExecStart = "${omni-server}/bin/omni-server-monitor %i";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  #--------------------------------------------------------------------#
  #-- Desktop Entry
  #--------------------------------------------------------------------#

  config.xdg.desktopEntries.omni-server = {
    name = "Omni Server";
    genericName = "Minecraft Server Manager";
    comment = "Run modded Minecraft servers, with live stats and a console";
    exec = "omni-server";
    icon = "${./icon.svg}";
    terminal = false;
    categories = ["Game" "Network"];
    settings.StartupWMClass = "org.quickshell";
  };
}
