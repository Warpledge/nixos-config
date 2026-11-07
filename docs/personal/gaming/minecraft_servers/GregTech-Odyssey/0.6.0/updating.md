# GTO 0.6.0 Updating, Trials and Debugging

Dev builds come out often and can corrupt saves, so nothing new reaches the real world
(`New Worldaa` in `GregTech.Odyssey-0.6.0-dev27`) before it has passed in a copy. The
copy is a staging instance, and [tools/gto.py](../tools/gto.py) does the copying,
carrying and checking. Run it with the game closed:

```bash
alias gto='python3 -I /etc/nixos-config/docs/personal/gaming/minecraft_servers/GregTech-Odyssey/tools/gto.py'
```

| Command | Does |
| --- | --- |
| `gto backup <inst>` | Copies the whole instance to `~/Documents/Minecraft_Servers/GTO-backups/<inst>-<date>/` |
| `gto stage <inst>` | Clones it, world included, to `<inst>-staging` (`--replace` backs up and redoes an old one). Prism must be closed |
| `gto carry <old> <new>` | Copies your jars, files and Java settings from [overlay.json](../tools/overlay.json) into a new build; `--saves` copies the worlds too |
| `gto diff <old> <new>` | Mods added, removed or updated, your jars the pack now ships, and every config file that changed |
| `gto check <inst>` | Errors in `logs/latest.log` that the instance's baseline lacks, plus mixin, dependency and load failures and crash reports. Exits 1 on findings |
| `gto check <inst> --save-baseline` | Records this log's errors as normal for the instance |

Every writing command takes `-n` to print what it would do. `<inst>` is a folder name
under Prism's `instances/` or a path.

## The baseline

A normal dev27 session logs about 140 ERROR lines (EventBus transformer noise, Curios
slot warnings, Distant Horizons' hanging entities), so a raw grep shows nothing useful.
`check` reduces each ERROR and FATAL line to a signature, with numbers, coordinates and
hex stripped, and reports only signatures the baseline lacks. Save a baseline after a
session you're happy with; it lives in the instance as `gto-baseline.txt`, so `stage`
copies it. `--against <inst>` compares with another instance's baseline, such as the old
build's after an update.

## Test checklist

After each launch of a new build or trial:

1. Create a new world for the test (every trial gets its own), or load the copied one
   for a new build.
2. Open the quest book and EMI.
3. Open a running GT multiblock and the AE2 terminal.
4. Fly into unexplored chunks for a minute (worldgen and Distant Horizons).
5. Save and quit, relaunch, and load the world again.
6. Quit and run `gto check`.

A fresh world matters most for worldgen mods, since chunks that already exist never get
their features. A new world's first launch logs `Configuration file ... is not correct.
Correcting` for each server config Forge fills in; that's normal.

## A new dev build

1. `gto backup GregTech.Odyssey-0.6.0-dev27` (use the current main instance's name).
2. Import the new zip into Prism as a new instance. Never unzip it over the old one.
3. Close Prism, then `gto carry <main> <new> --saves`. Where the pack's copy of a
   carried file differs, carry keeps it as `<file>.pack-new`, so a new build's new options
   in `gtocore-rules.txt` can be read before deleting it.
4. `gto diff <main> <new>` and read it. `!` lines are your jars that the pack now ships.
   Take them out of `overlay.json` and [mods.md](./mods.md).
5. Launch the new instance, run the checklist, then `gto check <new> --against <main>`.
6. If it's clean, the new instance becomes main: `gto check <new> --save-baseline`, and
   update the instance name in this note and [index.md](./index.md). The world's rules
   stay locked in it, so check View Rules once.
7. Keep the old instance until you've had two good sessions on the new one.

## A mod trial

One mod at a time, or a small batch from one section of
[candidates.md](./candidates.md):

1. `gto stage <main>` (`--replace` if an old staging copy is there).
2. Add the jars and the libraries they need to the staging instance's `mods/`.
3. Launch it, run the checklist and `gto check`.
4. If it passes, add the same jars to main, add an entry to `overlay.json` (jar, modId,
   name, source URL, date added), and note it in [mods.md](./mods.md). After main's next
   clean session, save the baseline again.
5. If it fails, nothing in main changed: delete the jars from staging, or the whole
   staging copy.

## Debugging

Debug in staging, not main. Copy the failing state first with `gto stage --replace`.

- `gto check` names new errors. Search each signature's logger and mod name, and read
  `crash-reports/` for a crash.
- Disable a jar in Prism's mod list (it renames it to `.jar.disabled`) to split the
  suspects in half, then relaunch and check again.
- To test against a clean pack, make a staging copy of a freshly imported build without
  `carry`. If the problem stays, it's the pack's; report it upstream with the log.

## Backups inside the pack

The pack ships Advanced Backups, which keeps differential and incremental sets in the
instance's `minecraft/backups/<world>/`. To restore one, run `restore-script.sh` in
`backups/` (it needs Java on `PATH` and may need `chmod +x`). These live inside the
instance, so `gto backup` is the copy that survives a broken instance.

The 0.5.6-to-0.6 migration bug, GregTech-Odyssey#2013, is fixed, but no world here was
migrated: `New Worldaa` started on 0.6.
