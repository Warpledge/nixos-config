---
name: rpgm-setup
description: Set up an RPG Maker game (2000/2003, XP, VX, VX Ace, MV, MZ) to run upscaled with Anime4K through gamescope via nix-rpgm, usually in Heroic - identify the engine, pick the preset, set the Heroic wrapper and settings, and fix a black screen. Use when the user asks to set up an RPGM game, make one sharper, adds one to Heroic, or reports a black screen with sound in one.
---

# RPGM setup

`nix-rpgm` runs an RPG Maker game in gamescope at its own resolution and upscales it
with Anime4K (via `nix-vn`, `-F anime4k`). Without arguments it guesses the resolution
from the engine; presets override a game that resizes its own window.

| Engine (how to tell) | Default | Preset |
| --- | --- | --- |
| 2000/2003 (`RPG_RT.exe`, `*.lmu`) | 320x240 | `nix-rpgm-240p`, but prefer EasyRPG |
| XP (`Game.ini` `Library=RGSS1*`, `Data/*.rxdata`) | 640x480 | `nix-rpgm-480p` |
| VX (`RGSS2*`, `*.rvdata`) | 544x416 | `nix-rpgm-416p` |
| VX Ace (`RGSS3*`, `*.rvdata2`, `Game.rgss3a`) | 544x416 | `nix-rpgm-416p` |
| MV / MZ (`www/`, `js/rpg_core.js` / `rmmz_core.js`) | `package.json` `.window` | `-624p` (816x624), `-720p`, `-768p` |

## 1. Find the game

- Heroic sideloads: `jq -r '.games[] | "\(.app_name) \(.title) \(.install.executable)"'
  ~/.config/heroic/sideload_apps/library.json`. Per-game settings are
  `~/.config/heroic/GamesConfig/<app_name>.json`, under the `<app_name>` key.
- Steam: `grep -l "<name>" ~/.local/share/Steam/steamapps/appmanifest_*.acf`.
- Check the `vn-setups` memory for an earlier setup of the same game.

## 2. Identify the engine

From the game folder:

```bash
grep -a -i '^Library=' Game.ini; ls Data | sed 's/.*\.//' | sort | uniq -c
jq -c .window package.json www/package.json 2>/dev/null; ls RPG_RT.* 2>/dev/null
```

Not RPG Maker, so not this skill:
- **WOLF RPG Editor** (`Data.wolf`, `data.dts`, `game.ini` without `Library=`): measure
  and use `nix-vn -r WxH` (the `vn-setup` skill).
- **NScripter** (`nscript.dat`, `*.nsa`): usually 800x600, `nix-vn-600p`.
- **2000/2003:** `gaming.easyrpg` runs these natively and scales them itself; offer that
  first. Some games ship their own EasyRPG build.

The engine default is a guess: many VX / VX Ace games resize to 640x480 with a script
(Hat World, VX, runs at 640x480). Start with plain `nix-rpgm` and measure if wrong.

## 3. Heroic settings

| Setting | Value |
| --- | --- |
| Wrapper command | `nix-rpgm` or a preset, arguments empty (`-r WxH` for odd sizes) |
| Old `/usr/bin/env -u WAYLAND_DISPLAY` wrapper | remove: gamescope keeps Proton on X11, and listed first it hides niri's socket from gamescope |
| Enable Wine-Wayland | off |
| Enable HDR, Enable FSR Hack | off (HDR input makes Anime4K step aside; FSR hack competes with it) |
| `LANG` / `LC_ALL` = `ja_JP.UTF-8`, `PROTON_USE_WINED3D=1` | keep; they pass through gamescope |

The user can set these in Heroic, or, with Heroic closed (`pgrep -f heroic` empty),
edit the JSON after copying it to `<file>.bak`: `wrapperOptions`
(`[{"exe":"nix-rpgm-480p","args":""}]`), `enableWineWayland`, `enableHDR`, `enableFSR`.
Heroic rewrites the file while it runs, so never edit it then.

Steam takes the same commands as a launch option: `nix-rpgm-480p %command%`.

## 4. Verify, and fix a black screen

With the game running:

```bash
pgrep -a gamescope | grep -- '-F anime4k'  # the -w/-h actually used (the last pair wins)
pid=$(pgrep -f -i 'Game\.exe' | tail -1)   # the Windows process (X:\...\Game.exe)
D=$(tr '\0' '\n' < /proc/$pid/environ | sed -n 's/^DISPLAY=//p')
nix shell nixpkgs#xwininfo -c xwininfo -root -tree -display "$D" | grep -v 'has no name'
```

The game's titled window shows its real size, with no Wine frame inside gamescope.
**Black screen with sound** means that window is bigger than gamescope's `-w/-h` and
sits off its edge (Hat World: `640x480+-48+-17` on 544x416). Switch to the preset that
matches the window and restart the game. Super+H cycles Anime4K, Super-xBR and linear
with a notification;
Super+G grabs the keyboard if Super+H doesn't reach gamescope.

## 5. Record it

Add a row to the `vn-setups` memory: game, Heroic app_name or Steam app id, wrapper,
engine and any quirk. The repo is public: adult titles stay out of repo files and
`README.md`, or get a stand-in name (see the stand-in key in memory).
