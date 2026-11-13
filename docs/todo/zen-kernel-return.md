# Switch eclipse back to the zen kernel

**Goal:** put eclipse back on `kernel = "zen"` once nixpkgs ships a linux-zen newer than 7.3.4, which panics at boot on this machine.

Added 2026-11-13.

## What's already in the repo

- `machines/eclipse/settings.nix` sets `kernel = "latest"` as the workaround (commit `7536b3e`). `modules/nixos/system/bootloader.nix` maps that to `pkgs.linuxPackages_latest`.
- The last generation on zen that boots is 1562 (linux-zen 7.2.15, nixpkgs `20261107.f4a03c0`). 7.2 has since been dropped from nixpkgs as end of life.

## Steps

1. Check the zen version in the flake's nixpkgs after a flake update:
   ```bash
   nix eval --impure --raw --expr '(builtins.getFlake "/etc/nixos-config").inputs.nixpkgs.legacyPackages.x86_64-linux.linuxPackages_zen.kernel.version'
   ```
2. If it's newer than 7.3.4, set `kernel = "zen"` in `machines/eclipse/settings.nix` (or in Omni Settings), run `nixm boot` and reboot.
3. If it still panics, pick the previous generation in the boot menu and set `kernel = "latest"` again.
4. Once zen boots, delete this note.

## The panic (2026-11-13)

linux-zen 7.3.4, pulled in by the nixpkgs bump of 2026-11-11 (`20261111.d4f25a3`), panics about 1.7 s into boot, before the root LUKS volume is unlocked, so the journal has nothing. The pstore dump (`/var/lib/systemd/pstore/1794590520/001/dmesg.txt`, root only) shows:

- `BUG: kernel NULL pointer dereference, address: 0000000000000138`
- `RIP: process_one_work+0xb5`, called from `bh_worker` via `tasklet_action` in `ksoftirqd/15`
- the crash happens right after `xhci_hcd 0000:02:00.0` registers its USB 3.1 bus

`linuxPackages_latest` 7.3.4 boots fine on the same machine with the same kernel parameters, so the bug is in zen's patches, not mainline 7.3.4 (tested by the user, 2026-11-13).
