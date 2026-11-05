#=====================================================================#
# VALHEIM DEDICATED SERVER
#=====================================================================#
#- Ky's Gale profile ("Doobie Canoe With Friends") as a permanent modded
#- server, hidden from the public list; friends join by IP. The world is
#- seeded from Steam Cloud once, then the server owns it in worlds/.
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

  #--- Stage Steam's install and the mod profile beside a writable save dir
  prepare = pkgs.writeShellApplication {
    name = "valheim-server-prepare";
    runtimeInputs = [pkgs.coreutils pkgs.rsync];
    text = ''
      mkdir -p ${base}/game ${base}/worlds ${base}/logs

      #--- Steams's files, leaving the ones the mod profile supplies
      rsync -a --delete --exclude=/BepInEx --exclude=/doorstop_libs \
        --exclude=/doorstop_config.ini ${steamDs}/ ${base}/game/

      #--- The mod set follows Ky's Gale profile, so client and server match
      rsync -a --delete ${galeProfile}/BepInEx/plugins/ ${base}/game/BepInEx/plugins/
      rsync -a --delete ${galeProfile}/BepInEx/patchers/ ${base}/game/BepInEx/patchers/
      rsync -a ${galeProfile}/BepInEx/core/ ${base}/game/BepInEx/core/
      rsync -a ${galeProfile}/BepInEx/config/ ${base}/game/BepInEx/config/
      rsync -a ${galeProfile}/doorstop_libs/ ${base}/game/doorstop_libs/
      install -m 644 ${galeProfile}/doorstop_config.ini ${base}/game/doorstop_config.ini

      #--- Seed the world once; resyncing would overwrite progress
      if [ ! -d ${base}/worlds/worlds_local/${world} ]; then
        mkdir -p ${base}/worlds/worlds_local
        rsync -a ${cloudWorlds}/${world} ${base}/worlds/worlds_local/
      fi
    '';
  };

  #--- Password comes from ${base}/env, not this public repo
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
      -logfile ${base}/logs/server.log
  '';
in {
  #--- Forward the same range on the router to this machine
  networking.firewall.allowedUDPPorts = [2456 2457 2458];

  systemd.services.valheim-server = {
    description = "Valheim dedicated server (modded: Doobie Canoe With Friends)";
    wantedBy = ["multi-user.target"];
    wants = ["network-online.target" "valheim-server-inhibit.service"];
    after = ["network-online.target" "valheim-server-inhibit.service"];
    serviceConfig = {
      User = user;
      WorkingDirectory = "${base}/game";
      EnvironmentFile = "-${base}/env";
      ExecStartPre = "${prepare}/bin/valheim-server-prepare";
      ExecStart = "${launch}";
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
    serviceConfig = {
      Type = "simple";
      ExecStart = "${config.systemd.package}/bin/systemd-inhibit --what=idle:sleep:handle-lid-switch --who=valheim-server --why=ValheimServerRunning --mode=block ${pkgs.coreutils}/bin/sleep infinity";
      Restart = "no";
    };
  };
}
