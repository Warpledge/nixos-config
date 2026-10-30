# Packages disabled after a nixpkgs update

Packages switched off because they stopped building after a flake update. Add a row when one gets disabled, and delete it once the package is back on.

| Package | Disabled in | Date | Broken at nixpkgs | Reason |
| --- | --- | --- | --- | --- |
| sbomnix | dropped from `environment.systemPackages` in `modules/nixos/security/hardening/default.nix` | 2026-10-20 | `ac6b216` (python3.14.7) | python314Packages.sqliteschema fails to build, breaking sbomnix's dependency chain (sqliteschema → SimpleSQLite → df-diskcache) |
| sesh | dropped from `home.packages` in `modules/home/programs/shell/zsh.nix` (the `sesh-sessions` widget and its `Alt+S` binds stay) | 2026-10-12 | `6510408` (2026-10-10), last good `e7439b6` (2026-10-08); still broken at `7fd4004` (2026-10-11) | sesh 2.32.0 builds with `buildGo127Module` and runs `mockery` in `preBuild`, with go-mockery 3.8.0 overridden to Go 1.27. mockery can't read Go 1.27 export data: `could not import context (... cannot decode "context", export data version 5 is greater than maximum supported version 4)`, so its `test.ci` checks fail and sesh's build would hit the same error |
| typescript-language-server | dropped from `home.packages` in `modules/home/programs/editors/zed.nix` (Helix's `typescript-language-server` LSP config stays and finds no binary) | 2026-10-12 | `7fd4004` (2026-10-11), last good `6510408` (2026-10-10) | 6.0.2's pnpm deps fail as a fixed-output derivation: `hash mismatch in fixed-output derivation '...-typescript-language-server-pnpm-deps.drv'` |

## Checking whether a fix has landed

`nixm check-updates` (or Omni Settings' Updates page) runs the free-package check below for every row against nixos-unstable's head, without updating the flake.

Run `nixm flake-update` first, so the checks below look at the new nixpkgs revision.

**Free packages** (GOverlay): if Hydra built the package, it's in the binary cache. Once `path-info` prints the path instead of `is not valid`, the build is fixed:

```bash
nix path-info --store https://cache.nixos.org "$(nix eval --raw --inputs-from . nixpkgs#goverlay)"
```

**Unfree packages** (REAPER): Hydra doesn't build unfree software, so a cache miss says nothing about them. Turn the toggle back on and run `nixm dryrun` instead.
