---
name: vn-setup
description: Set up a visual novel or other 2D game to run upscaled with Anime4K through gamescope on this machine - find its own resolution from the running window, pick the nix-vn preset and hand back the launch option. Use when the user asks to set up a VN, make one look sharper or less blurry, upscale a 2D game, or names a VN and asks for its gamescope/xBR launch option.
---

# VN setup

`nix-vn` runs a game in gamescope at its own resolution and upscales it with Anime4K
(`-F anime4k`, patched into gamescope in `nixos/gaming/tools/gamescope/`). The only
per-game fact needed is that resolution, so this skill measures it and picks a preset.

| Game resolution | Launch option |
| --- | --- |
| 800x600 | `nix-vn-600p %command%` |
| 1024x768 | `nix-vn-768p %command%` |
| 1280x720 | `nix-vn-720p %command%` |
| 1600x900 | `nix-vn-900p %command%` |
| 1920x1080 | `nix-vn-1080p %command%` |
| anything else | `nix-vn -r WxH %command%` |

**RPG Maker games go through the `rpgm-setup` skill** (`nix-rpgm`, which detects the
engine). Heroic settings and the black-screen check there apply to VNs in Heroic too.

## 1. Identify the game

- Steam: find the app id and folder from the manifest:
  `grep -l "<name>" ~/.local/share/Steam/steamapps/appmanifest_*.acf`.
- Check memory for a recorded setup first (the `vn-setups` entry).
- Check the engine before reaching for gamescope (see the game-troubleshooting skill,
  step 6): a System 4 game runs on `xsystem4`, wrapped as `nix-vn-<size> xsystem4
  "<game dir>" # %command%` with the size from `System40.ini`'s `ViewWidth`; RPG Maker
  2000/2003 runs on EasyRPG; a native Linux Ren'Py build renders at the window's size
  and gains nothing from this.

## 2. Measure the resolution

Ask the user to start the game once with the launch option empty, windowed (the default
for most VNs). Then read the window:

```bash
# niri
niri msg --json windows | jq -c '.[] | select(.app_id // "" | test("\\.exe$"; "i"))
  | {title, app_id, size: .layout.window_size}'
# Hyprland
hyprctl clients -j | jq -c '.[] | select(.class | test("\\.exe$"; "i")) | {title, class, size}'
```

- `app_id` is usually the exe name in lower case; match the title too.
- The size includes Wine's window frame: Flowers measured 1286x752 for 1280x720
  (3 px borders and a title bar). Pick the preset a few pixels narrower and up to about
  40 px shorter than the measurement.
- A window as large as the monitor means the game is fullscreen: ask the user to switch
  it to windowed (Alt+Enter or its settings) and measure again.

## 3. Hand back the launch option

Give the matching line for Steam → Properties → Launch Options. If the game's launch
option already wraps `%command%` (an exe swap, env vars), keep that after the preset:
`nix-vn-720p bash -c '...' -- %command%`, `nix-vn-720p LANG=ja_JP.UTF-8 %command%`.
Heroic and Lutris take the preset command in their wrapper or command-prefix field, with
no `%command%`.

## 4. Verify

After the user relaunches with it:

```bash
pgrep -a gamescope | grep -- '-F '   # shows -w/-h and the filter as chosen
```

The picture should fill the screen height, centred. Cropped or wrongly stretched means
the resolution is wrong: measure again. Super+H cycles Anime4K, Super-xBR and linear,
naming each in a notification; if it does nothing, Super+G makes gamescope grab the
keyboard first.

## 5. Record it

Add a line to the `vn-setups` memory: game, app id, preset. The repo is public, so an
adult title is named by its stand-in (see the stand-in key in memory) if it ever reaches
a repo file, and never appears in `README.md`.
