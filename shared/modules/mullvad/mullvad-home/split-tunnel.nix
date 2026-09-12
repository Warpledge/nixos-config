#=====================================================================#
# MULLVAD SPLIT TUNNEL (HOME MANAGER)
#=====================================================================#
#- Counterpart to mullvad-nixos/split-tunnel.nix, driven by the
#- same hostConfig.mullvad.splitTunnel list.
#-
#- The home profile sits earlier in PATH than /run/current-system/sw/bin,
#- so a NixOS-side wrapper for a home-manager package is shadowed and
#- never runs. Anything installed via home.packages must be wrapped here.
#-
#- Mechanism is identical: mullvad-exclude puts the process in the
#- mullvad-exclusions net_cls cgroup and children inherit, so wrapping a
#- launcher also covers every game it spawns.
{
  lib,
  pkgs,
  hostConfig,
  ...
}: let
  wanted = hostConfig.mullvad.splitTunnel or [];

  #--- Command name -> the real binary it shadows. Gated on each app's own
  #--- toggle so a shared splitTunnel list cannot pull an app onto a host
  #--- that does not install it.
  targets =
    lib.optionalAttrs hostConfig.gameLaunchers.heroic {
      heroic = "${pkgs.heroic}/bin/heroic";
    }
    // lib.optionalAttrs hostConfig.gameLaunchers.prismlauncher {
      prismlauncher = "${pkgs.prismlauncher}/bin/prismlauncher";
    }
    // lib.optionalAttrs hostConfig.claude.enable {
      claude = "${pkgs.claude-code}/bin/claude";
    }
    // lib.optionalAttrs hostConfig.opencode.enable {
      opencode = "${pkgs.opencode}/bin/opencode";
    };

  mine = lib.filter (n: targets ? ${n}) wanted;

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
  home.packages = map wrapperFor mine;
}
