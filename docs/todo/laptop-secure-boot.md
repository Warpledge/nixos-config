# Secure Boot on the laptop

**Goal:** boot the laptop with Secure Boot on, using Lanzaboote and our own keys, then decide whether the desktop follows.

Added 2026-10-16.

## Why

Both hosts encrypt their root partition with LUKS, but systemd-boot, the kernel and the initrd on the ESP are unsigned. Someone with the laptop in hand could swap the initrd for one that records the LUKS passphrase. With Secure Boot on and a firmware password set, the firmware refuses any loader or kernel image not signed with our keys. Signing happens at rebuild time, so nothing costs anything at runtime.

The laptop goes first because the desktop has other EFI loaders in its boot order besides systemd-boot, and each would need signing with our keys or removing. The laptop's boot entries haven't been checked yet.

## What's already in the repo

- `modules/nixos/system/bootloader.nix` — systemd-boot with `configurationLimit = 10` and `consoleMode = "max"`, plus `sbctl`, `efibootmgr` and `refind` in `environment.systemPackages` on both hosts.
- `modules/nixos/security/hardening/default.nix` — `boot.loader.systemd-boot.editor = lib.mkDefault false`.
- No `lanzaboote` flake input yet.
- The CachyOS kernel both hosts run is built without `CONFIG_MODULE_SIG` and without the lockdown LSM (`/proc/config.gz` on the desktop, 2026-10-15), so Secure Boot won't stop out-of-tree modules such as v4l2loopback or the laptop's NVIDIA driver from loading.

## Steps left

1. **Check the laptop's boot entries.** Run `efibootmgr` and `bootctl status` there. Anything besides systemd-boot (rEFInd, another OS) gets signed with `sbctl sign` or leaves the boot order before step 6.
2. **Create the keys.** `sudo sbctl create-keys` writes them to `/var/lib/sbctl`, root-only and outside the repo (rule 4). Copy that directory somewhere offline; without it, new generations can't be signed and the keys have to be enrolled again.
3. **Add Lanzaboote for the laptop only.** Add the input (`github:nix-community/lanzaboote/v1.2.0`, with `inputs.nixpkgs.follows = "nixpkgs"` as upstream recommends) and import `lanzaboote.nixosModules.lanzaboote`. On the laptop, set `boot.loader.systemd-boot.enable = lib.mkForce false` and `boot.lanzaboote = { enable = true; pkiBundle = "/var/lib/sbctl"; }`. Decide where the switch lives: a `secureBoot.enable` toggle in both `settings.nix` files, which then joins the deliberate desktop/laptop difference list in `CLAUDE.md`, or `hosts/laptop/default.nix` directly. The current systemd-boot settings carry over: Lanzaboote's `configurationLimit` defaults to systemd-boot's, and its `settings` default takes `console-mode` and `editor` from the systemd-boot options.
4. **Rebuild and verify.** After `nixm rebuild`, `sudo sbctl verify` should list the files under `EFI/Linux/` as signed. Files starting with `kernel-` showing as unsigned is expected.
5. **Put the firmware in Setup Mode.** Reset Secure Boot to Setup Mode in the firmware's security settings. Don't use an option that clears every key: that also wipes the forbidden-signature database (dbx).
6. **Enroll the keys.** `sudo sbctl enroll-keys --microsoft`. Keep `--microsoft`: some option ROMs are signed with Microsoft's keys, and a GPU whose option ROM fails the check can come up with no picture before the OS loads. Then check that `/sys/firmware/efi/efivars/dbx-*` isn't empty.
7. **Turn Secure Boot on and reboot.** `bootctl status` should report `Secure Boot: enabled (user)`.
8. **Set a firmware supervisor password**, or anyone can switch Secure Boot back off.
9. **Desktop, later.** Only after the laptop has run this for a while, and once the desktop's other loaders are signed or gone.

## Useful info

- **Way back.** If a step leaves the laptop unbootable, switching Secure Boot off in the firmware lets the unsigned loaders boot again.
- **fwupd.** With `services.fwupd.enable` on (set in `services/desktop.nix`), the Lanzaboote module signs fwupd's EFI capsule app and sets `DisableShimForSecureBoot`, so firmware updates keep working.
- **Automatic enrollment.** v1.2.0 also has `autoGenerateKeys.enable` and `autoEnrollKeys.enable`, which create the keys and have systemd-boot enroll them on the next boot while the firmware is in Setup Mode. Microsoft keys are included by default, and an assertion refuses to build without them unless `allowBrickingMyMachine` is set. The manual steps are easier to check one at a time.
- **TPM unlock.** `measuredBoot` and `measuredBoot.autoCryptenroll` can bind LUKS unlocking to the TPM through systemd-pcrlock. That's a separate decision; with measured boot on, `configurationLimit` must be 4 or less.

## Sources

- Lanzaboote v1.2.0, released 2026-09-26: https://github.com/nix-community/lanzaboote/releases/tag/v1.2.0
- Setup steps: `docs/getting-started/prepare-your-system.md` and `docs/getting-started/enable-secure-boot.md` in that repo
- Option defaults and assertions: `nix/modules/lanzaboote.nix` at v1.2.0
- Option ROMs and `--microsoft`: https://github.com/Foxboron/sbctl/wiki/FAQ#option-rom
