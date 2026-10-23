# Test VRR on the desktop monitors

**Goal:** confirm that variable refresh rate (VRR) turns on for games, and only for games, on both desktop monitors, without flicker on the OLED.

Added 2026-10-15.

## What's already in the repo

- `machines/eclipse/wm/niri.nix` sets `variable-refresh-rate = "on-demand"` on DP-2 (Dell AW2725D OLED) and DP-3 (LG ULTRAGEAR). Before the change, `niri msg outputs` listed both as `Variable refresh rate: supported, disabled` (2026-10-15).
- With `"on-demand"`, niri turns VRR on only while a window matched by a `variable-refresh-rate = true` window rule is on that output (niri-flake's `docs.md`). The rule is in `modules/wm/niri/home/core/window-rules.json` and matches these app-ids:
  - `^gamescope$`: nested gamescope (`nix-gamescope`, `nix-vn`, `nix-rpgm`), which sets this app-id itself (`src/Backends/WaylandBackend.cpp`)
  - `\.exe$`: Proton games on Wine's Wayland driver, which the global `PROTON_ENABLE_WAYLAND=1` turns on; winewayland names each window after the lowercased executable (`dlls/winewayland.drv/waylanddrv_main.c`)
  - `^steam_app_`: Proton games on X11, where Proton sets the window class to `steam_app_<id>` (`dlls/winex11.drv/window.c`)
  - `^Minecraft`: the same match the fullscreen rule uses
- The laptop's eDP panel isn't set; `niri msg outputs` there shows whether it supports VRR.

## Steps left

1. After the rebuild, start a game and run `niri msg outputs`. The game's monitor should read `supported, enabled`, and go back to `disabled` once the game closes.
2. If the monitor's on-screen menu shows the live refresh rate, it should follow the game's frame rate while VRR is on.
3. For each game you play, check its app-id with `niri msg pick-window` and add any the rule misses. Native Linux games (tModLoader, EasyRPG, xsystem4, feedBack) set their own.
4. Watch the OLED in dark scenes and loading screens, where frame rates swing. If it flickers, cap the frame rate with MangoHud's `fps_limit`, or drop VRR on DP-2.
5. Wine's own windows (`wineboot.exe`, `control.exe`, `msedgewebview2.exe`) and `.exe` game launchers match `\.exe$` too. If VRR turning on behind one of them causes trouble, add it to an `excludes` list on the rule.
6. Once it works, delete this file.

## Sources

- niri-flake option docs (pinned fork): https://github.com/epireyn/niri-flake
- gamescope: https://github.com/ValveSoftware/gamescope/blob/master/src/Backends/WaylandBackend.cpp
- Proton's Wine, Wayland driver: https://github.com/ValveSoftware/wine/blob/HEAD/dlls/winewayland.drv/waylanddrv_main.c
- Proton's Wine, X11 driver: https://github.com/ValveSoftware/wine/blob/HEAD/dlls/winex11.drv/window.c
