#=====================================================================#
# NIRI VRR TOGGLE
#=====================================================================#
# Mod+Shift+V switches every VRR-capable output between off and on-demand
# (VRR only for windows matched in rules.nix). Lasts until niri restarts.
{
  config,
  pkgs,
  ...
}: let
  vrrToggle = pkgs.writeShellApplication {
    name = "niri-vrr-toggle";
    runtimeInputs = [config.programs.niri.package pkgs.coreutils pkgs.jq pkgs.libnotify];
    text = ''
      state="''${XDG_RUNTIME_DIR:-/run/user/$UID}/niri-vrr-mode"

      if [[ $(cat "$state" 2>/dev/null || true) == on-demand ]]; then
        mode=off
      else
        mode=on-demand
      fi

      mapfile -t outputs < <(niri msg --json outputs | jq -r '.[] | select(.vrr_supported) | .name')
      for o in "''${outputs[@]}"; do
        if [[ $mode == off ]]; then
          niri msg output "$o" vrr off
        else
          niri msg output "$o" vrr on --on-demand
        fi
      done
      echo "$mode" >"$state"

      # Silent, and transient so it stays out of the DMS notification history
      notify-send -a Niri -t 2000 -e -h boolean:suppress-sound:true \
        "VRR" "$([[ $mode == off ]] && echo Off || echo "On demand")"
    '';
  };
in {
  #--------------------------------------------------------------------#
  #-- VRR Toggle
  #--------------------------------------------------------------------#
  home.packages = [vrrToggle];

  niri.keybinds.vrr-toggle = {
    key = "Mod+Shift+V";
    title = "VRR off / on demand";
    action.spawn = "niri-vrr-toggle";
    group = "Monitors";
  };
}
