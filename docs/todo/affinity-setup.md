# Set up Affinity on NixOS

**Goal:** get Affinity v3 (Photo, Designer and Publisher in one app, run under Wine) installed and usable on the desktop, then decide whether the laptop gets it too.

Added 2026-10-07.

## What's already in the repo

The wiring went in with commit `4d1a513` (2026-05-19), but the toggle has been `false` on both hosts ever since, so it has never been built or run here.

- `flake.nix` — `affinity-nix` input (`github:mrshmllow/affinity-nix`), deliberately not following our nixpkgs so its builds match upstream's binary cache. Pinned at `11312af` (2026-09-28) as of this note.
- `modules/nixos/nix/nixpkgs.nix` — applies `inputs.affinity-nix.overlays.default`, which provides `pkgs.affinity-v3`.
- `modules/home/programs/graphics/affinity.nix` — puts `affinity-v3` in `home.packages`.
- `modules/home/programs/default.nix` — imports that module when `hostConfig.graphics.affinity` is set.
- `hosts/{desktop,laptop}/settings.nix` — `graphics.affinity = false`.
- `README.md` — already lists Affinity in the Graphics row and the flake inputs table.

`nix eval .#nixosConfigurations.desktop.pkgs.affinity-v3.name` returned `Affinity-v3` on 2026-10-07, so the overlay still evaluates.

## Steps left

1. **Binary cache.** Upstream's README asks users to add `cache.forall.systems` as a substituter so the Wine build isn't compiled locally. `substituters.nix` doesn't have it; it only carries a commented-out `cache.garnix.io` entry (and its key) from before upstream switched caches. Add `https://cache.forall.systems` plus its public key from https://cache.forall.systems/ (copy the key from that page, don't guess it), and drop the garnix lines.
2. **Flip the toggle** to `true` in `hosts/desktop/settings.nix`, then `alejandra .` and `nix flake check`, and rebuild.
3. **First run.** Launch `affinity-v3` and sign in or activate. User data lands in `~/.local/share/affinity-v3/` (the Wine prefix itself is in the store, overlaid at runtime).
4. **Laptop.** Decide whether to enable it there too. If not, it becomes one more line in the deliberate desktop/laptop difference list in `CLAUDE.md`.
5. **Theming.** Check whether Stylix leaves the app alone. It's a Windows app under Wine, so there's probably no theming target to enable.

## Useful info

- **Overlayfs.** The wrapper mounts the store prefix with overlayfs inside an unprivileged user namespace and falls back to `fuse-overlayfs` (slower) if the kernel refuses. Our hardening doesn't currently restrict user namespaces (no `security.allowUserNamespaces = false` or `unprivileged_userns_clone` sysctl in `security/hardening/kernel.nix`), so the fast path should work. Re-check this if the hardening changes or the app is slow to start.
- **AppArmor.** No profile exists for it. If one is added later it needs `userns` permission, like the Obsidian profile in `security/apparmor/obsidian.nix`.
- **Troubleshooting.** The wrapper exposes Wine tools inside its sandbox: `affinity-v3 wine winecfg`, `affinity-v3 winetricks`, `affinity-v3 wineboot`, `affinity-v3 --verbose`. Upstream points at https://affinity.liz.pet/v2/misc-troubleshooting/ for fixes.
- **Bugs.** Upstream warns Affinity under Wine is buggy; issues go to https://github.com/mrshmllow/affinity-nix/issues.

## Sources

- affinity-nix README at `11312af`: https://github.com/mrshmllow/affinity-nix
- Commit `4d1a513` in this repo
