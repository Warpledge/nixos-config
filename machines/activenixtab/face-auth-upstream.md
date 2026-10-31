# Sending face auth upstream

Notes for a later pull request to Warpledge through the `upstream` skill (written
2026-10-31, no PR planned yet). `face-auth.nix` is mostly generic and has only been tested on this Z13.

## Moves as is

- Howdy with `control = "sufficient"`, and the opt-in PAM setup for sudo, polkit and the lock screen
- The polkit helper's sandbox change
- The lock screen order, so a typed password skips the scan
- The IR emitter service

## Has to change

- **Camera path:** the one Z13-specific line. Make it a machine setting, for example `machine.faceAuth.device`, defaulting to null.
- **`dark_threshold`, `max_height`, `timeout`:** tuned for this camera. Make them defaults or per-machine values; the first two are guesses for other hardware.
- **`v4l2loopback`:** the shared hardening module loads it for everyone. Force it off only when the toggle is on, and say in the PR that OBS's virtual camera then stops loading at boot on those machines.

## Work for a new toggle

- `modules/nixos/security/auth/face-auth.nix`, imported through `lib.optionals machine.faceAuth.enable` in `modules/nixos/default.nix`
- The setting in `machines/_template/settings.nix`, off by default
- An entry in `setup.sh`'s `services` list
- This machine's `settings.nix` switched to the toggle, and `face-auth.nix` removed from this folder
- A security note in `modules/nixos/CLAUDE.md`, with `AGENTS.md` kept matching, because a face scan can now grant root
- Possibly an Omni Settings description for the setting

## Tell Warpledge in the PR

- It's only tested on this Z13, and nixpkgs warns that a photo can fool Howdy.
- The polkit sandbox change loosens a security boundary, so it needs its own review.
- Setup has manual steps after the rebuild: `sudo howdy add`, and on some cameras `sudo linux-enable-ir-emitter configure --no-gui`.
