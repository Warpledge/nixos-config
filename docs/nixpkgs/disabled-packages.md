# Packages disabled after a nixpkgs update

Packages switched off because they stopped building after a flake update. Add a row when one gets disabled, and delete it once the package is back on.

| Package | Disabled in | Date | Broken at nixpkgs | Reason |
| --- | --- | --- | --- | --- |
| REAPER | `audio.reaper = false` in both `settings.nix` files | 2026-10-03 | `c59305b` (2026-10-01), last good `e158d9e` (2026-09-26); still broken at `151fa4e` (2026-10-06) | REAPER itself builds; its SWS and ReaPack extensions fail on GCC 16. ReaPack: `implicit capture of 'this' via '[=]' is deprecated in C++20` under `-Werror=deprecated`. SWS: `g_actions` in `BR_ContextualToolbars.cpp` is a non-literal `constexpr` |

## Checking whether a fix has landed

Run `nixm flake-update` first, so the checks below look at the new nixpkgs revision.

**Free packages** (GOverlay): if Hydra built the package, it's in the binary cache. Once `path-info` prints the path instead of `is not valid`, the build is fixed:

```bash
nix path-info --store https://cache.nixos.org "$(nix eval --raw --inputs-from . nixpkgs#goverlay)"
```

**Unfree packages** (REAPER): Hydra doesn't build unfree software, so a cache miss says nothing about them. Turn the toggle back on and run `nixm dryrun` instead.
