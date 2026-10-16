# Set GameMode's GPU device on the laptop

**Goal:** point GameMode's GPU settings at the right card on the laptop, or switch them off there, the way the desktop got its own value on 2026-10-15.

Added 2026-10-15.

## What's already in the repo

- `modules/nixos/gaming/performance/gamemode.nix` sets `gpu_device = lib.mkDefault 0` next to `amd_performance_level = "high"`. GameMode reads `gpu_device` as the number in `/sys/class/drm/cardN` (upstream's `example/gamemode.ini`).
- `hosts/desktop/hardware/gpu.nix` overrides it to `1`. On the desktop, simpledrm registers `card0` at boot and amdgpu gets `card1` (kernel log, 2026-10-15), so with `0` gamemoded logged `Couldn't open vendor file at /sys/class/drm/card0/device/vendor, will not apply gpu optimisations!` on each game launch and never applied the GPU settings.
- The laptop still gets `0`, unchecked.

## Steps left

1. On the laptop, list which card is which:
   ```bash
   for c in /sys/class/drm/card[0-9]; do echo "$c $(cat "$c/device/vendor")"; done
   ```
   `0x1002` is the AMD 680M and `0x10de` the RTX 4070.
2. See what GameMode does now: launch a game through `nix-performance`, then run `journalctl -b _COMM=gamemoded | grep -i -E 'gpu|vendor'`.
3. Pick a setting. Games run on the 4070 through `nvidia-offload` while the 680M drives the display, and `amd_performance_level = "high"` would pin the 680M's clocks; since the 680M sits on the CPU's chip, that could take power from the CPU. GameMode's NVIDIA options need Coolbits set through `nvidia-xconfig` (upstream's `example/gamemode.ini`), an X11 setting, so they may not apply under niri. Switching the GPU section off on the laptop is the likely answer.
4. Set the laptop's value in `hosts/laptop/hardware/gpu.nix`, the way the desktop's sits in its own `gpu.nix`. To switch the section off, give `apply_gpu_optimisations` any value other than `accept-responsibility`, with `lib.mkForce` since the shared module sets it.
5. Rebuild and repeat step 2.

## Useful info

- `hardware.nvidia.dynamicBoost.enable` went on in `hosts/laptop/hardware/gpu.nix` on 2026-10-15 and hasn't run on the laptop yet. While you're there, `systemctl status nvidia-powerd` shows whether it started, and `nvidia-smi -q -d POWER` shows the 4070's power limits.

## Sources

- GameMode's example config: https://github.com/FeralInteractive/gamemode/blob/master/example/gamemode.ini
