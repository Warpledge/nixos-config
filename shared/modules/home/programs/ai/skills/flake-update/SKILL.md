---
name: flake-update
description: Update this NixOS repo's flake inputs (all, or named ones) and bring the repo to a state the user can rebuild - this host built without activation, failures fixed or switched off, version diff, disabled packages rechecked - then hand back the exact rebuild command. Run only when the user asks.
disable-model-invocation: true
---

# Flake update

Covers what `nixm upgrade` would do, minus the rebuild: CLAUDE.md rule 1 keeps
`nixm rebuild`, `nixm boot` and `nixos-rebuild` with the user. Arguments, if given, are
input names (`/flake-update nixpkgs`); none means every input.

## 1. Update

```bash
git status --porcelain flake.lock   # must be clean, so the diff below is only this update
nix flake update [<input>...]
git diff --stat flake.lock
```

Note the root nixpkgs revision before and after (the lock holds other inputs' nixpkgs
copies too, so resolve the root one):

```bash
nix flake metadata --json | jq -r '.locks as $l | $l.nodes[$l.nodes.root.inputs.nixpkgs].locked
  | "\(.rev[0:7]) (\(.lastModified | todate | .[0:10]))"'
```

## 2. Build

`nix flake check` first (evaluation only, fast). Then build the host you're running on
(`hostname`) directly; build the other one only if the user asked for it:

```bash
nix build ".#nixosConfigurations.$(hostname).config.system.build.toplevel" \
  --no-link --print-out-paths --keep-going 2>&1 | tail -n 3
```

A success prints the out path as its last line. On a failure, don't read the log here:
hand the host to the `build-triager` agent, which returns each root failure with its
class and route. A clean update never starts it, since each agent costs ~26k tokens
just to start.

Fix failures by route, then rebuild that host until it builds:

- moku, `pnpmHash` or `vendorHash`: the `moku-bump` skill. A nixpkgs bump that touches
  the pnpm or Go fetchers makes these hashes stale with no Moku change.
- an upstream package broken at the new nixpkgs: the `disable-package` skill, recording
  the revision from step 1.
- anything else: fix it if the cause is in this repo; otherwise stop and report it.

## 3. Boot or switch

Diff the new build against the live system:

```bash
bash <skill-dir>/scripts/diff.sh <out path from step 2>
```

It prints the version changes and a verdict: `nixm boot` when glibc, systemd, niri or
xwayland-satellite changed (live switches froze the desktop on a new glibc/systemd on
2026-10-03 and on a new xwayland-satellite on 2026-10-07), else `nixm rebuild`.

## 4. Recheck disabled packages

Skip this when the root nixpkgs revision didn't move in step 1: nothing can have been
fixed. Otherwise, for each row in `docs/nixpkgs/disabled-packages.md`, follow its
"Checking whether a fix has landed" section. For an unfree package, build the package
itself (`NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link --inputs-from . nixpkgs#<pkg>`)
plus anything the module adds alongside it (REAPER's SWS and ReaPack extensions),
instead of asking for `nixm dryrun`. Re-enable what now builds (the `disable-package`
skill's Re-enabling steps); for what still fails, update the row's revision and reason.

## 5. Hand back

`alejandra .` → `nix flake check`, then report: inputs that moved (old → new rev), the
version changes that matter, anything fixed or disabled, recheck results, and the command
to run (`nixm boot` or `nixm rebuild`) from step 3. Don't commit; the user runs the
`commit` skill when they want one.
