---
name: apparmor-check
description: Compile-test this repo's AppArmor profiles before handing back. Use after adding or editing anything under shared/modules/nixos/security/apparmor/ (a profile, an abstraction, a toggle gate), when moving a profile from complain to enforce, or when the user asks whether the AppArmor profiles are valid. nix flake check does not parse profiles; this does.
---

# AppArmor check

`nix flake check` builds the module but never parses the profile text, so a missing comma
or a bad rule only shows up at boot, when `apparmor.service` fails to load the policy.
This compiles every policy the host defines with `apparmor_parser`, without loading
anything into the kernel, so no root is needed.

## Run it

```bash
bash <skill-dir>/scripts/check.sh desktop   # or: laptop
```

- `git add` new profile files first; the flake ignores untracked files.
- Each policy prints `ok` or `FAIL` with the parser's message; exit code 1 on any failure.
- Check both hosts when a toggle gates the profile (`media.mpv`, `office.obsidian`, …),
  since a host with the toggle off doesn't build that profile at all.

## Before and after

- New profiles start in `complain` mode, attach by store-path glob
  (`/nix/store/*-mpv-*/bin/mpv`), and never attach to a binary Nix builds also run
  (unzip, tar). The router is `apparmor/default.nix`.
- A clean compile says nothing about whether the rules are *enough*. Reading
  `apparmor="ALLOWED"` log lines, the enforce procedure and the known gaps (launched apps
  inherit the profile, conflicting exec modifiers) are in `docs/security/apparmor.md`;
  read it before switching anything to `enforce`.
