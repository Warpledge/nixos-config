# GTO 0.6.0 Updating

Dev builds can corrupt saves, so back up before every update and never unzip a new
build over the old instance.

## Backups

The pack ships Advanced Backups. Its backups are in the instance's
`minecraft/backups/<world>/` as differential and incremental sets. To restore one, run
`restore-script.sh` in `backups/` (it needs Java on `PATH` and may need `chmod +x`).
Before an update, also copy the whole `saves/<world>/` folder somewhere outside the
instance.

## Moving to a newer build

1. Back up the world as above.
2. Import the new zip into Prism as a new instance.
3. Set Java and the JVM args from [java-and-launch.md](./java-and-launch.md).
4. Copy the six jars in [mods.md](./mods.md), `shaderpacks/`, and your edits in
   `config/` (at least `gtocore-rules.txt`, so new worlds get the same rules).
5. Copy `saves/<world>/` across and start it once. The rules stay locked in the world,
   so check View Rules afterwards.
6. Keep the old instance until the world has run on the new one.

The 0.5.6-to-0.6 migration bug, GregTech-Odyssey#2013, is fixed, but no world here was
migrated: `New Worldaa` started on 0.6.
