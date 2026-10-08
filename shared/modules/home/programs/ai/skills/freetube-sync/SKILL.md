---
name: freetube-sync
description: Fold channels blocked or unblocked in the FreeTube app back into this repo's declarative blocklist (blocked-channels.nix), and keep that list valid. Use when the user says they blocked more channels, asks to sync or update FreeTube, mentions the FreeTube blocklist or hidden channels, or before editing blocked-channels.nix by hand.
---

# FreeTube sync

FreeTube keeps its blocklist in `~/.config/FreeTube/settings.db`; the repo mirrors it in
`shared/modules/home/programs/media/freetube/blocked-channels.nix`. The full
reasoning is under **Update FreeTube state** in CLAUDE.md; this skill is the runnable form.

## Steps

1. **FreeTube must be closed.** It rewrites `settings.db` from memory when it exits, so a
   capture taken while it runs is stale, and a rebuild while it runs gets clobbered. Ask the
   user to quit it if `diff.sh` warns it is running.
2. **See the delta** (read-only):
   ```bash
   bash <skill-dir>/scripts/diff.sh
   ```
   It prints new entries as ready-made `(mk "UC…" "Name")` lines, plus ids only the module
   has (channels the user unblocked).
3. **Apply it**: paste the new lines anywhere inside the `channelsHidden` list, delete the
   lines for unblocked ids, then sort:
   ```bash
   bash <skill-dir>/scripts/check.sh --sort
   ```
4. **Validate**: `check.sh` (no flag) must print `ok`: no duplicate ids, every entry named,
   sorted by lowercased name under `LC_ALL=C` with the id as tie-breaker. Confirm the entry
   count moved by exactly the delta.
5. `alejandra .` → `nix flake check`, then hand back for the rebuild with FreeTube still
   closed.

Settings changes (not the blocklist) go in `settings.nix` the same way: reduce `settings.db`
with `jq -rs 'reduce .[] as $x ({}; .[$x._id] = $x.value)'` and mirror the changed keys.
Subscriptions, playlists and history are personal data and never go in this public repo;
`nixm freetube-backup` covers those.
