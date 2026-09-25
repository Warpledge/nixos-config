#=====================================================================#
# NIX-PERFORMANCE - PER-GAME PERFORMANCE LAUNCH WRAPPER
#=====================================================================#
#- NixOS take on CachyOS's game-performance. Use as a Steam launch option
#- (`nix-performance %command%`) or a Heroic/Lutris wrapper command.
#- Global tuning env vars already live in gaming.nix; this adds the parts
#- that must stay per-game:
#-   unset LD_PRELOAD drops Steam's overlay hook; must run before gamemoderun
#-   gamemoderun      governor, AMD GPU clocks, renice, screensaver inhibit
#-                    (settings in nixos/gaming/gamemode.nix)
#-   mangohud         FPS overlay (config in gaming.nix); skipped inside gamescope,
#-                    which takes --mangoapp instead
#-   nvidia-offload   laptop only: route the game to the RTX 4070
#-   PROTON_*_UPGRADE newest FSR4 (desktop, RDNA4) or DLSS (laptop) DLL, fetched
#-                    by GE/CachyOS/DW Proton; a launch-option value wins, `=0` opts out
{pkgs, ...}: let
  nix-performance =
    pkgs.writeShellScriptBin "nix-performance"
    # bash
    ''
      if [[ $# -eq 0 ]]; then
        echo "usage: nix-performance <command> [args...]" >&2
        exit 1
      fi

      unset LD_PRELOAD

      hud=(${pkgs.mangohud}/bin/mangohud)
      if [[ -n $GAMESCOPE_WAYLAND_DISPLAY ]]; then
        hud=()
      fi

      if command -v nvidia-offload >/dev/null; then
        export PROTON_DLSS_UPGRADE="''${PROTON_DLSS_UPGRADE:-1}"
        exec nvidia-offload ${pkgs.gamemode}/bin/gamemoderun "''${hud[@]}" "$@"
      fi

      export PROTON_FSR4_UPGRADE="''${PROTON_FSR4_UPGRADE:-1}"
      exec ${pkgs.gamemode}/bin/gamemoderun "''${hud[@]}" "$@"
    '';
in {
  home.packages = [nix-performance];
}
