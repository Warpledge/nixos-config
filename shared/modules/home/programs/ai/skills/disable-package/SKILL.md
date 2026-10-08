---
name: disable-package
description: Switch off, or back on, a package that a flake/nixpkgs update broke in this NixOS repo, and keep docs/nixpkgs/disabled-packages.md in step. Use when a rebuild or flake update fails on one package, when the user says an app broke after updating, asks to temporarily disable an app, or asks whether a disabled package is fixed yet.
---

# Disable or re-enable a package

The record lives in `docs/nixpkgs/disabled-packages.md`; read it first, since its
"Checking whether a fix has landed" section is how re-enabling starts.

## Disabling

1. **Pin down the failure**: the failing derivation and why, from the build error or
   `nix log <drv>`. Note the nixpkgs revision it broke at and the last good one if known.
   The lock has several nixpkgs nodes (other inputs' copies), so resolve the root input's:
   ```bash
   nix flake metadata --json | jq -r '.locks as $l | $l.nodes[$l.nodes.root.inputs.nixpkgs].locked
     | "\(.rev[0:7]) (\(.lastModified | todate | .[0:10]))"'
   ```
2. **Switch it off the least invasive way**:
   - The app has a hostConfig toggle: set it to `false` in **both**
     `hosts/{desktop,laptop}/settings.nix` with a short trailing comment saying why,
     e.g. `reaper = false; # broken in nixpkgs c59305b, see disabled-packages.md`.
   - No toggle (a plain package list entry): drop it from that list and leave everything
     else in the module alone.
   - Don't comment the package out inside its module; the toggle is the switch.
3. **Add a row** to the table: Package | Disabled in (the exact place, e.g. `audio.reaper =
   false` in both `settings.nix` files) | Date (absolute, YYYY-MM-DD) | Broken at
   nixpkgs (short rev and date, plus last good) | Reason (the actual error, not "broke").
4. `alejandra .` → `nix flake check`, hand back for the rebuild.

## Re-enabling

1. After `nixm flake-update`, check per the note: a **free** package is fixed once
   `nix path-info --store https://cache.nixos.org <its out path>` prints a path; an
   **unfree** one isn't built by Hydra, so flip it back on and try `nixm dryrun` (ask the
   user to run it).
2. When it builds, undo step 2, **delete** its table row, and check. If it still fails,
   update the row's revision and reason instead of guessing.
