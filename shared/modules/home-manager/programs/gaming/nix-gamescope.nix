#=====================================================================#
# NIX-GAMESCOPE - GAMESCOPE LAUNCH WRAPPER
#=====================================================================#
#- `nix-gamescope %command%` runs the game fullscreen in gamescope at the
#- focused monitor's resolution and refresh (read from niri or Hyprland;
#- nested gamescope can't detect them and falls back to 1280x720), under
#- nix-performance. Base flags come from nixos/gaming/gamescope.nix.
#- Extra gamescope flags go before `--` and override the detected ones:
#-   nix-gamescope -w 1920 -h 1080 -F fsr -- %command%
#- --force-grab-cursor locks the pointer to the game; add it only where it escapes.
#- Use --mangoapp for the overlay, not mangohud (gamescope's own advice).
{pkgs, ...}: let
  jq = "${pkgs.jq}/bin/jq";

  nix-gamescope =
    pkgs.writeShellScriptBin "nix-gamescope"
    # bash
    ''
      if [[ $# -eq 0 ]]; then
        echo "usage: nix-gamescope [gamescope flags --] <command> [args...]" >&2
        exit 1
      fi

      # Steam's overlay hook must not load into gamescope itself
      unset LD_PRELOAD

      # Overrides the global =1 (variables.nix): Wine's Wayland driver hangs on
      # gamescope's --expose-wayland socket, so Proton uses gamescope's Xwayland
      export PROTON_ENABLE_WAYLAND=0

      # %command% never starts with a dash, so a `--` inside the game's own args is left alone
      extra=()
      if [[ $1 == -* ]]; then
        while [[ $# -gt 0 && $1 != -- ]]; do
          extra+=("$1")
          shift
        done
        if [[ $# -lt 2 ]]; then
          echo "nix-gamescope: no command after --" >&2
          exit 1
        fi
        shift
      fi

      mode=""
      if [[ -n $NIRI_SOCKET ]]; then
        mode=$(niri msg --json focused-output \
          | ${jq} -r '.modes[.current_mode] | "\(.width) \(.height) \(.refresh_rate / 1000 | round)"')
      elif [[ -n $HYPRLAND_INSTANCE_SIGNATURE ]]; then
        mode=$(hyprctl -j monitors \
          | ${jq} -r '.[] | select(.focused) | "\(.width) \(.height) \(.refreshRate | round)"')
      fi

      detected=()
      if [[ -n $mode ]]; then
        read -r w h r <<<"$mode"
        detected=(-W "$w" -H "$h" -w "$w" -h "$h" -r "$r")
      fi

      exec /run/current-system/sw/bin/gamescope "''${detected[@]}" -f "''${extra[@]}" -- nix-performance "$@"
    '';
in {
  home.packages = [nix-gamescope];
}
