#!/usr/bin/env bash
# Toggle HDR on/off for Dell AW2725D OLED monitor

HDR_STATE_FILE="$HOME/.cache/hyprland_hdr_state"
mkdir -p "$HOME/.cache"

# Initialize state file if it doesn't exist
if [ ! -f "$HDR_STATE_FILE" ]; then
  echo "0" > "$HDR_STATE_FILE"
fi

# Check current state
HDR_ENABLED=$(cat "$HDR_STATE_FILE" 2>/dev/null || echo "0")

if [ "$HDR_ENABLED" = "1" ]; then
  # Disable HDR
  hyprctl keyword monitor "DP-2, 2560x1440@280, 0x0, 1.0, bitdepth, 10" 2>&1 > /dev/null
  echo "0" > "$HDR_STATE_FILE"
  notify-send "HDR" "Disabled" -u low -i display-brightness-low 2>/dev/null || true
else
  # Enable HDR
  hyprctl keyword monitor "DP-2, 2560x1440@280, 0x0, 1.0, bitdepth, 10, cm, hdr" 2>&1 > /dev/null
  echo "1" > "$HDR_STATE_FILE"
  notify-send "HDR" "Enabled" -u low -i display-brightness 2>/dev/null || true
fi
