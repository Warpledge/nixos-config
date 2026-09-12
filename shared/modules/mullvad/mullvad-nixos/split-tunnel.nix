#=====================================================================#
# MULLVAD SPLIT TUNNEL
#=====================================================================#
#- Routes chosen apps around the VPN, permanently.
#-
#- Unlike Android, Mullvad on Linux keeps no per-app list: exclusion is
#- decided at launch by `mullvad-exclude`, which puts the process in the
#- `mullvad-exclusions` net_cls cgroup. Membership is inherited on fork
#- and survives reparenting and systemd-run scopes, so wrapping a
#- launcher also covers every game it spawns.
#-
#- Each name here shadows the real command with a higher-priority
#- wrapper, so the desktop entry (Exec=steam, resolved via PATH) and the
#- shell both go through it. Steam is single-instance: an unwrapped
#- instance started first would silently claim later launches, which is
#- why the wrapper has to own every entry point.
#-
#- Mullvad's lockdown mode does NOT block excluded processes on Linux,
#- so no allowlist is needed alongside this.
{
  config,
  lib,
  pkgs,
  hostConfig,
  ...
}: let
  wanted = hostConfig.mullvad.splitTunnel or [];

  #--- Command name -> the real binary it should shadow
  targets = lib.optionalAttrs hostConfig.gameLaunchers.steam {
    steam = "${config.programs.steam.package}/bin/steam";
  };

  #--- Owned by the home-manager counterpart; listed so a typo here still
  #--- fails loudly instead of being silently wrapped by neither module.
  hmTargets = ["heroic" "prismlauncher" "claude" "opencode" "vesktop" "spotify" "freetube"];

  mine = lib.filter (n: targets ? ${n}) wanted;
  unknown = lib.subtractLists (lib.attrNames targets ++ hmTargets) wanted;

  #--- Falls back to running unwrapped if the setuid helper is absent,
  #--- so disabling Mullvad cannot leave an unlaunchable app behind.
  wrapperFor = name:
    lib.hiPrio (pkgs.writeShellScriptBin name ''
      real=${lib.escapeShellArg targets.${name}}
      if [ -x /run/wrappers/bin/mullvad-exclude ]; then
        exec /run/wrappers/bin/mullvad-exclude "$real" "$@"
      fi
      exec "$real" "$@"
    '');
in {
  config = lib.mkIf (wanted != []) {
    assertions = [
      {
        assertion = unknown == [];
        message = "mullvad.splitTunnel: no wrapper defined for ${lib.concatStringsSep ", " unknown}. Add it to `targets` in mullvad-nixos/split-tunnel.nix or mullvad-home/split-tunnel.nix.";
      }
    ];

    environment.systemPackages = map wrapperFor mine;
  };
}
