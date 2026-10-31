# Packages disabled after a nixpkgs update

Packages switched off because they stopped building after a flake update. Add a row when one gets disabled, and delete it once the package is back on.

| Package | Disabled in | Date | Broken at nixpkgs | Reason |
| --- | --- | --- | --- | --- |
| sbomnix | dropped from `environment.systemPackages` in `modules/nixos/security/hardening/default.nix` | 2026-10-20 | `ac6b216` (python3.14.7) | python314Packages.sqliteschema fails to build, breaking sbomnix's dependency chain (sqliteschema → SimpleSQLite → df-diskcache) |

## Pinned ahead

Packages overridden to a newer upstream release than nixpkgs has. Delete the override and the row once nixpkgs ships that version or newer.

| Package | Override in | Date | Pinned to | nixpkgs had | Why |
| --- | --- | --- | --- | --- | --- |
| llama-cpp (and llama-cpp-vulkan) | overlay in `modules/nixos/nix/nixpkgs.nix` | 2026-10-31 | v0.8.0 | 0.7.0 (build 11669) | Flint models (`flint` architecture) need v0.8.0; llama-swap and Omni Settings' Local Models test run it. Builds from source |

Check what nixos-unstable has without updating the flake:

```bash
curl -s https://raw.githubusercontent.com/NixOS/nixpkgs/nixos-unstable/pkgs/by-name/ll/llama-cpp/package.nix | grep 'version = '
```

## Checking whether a fix has landed

`nixm check-updates` (or Pinned Versions on Omni Settings' Maintenance page) runs the free-package check below for every row against nixos-unstable's head, without updating the flake. Omni Settings' Disabled Packages page checks one row at a time and turns a fixed package's switch back on, when its "Disabled in" cell names one as `` `a.b = false` in `users/<name>/settings.nix` ``; the row goes once that rebuild works.

Run `nixm flake-update` first, so the checks below look at the new nixpkgs revision.

**Free packages** (GOverlay): if Hydra built the package, it's in the binary cache. Once `path-info` prints the path instead of `is not valid`, the build is fixed:

```bash
nix path-info --store https://cache.nixos.org "$(nix eval --raw --inputs-from . nixpkgs#goverlay)"
```

**Unfree packages** (REAPER): Hydra doesn't build unfree software, so a cache miss says nothing about them. Turn the toggle back on and run `nixm dryrun` instead.
