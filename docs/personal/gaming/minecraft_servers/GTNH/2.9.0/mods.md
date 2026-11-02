# GTNH 2.9.0 Added Mods

The hand-added mods, checked against the 2.9.0 pack on 2026-11-01. Descriptions of what
each mod does are in the [2.8.4 write-ups](../2.8.4/mods.md); this page records which
build to use and what changed.

`Side`: **B** goes on client and server, **C** is client only.

## Shipped by 2.9.0 now

Do not add these: the pack carries its own copy.

| Mod | Pack version | Note |
| --- | --- | --- |
| Extreme Sound Muffler Legacy | 1.1.1 | Was `esm-legacy-1.0.13` by hand in 2.8.4 |
| FalsePatternLib | 1.12.2 | Was `1.10.7` by hand in 2.8.4, as a LagGoggles dependency |

## Carry over, 2.9 build exists

| Mod | 2.9 build | Side | Evidence |
| --- | --- | --- | --- |
| GT: Not Leisure (GTNL) | 0.2.7-rc2.1 | B | README: 2.9.0 needs `0.2.7+` |
| GTNHRates | 1.12.0-2.9 | B | release tag, 2026-11-01 |
| Twist Space Technology | 0.8.0-RC2.9 | B | release tag, 2026-10-27 |
| 123Technology | 2.2.0.1 | B | built against `2.9.0-RC-2` |
| EZMiner | 6.2 | B | built against `2.9.0-beta-3` |
| EZNuclear | 1.1.1 | B | README table: 2.9+ uses 1.0.8 to 1.1.1 |
| EZStorage | 1.8.2 | B | builds against GTNHLib 0.11.52, NEI 2.8.158 |
| Programmable Hatches | 0.2.1p2-beta | B | builds against GTNHLib 0.11.54, NEI 2.8.171 |
| NH-Utilities | 1.7.0 | B | commit "Fit 29x" |
| ModernKeyBinding | 2.1.0 | C | no GT API use |
| MineMenu | 1.2.0 | C | unchanged since 2.8.4 |
| Spark | 1.10.19 | C | 2.9 no longer ships it |
| BetterSprinting | 1.1.3 | B | no GT API use |
| deconfigintegration | 1.0.2 | B | no GT API use |
| FPS Reducer | 1.10.3 | C | no GT API use |
| Trash Slot | 1.0.31 | B | no GT API use |
| ElytraMining | 1.2.0.1 | B | last release 2023, no GT API use |

## Left out until their author ships a 2.9 build

- **AE2Things 1.2.14**: built against 2.8.4's AE2 `rv3-beta-695`, `AE2FluidCraft 1.4.120`
  and `ae2stuff`, which 2.9 removed. AE2 was unified for items, fluids, gasses and
  essentia, so the mod's internals do not match the pack.
- **BoxPlusPlus 2.1.2**: last release 2025-12-10, built against Galaxy Space 1.1.121.
  It sits on GT multiblock internals, which 2.9 rewrote across more than fifty machines.

Check these two again after their next release; neither has a 2.9 branch.

## In, but untested on 2.9

Install them, and pull any one that crashes or misbehaves on the first launch.

- **SharedProspecting 2.0.4**: built against GTNHLib 0.9.0, pack has 0.11.54.
- **LagGoggles 4.17.0**: built against FalsePatternLib 1.10.7, pack has 1.12.2.
- **Distant Horizons preview8** (`upstream-preview8-rple-biomes`): needs Angelica 2.1.12+;
  the pack ships 2.2.43, newer than the build names.
- **Dynamic Surroundings 1.0.7.7** and **Sound-Physics 1.1.1**: mix into rendering and
  audio, which moved to Celeritas.
- **Euphoria Patcher 1.8.6**: shader support changed with the renderer.

## Found in the instance but missing from the 2.8.4 notes

Both were installed by hand and neither appeared in `mods.md`:

- **Waystones 1.0.12**: the `xpBaseCost=-1` tweak in `config-tweaks.md` belongs to it.
  Not shipped by 2.9, so keep it if the teleport network is wanted.
- **Euphoria Patcher**: shader patch layer, covered only in `shaders.md`.

## Mod configs

The per-mod settings for GTNL, GTNHRates, EZNuclear and NH-Utilities are in
[config-tweaks.md](./config-tweaks.md#added-mod-configs). They have to be re-created in
the 2.9 instance because the mods start with their defaults.
