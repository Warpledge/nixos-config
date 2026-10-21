# Window Managers

<!-- Claude Code loads this file when it reads a file in this folder. -->

Niri is the only WM. Hyprland was removed on 2026-10-21; its modules, machine files and the `hyprland-verify` skill are on the `hyprland-backup` branch.

Niri uses attribute-set actions, and **spawns with arguments must be lists**, not strings (`modules/wm/niri/home/core/binds.nix`):
```nix
programs.niri.settings.binds = {
  "Mod+Return".action.spawn = "kitty";                            # single command, string OK
  "XF86AudioPlay".action.spawn = ["playerctl" "play-pause"];      # args → must be a list
  "Mod+Left".action.focus-column-left = {};
};
```

A string like `"dms ipc call spotlight"` in Niri only runs `dms` and drops the rest, so use `["dms" "ipc" "call"] ++ lib.splitString " " action`. An assertion in `niri/home/core/binds.nix` fails the build on a `spawn` string containing a space.

**DMS** (DankMaterialShell): declarative config lives at `modules/wm/niri/home/dms/` (`default.nix`, `settings.json`, `clsettings.json` and `niri-cheatsheet.json`). Its DMS keybind helper is list concat. The module points `settings.json`'s `customThemeFile` at the current user's `~/.config`, since the mirrored file names one home folder, and merges a machine's `dms.extraSettings` (its bars, the laptop's lock timeout) over the file last. Neither file is a store link: the module hands them to `dms.mutableFiles` (`modules/wm/dms-mutable.nix`), which writes real files the DMS settings GUI saves to (the merge itself is `lib/mutable-merge.jq`, shared with Zed). On each activation a key takes the repo's value only when it's missing, still matches what the repo last applied (kept in `~/.local/state/dms-declared/`), or is listed in `dms.lockedSettings` (theme, fonts, cursor, and the wallpaper keys under `wallpaper = "engine"`), so every other GUI change survives rebuilds and a fresh install gets the repo's file. Under niri the GUI's keybinds and monitors work too: `dms/binds.kdl` and `dms/outputs.kdl` are plain files (`dms.writableFiles`), binds.kdl loads after `hm.kdl` so its binds override the repo's, and outputs.kdl loads before it, since niri uses the first `output` block per monitor. So do its Mouse & Touchpad and Keyboard pages: `dms/input.kdl` loads after `hm.kdl`, and what DMS writes there (pointer acceleration, scrolling, tapping, disable-while-typing, middle-click emulation, Num Lock) is seeded as DMS settings (`inputDefaults` in niri's `dms/default.nix`) rather than set in `core/settings.nix`. DMS leaves a switched-off flag out instead of writing `false`, so a flag `hm.kdl` sets could never be turned off; niri-flake turns touchpad `tap` and `natural-scroll` on by default, hence their explicit `false` there. The keyboard layout stays the machine's `keyboardLayout` until layouts are added on DMS's Keyboard page. Plugin settings go in `dms.pluginSettings.<plugin>`, not `plugins.<plugin>.settings`: niri writes `plugin_settings.json` itself (`managePluginSettings = false`), and DMS warns it ignores `plugins.*.settings` then.

DMS runs as a systemd user service (`systemd.enable`, `niri.enableSpawn = false`), so it inherits the **systemd user manager** environment (`modules/home/variables.nix`), not niri's `programs.niri.settings.environment` block. It launches every app with `systemd-run --user --scope`, so those session variables, and not niri's, govern anything started from the spotlight. Keep the two sets compatible: `QT_QPA_PLATFORM`, `GDK_BACKEND` and `SDL_VIDEODRIVER` must keep their X11 fallbacks (`wayland;xcb`, `wayland,x11`, `wayland,x11`) or X11-only apps die instantly from the launcher while still working from a terminal: a Qt app with no wayland plugin aborts in ~50 ms, a JUCE/GTK one exits with "cannot open display". Diagnose by diffing `tr '\0' '\n' < /proc/$(pgrep -x .quickshell-wra)/environ` against `env`, then replaying with `env -i "${DMS_ENV[@]}" <app>`. A rebuild alone does not fix a bad value: the running manager keeps the old import, so `systemctl --user set-environment` then restart `dms.service`, or log out.

**XDG portals** (Niri): `niri/session.nix` strips `GDK_BACKEND` from `xdg-desktop-portal-gnome`, and `niri/home/core/portals.nix` adds the gtk backend back. Read `docs/wm/niri-xdg-portals.md` before touching either, and never "fix" a portal by dropping the X11 fallback from `variables.nix`.

**Login:** Niri starts from the DMS greeter (greetd, through the `dux-greeter` input, set up in `niri/session.nix`).

**Niri-only directories:** `core/blur-presets.nix`, `core/portals.nix`, `core/rules.nix` (plus `core/window-rules.json`), `core/translucent-apps.nix`, `core/vrr.nix`, `core/xwayland.nix`, `nirius.nix`.

Per-machine WM overrides exist where needed, each applied to every user on the machine:
- `machines/legion/wm/niri.nix` — hybrid-GPU env, Solaar autostart, the internal panel's outputs, DMS auto-lock off
- `machines/eclipse/wm/niri.nix` — monitor layout and workspace assignment (1–6 on DP-2, 7–9 on DP-3), app placement, and the DMS bars (an auto-hiding copy of the main bar on the OLED)
- `machines/_template/wm/niri.nix` — commented monitor examples; with no outputs set, niri uses each monitor's preferred mode

These are only imported when the WM is active, e.g. `lib.optional (machine.windowManager == "niri") ./wm/niri.nix`.
