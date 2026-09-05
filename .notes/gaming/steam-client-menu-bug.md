# Steam client menus vanish under niri (build 1788400362)

Since Steam client build `1788400362` (downloaded 2026-09-02, applied 2026-09-03) the
client dismisses its own menus instantly on niri: the `Steam` / `View` / `Friends` /
`Games` / `Help` dropdowns and store right-click menus flash and disappear. Build
`1788291500` was fine.

## Workaround (removed 2026-09-05)

Running the client inside a nested **labwc** compositor (`labwc -t "Steam" -S "steam"`)
restored the menus, but the nested window brought its own problems and the wrapper was
dropped. Use **labwc**, not gamescope, if it is ever revived: gamescope exports
`GAMESCOPE_WAYLAND_DISPLAY`, so Steam starts in Big Picture and hangs on
"Switch to Desktop".

## What it is not

Ruled out on 2026-09-04, so don't re-investigate these:

- **focus-follows-mouse.** Tested live with it off; menus still vanish. This is *not*
  the classic [steam-for-linux#6](https://github.com/ValveSoftware/steam-for-linux/issues/6).
- **Steam's "context menu focus compatibility mode"** (Settings → Interface). Only
  lengthens the delay before the menu closes.
- **Client beta channel.** Stable and beta both serve `1788400362` — switching branches
  downloads identical code. Branch lives in `~/.local/share/Steam/package/beta`
  (empty = stable).
- **The system.** niri 26.04, xwayland-satellite 0.8.2 and Xwayland 24.1.13 are identical
  across generations 834 (Sep 1) → 836 (Sep 4), and nothing was rebuilt between Sep 1 and
  the regression.

## Diagnostics that were useful

`niri msg event-stream` during a menu click shows focus moving to the Steam window and
**no window opening** — the menus map as override-redirect surfaces niri never manages,
so no niri window rule can target them.

Client build and update history: `~/.local/share/Steam/logs/bootstrap_log.txt`.

Retest after each client update; drop the workaround once upstream fixes it.
