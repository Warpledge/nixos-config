# GTO 0.6.0

Client instance: `GregTech.Odyssey-0.6.0-dev27` (Prism Launcher, CurseForge import)
Path: `~/.local/share/PrismLauncher/instances/GregTech.Odyssey-0.6.0-dev27/minecraft/`
World: the laptop server's ([server.md](./server.md)), with the Custom preset. The
client's `New Worldaa` and the later test worlds were deleted by 2026-11-08

Minecraft 1.20.1, Forge 47.4.20. The dev27 manifest lists 153 CurseForge files, and the
zip's overrides add 4 more jars (GTOCore, ExtendedAE, DataSyncLib and Botania).

0.6.0 is a development build. The dev27 release notes (read 2026-11-07) warn of
crashes, corrupted saves and progress blockers, and give no changelog. A world started on
0.6 is the only way to get the rule set in [difficulty-rules.md](./difficulty-rules.md),
which is why this world runs on a dev build instead of waiting for beta.

## Sub-Notes

- [java-and-launch.md](./java-and-launch.md): Java, Prism's JVM args and memory
- [difficulty-rules.md](./difficulty-rules.md): the Custom preset, every rule changed and why
- [mods.md](./mods.md): the six jars added by hand
- [candidates.md](./candidates.md): the Cosmic Frontiers mods sorted by risk for trials
- [structure-spacing.md](./structure-spacing.md): Structurify's overlap prevention and
  spacing tiers, and how to fit a new structure mod in
- [quests.md](./quests.md): how far the quest book goes
- [server.md](./server.md): the dedicated server on the laptop, built with `gto server`
- [updating.md](./updating.md): new builds, mod trials and debugging through a staging
  instance, with the test checklist
- [../tools/](../tools/): `gto.py` (backup, stage, carry, diff, check) and
  `overlay.json`, what you add on top of the pack; `gregify.py` and `libgate.py`, which
  write the recipe, ban and structure files; `structures.py`, which lists structure
  sets and writes Structurify's config; `quarkblocks/`, the Quark block jar

## Sources

- [0.6 guide](https://gtodyssey.com/articles/en/c1f8b283-dbe1-433f-aaaf-ec023e90379f)
- [Rules guide](https://gtodyssey.com/articles/en/cdc6dab6-7923-5774-993d-1e7e9d02c305)
- `flame/manifest.json` in the instance, for the file count and loader
