# Packages disabled after a nixpkgs update

Packages switched off because they stopped building after a flake update. Add a row when one gets disabled, and delete it once the package is back on.

| Package | Disabled in | Date | Broken at nixpkgs | Reason |
| --- | --- | --- | --- | --- |
| GOverlay | `goverlay` dropped from the package list in `home-manager/programs/gaming/gaming.nix` (MangoHud stays) | 2026-10-03 | `c59305b` (2026-10-01), last good `e158d9e` (2026-09-26) | Its dependency `lazarus-qt6-4.8-0` fails in `installPhase`: the stdenv refuses `--prefix NIX_LDFLAGS` because the value has an empty PATH-like segment. Full log via `nix log` on the lazarus-qt6 drv |
| REAPER | `audio.reaper = false` in both `hostConfig/core.nix` files | 2026-10-03 | `c59305b` (2026-10-01), last good `e158d9e` (2026-09-26) | Disabled by hand during the same update; reason not recorded |

## Checking whether a fix has landed

Run `nixm flake-update` first, so the checks below look at the new nixpkgs revision.

**Free packages** (GOverlay): if Hydra built the package, it's in the binary cache. Once `path-info` prints the path instead of `is not valid`, the build is fixed:

```bash
nix path-info --store https://cache.nixos.org "$(nix eval --raw --inputs-from . nixpkgs#goverlay)"
```

**Unfree packages** (REAPER): Hydra doesn't build unfree software, so a cache miss says nothing about them. Turn the toggle back on and run `nixm dryrun` instead.
