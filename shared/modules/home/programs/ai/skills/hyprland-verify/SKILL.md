---
name: hyprland-verify
description: Verify this NixOS repo's Hyprland config with Hyprland's own checker before handing back. Use after any change under shared/modules/wm/hyprland/, hosts/*/wm/hyprland.nix, Hyprland binds, window or layer rules, monitors, the quad layout, or the Hyprland theming targets, and whenever the user asks whether the Hyprland config is valid, even if the host currently runs niri. nix flake check does not catch Lua config errors; this does.
---

# Hyprland verify

`nix flake check` only proves the Nix evaluates. Hyprland's Lua config can still
carry unknown option keys, bad rule fields or bad dispatcher arguments, which
Hyprland reports only at startup. This skill builds the exact `hyprland.lua`
home-manager would write and runs `Hyprland --verify-config` on it.

## Run it

```bash
bash <skill-dir>/scripts/verify.sh desktop   # or: laptop
```

- Works when the host runs niri: `windowManager` is overridden to `"hyprland"` in
  memory only, nothing in the repo changes.
- `git add` new files first; the flake ignores untracked files.
- Exit code 0 and `config ok` means it passed. Otherwise each error line names the
  generated file and line; map it back to the Nix module that produced it.
- Check both hosts when a change touches shared modules, since the laptop has its
  own monitor, env and autostart overrides.

## What it does not catch

The verifier stops short of runtime behaviour, so say so when reporting a pass:

- Layout names (`general.layout = "quad"`) are not checked; a typo falls back silently.
- Rule *values* are parsed when applied, not at verify time. A rule like
  `blur on ignorealpha 0.85` passes but leaves blur off.
- Placement logic in `core/layouts/*.lua` only runs live.

For those, the user has to rebuild and look.
