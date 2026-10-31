# Packages disabled after a nixpkgs update

Packages switched off because they stopped building after a flake update. Add a row when one gets disabled, and delete it once the package is back on.

| Package | Disabled in | Date | Broken at nixpkgs | Reason |
| --- | --- | --- | --- | --- |
| sbomnix | dropped from `environment.systemPackages` in `modules/nixos/security/hardening/default.nix` | 2026-10-20 | `ac6b216` (python3.14.7) | python314Packages.sqliteschema fails to build, breaking sbomnix's dependency chain (sqliteschema → SimpleSQLite → df-diskcache) |

## Checking whether a fix has landed

`nixm check-updates` (or Pinned Versions on Omni Settings' Maintenance page) runs the free-package check below for every row against nixos-unstable's head, without updating the flake.

Run `nixm flake-update` first, so the checks below look at the new nixpkgs revision.

**Free packages** (GOverlay): if Hydra built the package, it's in the binary cache. Once `path-info` prints the path instead of `is not valid`, the build is fixed:

```bash
nix path-info --store https://cache.nixos.org "$(nix eval --raw --inputs-from . nixpkgs#goverlay)"
```

**Unfree packages** (REAPER): Hydra doesn't build unfree software, so a cache miss says nothing about them. Turn the toggle back on and run `nixm dryrun` instead.
