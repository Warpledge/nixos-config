# GTO 0.6.0

Client instance: `GregTech.Odyssey-0.6.0-dev33` (Prism Launcher, CurseForge import,
rebuilt by hand on 2026-11-20, [mods.md](./mods.md#dev-33-remake-2026-11-20))
Path: `~/.local/share/PrismLauncher/instances/GregTech.Odyssey-0.6.0-dev33/minecraft/`
World: a new one, not yet created (2026-11-20). The dev27 world stays on the laptop
server ([server.md](./server.md)), built from `GregTech.Odyssey-0.6.0-dev27-old`

Minecraft 1.20.1, Forge 47.4.29. The dev33 manifest lists 148 CurseForge files, and the
zip's overrides add 4 more jars (GTOCore, gto-seal-runtime, ExtendedAE and DataSyncLib).
dev27 had 153 files on Forge 47.4.20.

0.6.0 is a development build. The dev27 release notes (read 2026-11-07) warn of
crashes, corrupted saves and progress blockers, and give no changelog. A world started on
0.6 is the only way to get the rule set in [difficulty-rules.md](./difficulty-rules.md),
which is why this world runs on a dev build instead of waiting for beta.

## Sub-Notes

- [java-and-launch.md](./java-and-launch.md): Java, Prism's JVM args and memory
- [difficulty-rules.md](./difficulty-rules.md): the Custom preset, every rule changed and why
- [mods.md](./mods.md): the jars added by hand
- [shaders.md](./shaders.md): the 1.20.1 Eclipse edit, Chroma Patch and the generated
  GT PBR pack
- [candidates.md](./candidates.md): the Cosmic Frontiers mods sorted by risk for trials
- [structure-spacing.md](./structure-spacing.md): Structurify's overlap prevention and
  spacing tiers, and how to fit a new structure mod in
- [quests.md](./quests.md): how far the quest book goes
- [internals/](./internals/index.md): what GTO's own jars, forks, mixins and rules
  change, and the checklist for a new mod
- [server.md](./server.md): the dedicated server on the laptop, built with `gto server`
- [updating.md](./updating.md): new builds, mod trials and debugging through a staging
  instance, with the test checklist
- [../tools/](../tools/): `gto.py` (backup, stage, carry, diff, check, map) and
  `overlay.json`, what you add on top of the pack; `gregify.py` and `libgate.py`, which
  write the recipe, ban and structure files; `structures.py`, which lists structure
  sets and writes Structurify's config; `quarkblocks/`, the Quark block jar;
  `pbrpack.py`, the GT PBR resource pack

## Sources

- [0.6 guide](https://gtodyssey.com/articles/en/c1f8b283-dbe1-433f-aaaf-ec023e90379f)
- [Rules guide](https://gtodyssey.com/articles/en/cdc6dab6-7923-5774-993d-1e7e9d02c305)
- `flame/manifest.json` in the instance, for the file count and loader
