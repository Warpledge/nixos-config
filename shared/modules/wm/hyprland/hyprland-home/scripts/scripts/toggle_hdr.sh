#!/usr/bin/env bash
# Toggle HDR on/off for Dell AW2725D OLED monitor

# Reads the live preset, so the toggle stays correct across restarts and reloads.
# Keep the mode string in sync with hosts/desktop/wm/hyprland.nix.
MONITOR='output = "DP-2", mode = "2560x1440@280", position = "0x0", scale = 1.0, bitdepth = 10'
PRESET=$(hyprctl monitors -j | jq -r '.[] | select(.name == "DP-2") | .colorManagementPreset')

if [ "$PRESET" = "hdr" ]; then
  hyprctl eval "hl.monitor({ $MONITOR, cm = \"auto\" })" > /dev/null
  notify-send "HDR" "Disabled" -u low -i display-brightness-low 2>/dev/null || true
else
  hyprctl eval "hl.monitor({ $MONITOR, cm = \"hdr\" })" > /dev/null
  notify-send "HDR" "Enabled" -u low -i display-brightness 2>/dev/null || true
fi
