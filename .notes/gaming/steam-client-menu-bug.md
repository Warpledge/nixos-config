# Steam client menus vanish under niri

The `Steam` / `View` / `Friends` / `Games` / `Help` dropdowns and store right-click
menus flash and disappear within ~50 ms. Noticed 2026-09-03.

## Cause

**xwayland-satellite 0.8.2**, not Steam. Upstream commit `3273a0f` (shipped in the
v0.8.2 tag, released 2026-07-22) made satellite give X11 input focus to
override-redirect windows. Steam's menus are override-redirect, so focus lands on the
menu, immediately reverts to the main window, and Steam dismisses the menu on the
focus-out.

Upstream: [#489](https://github.com/Supreeeme/xwayland-satellite/issues/489),
[#468](https://github.com/Supreeeme/xwayland-satellite/issues/468) — fixed by
[PR #494](https://github.com/Supreeeme/xwayland-satellite/pull/494), merged
2026-09-09 as `add2795`. The fix never focuses override-redirect windows and routes
`WM_TAKE_FOCUS` for the rest (`src/server/mod.rs`, `should_focus`).

The Steam client build was a red herring: #489 reproduces on `1788291500`, the build
that looked fine here, and the bug persists on `1788652215`.

## Fix in this repo

`niri-home/core/xwayland.nix` pins `xwayland-satellite` to `add2795` via
`overrideAttrs` and sets `programs.niri.settings.xwayland-satellite.path` so niri uses
it instead of resolving from PATH. Drop the pin once nixpkgs ships a tag containing
that commit; niri-flake's `xwayland-satellite-unstable` is also still on 0.8.2.

## Why this was missed the first time

The lock bump that pulled 0.8.1 -> 0.8.2 sat uncommitted in the working tree for two
days (nixpkgs `e8273b29fe`, 2026-07-01, has 0.8.1; `ac6b2166e7`, 2026-08-24, has
0.8.2, and only landed in git on 2026-09-05). Comparing committed commits, or
generations 834/836 which both already had 0.8.2, showed no change.

## What it is not

Ruled out on 2026-09-04, so don't re-investigate these:

- **focus-follows-mouse.** Tested live with it off; menus still vanish.
- **Steam's "context menu focus compatibility mode"** (Settings -> Interface). Only
  lengthens the delay, which is itself the tell that dismissal is focus-driven.
- **Client beta channel.** Stable and beta serve identical code.
- **niri.** 26.04 throughout; unchanged across every commit in the window.

## Workaround (removed 2026-09-05, no longer needed)

Running the client inside a nested **labwc** compositor restored the menus but brought
its own problems. Use labwc, not gamescope, if it is ever revived: gamescope exports
`GAMESCOPE_WAYLAND_DISPLAY`, so Steam starts in Big Picture and hangs on
"Switch to Desktop".

## Diagnostics

`niri msg event-stream` during a menu click shows focus moving to the Steam window and
no window opening -- the menus map as override-redirect surfaces niri never manages,
so no niri window rule can target them.

Client build and update history: `~/.local/share/Steam/logs/bootstrap_log.txt`.
