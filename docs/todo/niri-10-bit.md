# Get 10-bit colour from niri

**Goal:** have niri draw 10 bits per channel on the desktop monitors, then move back to a released niri once one includes it.

Added 2026-10-16.

## Background

- The Dell AW2725D OLED (DP-2) reports a 30-bit signal, but on niri 26.04 from nixpkgs the image itself was 8-bit. `drm_info` showed both monitors scanning out an `XR24` (XRGB8888) framebuffer, with `max bpc` at 16 on both connectors (2026-10-16).
- 10-bit framebuffers landed in niri in commit `9bd6c2c` ("feat: add 10-bit framebuffer pixel format", merged 2026-05-28). It needs no setting: it turns on for outputs that support it (YaLTeR in issue #4205).
- v26.04 (2026-04-25) is the latest niri release as of 2026-10-16, so no release has it yet.

## What's already in the repo

- `modules/wm/niri/session.nix` sets `programs.niri.package` to niri-flake's `niri-unstable` build, pinned by the `niri` input's lock (niri `45739bc` on 2026-10-16), and uses it for the session package.
- `modules/wm/niri/home/core/settings.nix` takes home-manager's niri package from `osConfig.programs.niri.package`, so both halves run the same build.
- The `niri` input follows this flake's nixpkgs, so a matching build depends on the input's lock; `niri-epireyn.cachix.org` (in `modules/nixos/nix/substituters.nix`) carries epireyn's `niri-unstable` builds and had the one this repo locks (2026-10-25). When it misses, niri compiles locally.

## Steps left

1. Apply with `nixm boot` and reboot (CLAUDE.md: niri version changes froze the desktop when switched live).
2. Check the scanout format: `nix shell nixpkgs#drm_info -c drm_info /dev/dri/card1 | grep -i 'format'`. A 10-bit framebuffer shows as `XR30` or `AR30` instead of `XR24`.
3. Watch the first `nixm flake-update` after the switch: `niri-unstable` follows niri's main branch, so config options can change between updates.
4. Once a niri release after v26.04 reaches nixpkgs (`nix eval --raw nixpkgs#niri.version`), set the package back to `pkgs.niri` in `session.nix`, drop the `niri` binding there, rebuild with `nixm boot`, and repeat step 2.
5. Delete this file.

## Sources

- niri 10-bit commit: https://github.com/niri-wm/niri/commit/9bd6c2cadda26450d435785815a634c320127a1c
- niri issue #4205: https://github.com/niri-wm/niri/issues/4205
- niri releases: https://github.com/niri-wm/niri/releases
- niri-flake (pinned fork): https://github.com/epireyn/niri-flake
- drm_info: https://gitlab.freedesktop.org/emersion/drm_info
