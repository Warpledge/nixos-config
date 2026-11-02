# GTNH 2.9.0 Added Mods

The hand-added mods, checked against the 2.9.0 pack and against each mod's releases on
2026-11-01. Descriptions of what each mod does are in the
[2.8.4 write-ups](../2.8.4/mods.md); this page records which build to use and what
changed. Every mod below was looked up on GitHub, Modrinth or CurseForge: the only one
with a newer 1.7.10 build than the 2.8.4 jar is Euphoria Patcher.

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
| ModernKeyBinding | 2.1.0 | C | latest Forge 1.7.10 on Modrinth |
| MineMenu | 1.2.0.B44 | C | latest on Modrinth, 2025-12-07 |
| Spark | 1.10.19 | C | latest 1.7.10; the `1.10.35` in the old notes was wrong |
| BetterSprinting | 2.3.0 | B | latest 1.7.10 build; 1.1.3 was five years older |
| deconfigintegration | 1.0.2 | B | no public release page found |
| FPS Reducer | 1.10.3 | C | latest, 2023-09-06 |
| Trash Slot | 1.0.31 | B | latest 1.7.10 on CurseForge |
| ElytraMining | 1.2.0.1 | B | latest, 2023, no GT API use |

## Left out until their author ships a 2.9 build

- **AE2Things 1.2.14**: built against 2.8.4's AE2 `rv3-beta-695`, `AE2FluidCraft 1.4.120`
  and `ae2stuff`, which 2.9 removed. AE2 was unified for items, fluids, gasses and
  essentia, so the mod's internals do not match the pack.
- **BoxPlusPlus 2.1.2**: last release 2025-12-10, built against Galaxy Space 1.1.121.
  It sits on GT multiblock internals, which 2.9 rewrote across more than fifty machines.

Check these two again after their next release; neither has a 2.9 branch.

## Installed, still unproven on 2.9

These are in the 2.9 instance but have no explicit 2.9 release, so a launch is the proof.

- **SharedProspecting 2.0.4**: built against VisualProspecting 1.5.11 and GTNHLib 0.9.0.
  Its six late mixins still match VP 1.5.42 as shipped in 2.9 (checked 2026-11-01); the
  team sync itself can only be proven on the server.
- **LagGoggles 4.17.0**: built against FalsePatternLib 1.10.7, pack has 1.12.2.
- **Distant Horizons `upstream-preview8-rple-biomes`** (2026-10-18): the 2.8.4 jar was
  `alpha18`; this is the newest build and the first from the 2.9 period. Enable
  Aggressive Chunk Loading under Video Settings, Performance, to stop transparent
  chunks. Known issues are unchanged: memory creep, unstable server side, and LODs that
  need a render-distance toggle to refresh.
- **Dynamic Surroundings 1.0.9.0** (2026-09-30): mist475's 1.7.10 fork, newer than the
  1.0.7.7 in the old notes; adds Seasonal Horizons compatibility.
- **Sound-Physics 1.1.1** (2026-06-27): the 1.7.10 mixin edition.
- **Euphoria Patcher 1.9.3** is installed to match the NeonTech settings. 1.10.5 exists,
  but moving to it means copying the NeonTech values by hand.

## Overlap with 2.9 changes

- **Dropped because the pack ships them**: Extreme Sound Muffler Legacy and
  FalsePatternLib. A second copy of either is a duplicate mod id; the old
  FalsePatternLib 1.10.7 would also shadow the 1.12.2 that LagGoggles and other
  FalsePattern mods load against.
- **Functionally overlapped, not in conflict**: Waystones against the ServerUtilities
  `/warp` commands this setup enables, and Spark against the pack's Opis. Keep or drop
  by preference; neither fights the other.
- **Replaced by 2.9 itself**: GTNL 0.2.7 has no Integrated Ore Factory mixin (the
  `enableIntegratedOreFactoryChange` option is gone from its config), and 2.9 gave the
  real IOF uncapped parallels that scale with EU/t.
- **Retargeted, not broken**: GTNHRates' `ic2CropsYield` key now multiplies CropsNH
  drops through `mixins/late/CropsNH.java`. The setting name is stale; the value still
  does its job.
- **Partly redundant**: Programmable Hatches' large buffer hatches overlap with 2.9's
  bus rework, which deprecated Super Buses and let regular input buses carry more than
  16 slots. Its 0.2.1 build targets 2.9, so it stays a choice rather than a conflict.

## Quest data

- **Twist-Stuff**: the repo has a "2.9 Update" commit from 2026-08-27. Copy the 2.9
  quest set into BetterQuesting, not the 2.8.4 one from the old instance.

## Found in the instance but missing from the 2.8.4 notes

Both were installed by hand and neither appeared in `mods.md`:

- **Waystones 1.0.12**: the `xpBaseCost=-1` tweak in `config-tweaks.md` belongs to it.
  Not shipped by 2.9, so keep it if the teleport network is wanted.
- **Euphoria Patcher**: shader patch layer, covered only in `shaders.md`.

## Mod configs

The per-mod settings for GTNL, GTNHRates, EZNuclear and NH-Utilities are in
[config-tweaks.md](./config-tweaks.md#added-mod-configs). They have to be re-created in
the 2.9 instance because the mods start with their defaults.
