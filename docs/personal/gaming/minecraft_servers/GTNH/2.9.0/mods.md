# GTNH 2.9.0 Added Mods

The hand-added mods, checked against the 2.9.0 pack and against each mod's releases on
2026-11-01. This page records which build to use and what changed; the longer write-ups
of what the carried-over mods do are in `2.8.4/mods.md` in git history (see
[the GTNH index](../index.md)). Every mod below was looked up on GitHub, Modrinth or
CurseForge.

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
| Twist Space Technology | 0.8.0 | B | release 2026-11-02 includes the 2.9 fix (PR #1386) |
| 123Technology | 2.2.0.1 PR build | B | release crashes on 2.9.0 stable; use PR #269 |
| EZMiner | 6.2 | B | built against `2.9.0-beta-3` |
| EZNuclear | 1.1.1 | B | README table: 2.9+ uses 1.0.8 to 1.1.1 |
| EZStorage | 1.8.2 | B | builds against GTNHLib 0.11.52, NEI 2.8.158 |
| Programmable Hatches | 0.2.1p2-beta | B | builds against GTNHLib 0.11.54, NEI 2.8.171 |
| NH-Utilities | 1.7.0 | B | commit "Fit 29x" |
| YesSteveModel Unofficial | 1.9 | B | wiki lists 2.9.0-beta-1 to RC-2; loads on stable, 2026-11-02 |
| MineMenu | 1.2.0.B44 | C | latest on Modrinth, 2025-12-07 |
| Spark | 1.10.19 | C | latest 1.7.10 |
| FPS Reducer | 1.10.3 | C | latest, 2023-09-06 |
| Trash Slot | 1.0.31 | B | latest 1.7.10 on CurseForge |
| ElytraMining | 1.2.0.1 | B | latest, 2023, no GT API use |

**GTNL needs two jars the pack does not ship:** `gtnllib-1.1.3.jar` and
`bqapi-1.1.3.jar` (GTNLLib >= 1.1, BetterQuestingAPI >= 1.1.3). Without GTNLLib the
game stops before the main menu with `NoClassDefFoundError: com/gtnllib/mod/ModList`.
GTNLLib 1.1.1 also fails at launch on Angelica 2.2.43: its font-batch `@ModifyArg` finds
0 targets, so the font renderer cannot load. 1.1.3 changes that mixin and is the build
to use.

**123Technology still needs its unreleased PR build for 2.9.0 stable.** The published jar
crashes during init; its stable compatibility is on an open PR:

| Mod | Jar to use | Source |
| --- | --- | --- |
| 123Technology | `OTHTechnology-2.2.0.1-git.3+2b1a0b5fbd.jar` | [PR #269](https://github.com/CallmeSHaobe/123Technology/pull/269) |

Twist's tracker had the matching startup-crash report (#1390, from 2026-11-01), and the
0.8.0 release caught up on 2026-11-02: its changelog lists PR #1386 and its tag sits 11
commits past that PR's head. `TwistSpaceTechnology-0.8.0.jar` replaced the PR build on
both sides and the server loads it. Swap 123Technology back to its release once PR #269
merges. On a Twist update, reset `GregTech.lang` and `TwistSpaceTechnology.cfg` to avoid
config conflicts.

## Installed on 2.9.0 only

These are not carried from 2.8.4; they went in on top of 2.9.0 on 2026-11-02, client and
server, and the server boots with all of them next to GTNL.

| Mod | Build | Side | Note |
| --- | --- | --- | --- |
| Waystones-X | 1.0.16 | B | [JackOfNoneTrades fork](https://github.com/JackOfNoneTrades/WaystonesFork) of BlayTheNinth's mod; `config/waystones.cfg` sets `xpBaseCost=-1` |
| MIAOKATZE Core | 0.2.0 | B | required by the four Miao mods below, on both sides |
| GT-Miao-Blueprint | 0.3.0 | B | Neko Blueprint Hologram Projector: blueprint, cut and demolition modes |
| GT-Steam-Reborn | 2.1.1 | B | steam industry, hubs and nodes, singularity tech, the Prosperity dimension, portable weapons, a BQ line |
| GT-Interesting-Thing | 2.1.0 | B | float cores, rings, Neko dimensional pocket, infinity storage, coins and trading |
| GT-Simple-Wireless-Network | 2.1.0 | B | wireless EU link nodes, monitors, ME quantum terminal |

All but Waystones come from [MIAOKATZE](https://github.com/MIAOKATZE) and are tagged
"for GTNH 2.9.0 stable". Their `en_US.lang` files are complete, so the in-game text is
English; the READMEs are Chinese. GT-Miao-Blueprint needs Applied Energistics and
StructureLib, GTSWN needs AE2, the other two only GregTech. The four Miao mods overlap
GTNL in role (steam tiers, singularity tech, large storage) but share no IDs or
recipes, and the server boots with both installed. Since 2026-11-04 the GTIT starter gift
gives no rings, because Omni Tweaks covers step assist, and since 2026-11-03 123Technology's
overpowered recipes are off; the values are in
[config-tweaks.md](./config-tweaks.md#balance-edits-2026-11-03).

One more joined them later on 2026-11-02, client and server:

| Mod | Build | Side | Note |
| --- | --- | --- | --- |
| ThinkTech | 0.3.1 | B | chemistry and materials: briquettes, methane clathrate, catalysts, computing chips, explosives (PETN, HMX, HNIW), separation control cores |

TenkeiTech 1.1.0 was installed with it and removed the same day: it hands you an
"Useless Tools" staff on spawn with force kill, spawn eggs, area damage, bedrock mining
and time acceleration modes, and the AE automation it adds was not worth that. Its jar and
`config/tenkeitech.cfg` are gone from both sides and FML removed its items from the world.

Four client-side additions on 2026-11-02:

| Mod | Build | Side | Note |
| --- | --- | --- | --- |
| World Tooltips | 1.2.3 | C | floating tooltip over dropped items; no lang files, it shows the game's own item names |
| Better Line Break | 1.0.1 | C | replaces Minecraft's line wrapping; no text of its own |
| MyCTMLib | 1.4.4-290 | C | connected-texture support for resource packs |
| OmniOcular Unofficial | 1.6.0 | B | WAILA add-on showing machine internals; see the scripts note below |

Fancy Block Particles 2.4.1 was removed after its 3D block particles rendered as
screen-filling shards under Angelica and the shader pack; its `config/FBP/` folder is gone
too, so the Twilight Forest workaround went with it.

Both PICO-8 GTNH 0.4.1 and Fission-Evolved 0.1.1 are parked. With either installed
alongside the other client mods the client fails before the main menu at GregTech's
post-init, and without them the same set boots. The report hides the real error behind
`Class bytes is null for net.minecraft.item.ItemBlock`, the same masked failure the pack
shows when a mod's init exception cannot be logged, so the mod names are the only signal.
The server's copies were removed too, so the two mod lists match. PICO-8 has no mixins and
finishes its own init; Fission's baseline is 2.9.0-beta-2, the oldest of the group. Both are
worth retrying after a report upstream and before the next pack update.

OmniOcular's labels come from XML scripts, and the Chinese pack the wiki links
([CCYF78/GTNH_OmniOcular](https://github.com/CCYF78/GTNH_OmniOcular)) is fully translated
into English in `config/OmniOcular/`, on both sides: all quoted Chinese strings, display
names and script output, 194 display names plus 111 single-quoted literals. The GT script
is named `GregTech5U.xml` so the mod does not drop its own older copy beside it. Two
Chinese leftovers are harmless: comments inside the XML, and `GregTech6.xml`, which only
fires for GregorianTech 6 blocks that GTNH does not have. A pack update will not refresh
these files, so new Chinese strings would need translating again.

One mod written for this setup on 2026-11-04, client and server:

| Mod | Build | Side | Note |
| --- | --- | --- | --- |
| Omni Tweaks | 0.2.0 | B | QoL backports from modern Minecraft, so far step height 1.0 (0.5 while sneaking) and better ladder and vine climbing |

It reimplements the wanted features of Keep Stepping and Better Climbing, neither of which
has a 1.7.10 build; no code comes from them. Its climbing mixin hooks
`EntityLivingBase.moveEntityWithHeading` and only acts on the client's own player. Holding
jump in a climbable climbs up, and looking down 45° or more descends instead of climbing
when walking into a ladder. Toggles and speeds are in `config/omnitweaks.cfg`. These
features passed in-game testing on 2026-11-04, under the mod's first name, Footwork. The
source is in `~/Projects/omni-tweaks`, a local git repo built with GTNH's ExampleMod
starter; the jar is `build/libs/omnitweaks-0.2.0.jar`.

## Added on 2026-11-05

Latest 1.7.10 Forge builds from Modrinth, hashes checked. None has an explicit 2.9
release; all of them passed in-game testing on 2026-11-05.

| Mod | Build | Side | Note |
| --- | --- | --- | --- |
| World Preview NH | 1.0.3 | C | biome and height preview on Create New World |
| Vintage Pick Up Notifier | 1.0.0 | C | item pickup notices |
| Vintage Resourcify, with AngelLib 1.0.0 | 1.0.6 | C | in-game resource and shader pack browser |
| Better Search | 1.6.2 | C | typo-tolerant search, with NEI and AE2 hooks |
| Effortless Building Gadgets | 0.10.1 | B | shape building through a crafted gadget; `B:consumesEnergy=false` on both sides, so it needs no power |
| Shoulder Surfing Reloaded | 2.4.1 | C | over-the-shoulder camera; a 2023 build that patches vanilla code, so suspect it first after a pack update |

Vintage Resourcify lists `forgelin-legacy` as required. It has the same `forgelin` mod id
as the pack's `forgelin-2.0.3-GTNH.jar`, so it was left out and runs on the pack's copy.

Right Proper GUI Scale 2.1.1 is also on the client. It keeps the scale as a decimal in
`options.txt` (`guiScale:3.5`, between vanilla's 3 and 4) and applies a change when the
settings screen closes, so it can look like nothing happened. `/guiscale` sets it in game.

Neo ECO AE Extension 7.3.6 is on client and server, on trial since 2026-11-05: three
tiered AE2 multiblock systems for storage, crafting and computation, an optional upgrade
path rather than a replacement for normal AE2. 7.3.7 appeared on Modrinth that day and was
gone from its listing hours later, so 7.3.6 is the build in use, and both sides must match.
Its recipes looked in line with GTNH in NEI. Still to check: autocrafting through GT
machines alongside WTCT, and what a world loses when it's removed. The world from before it
went on the server is `~/Documents/Minecraft_Servers/World-Backups/World3-before-neoecoae-2026-11-05.tar.gz`.

## Left out until their author ships a 2.9 build

- **AE2Things 1.2.14**: built against 2.8.4's AE2 `rv3-beta-695`, `AE2FluidCraft 1.4.120`
  and `ae2stuff`, which 2.9 removed. AE2 was unified for items, fluids, gasses and
  essentia, so the mod's internals do not match the pack.
- **LagGoggles 4.17.0**: in the 2.8.4 instance only; not copied to 2.9.0. It was built
  against FalsePatternLib 1.10.7, the pack ships 1.12.2, so a launch is still the proof.
- **BoxPlusPlus 2.1.2**: last release 2025-12-10, built against Galaxy Space 1.1.121.
  It sits on GT multiblock internals, which 2.9 rewrote across more than fifty machines.

Check these again after their next release; none has a 2.9 build.

## Installed, still unproven on 2.9

These are in the 2.9 instance but have no explicit 2.9 release, so a launch is the proof.

- **SharedProspecting 2.0.4**: built against VisualProspecting 1.5.11 and GTNHLib 0.9.0.
  Its six late mixins still match VP 1.5.42 as shipped in 2.9 (checked 2026-11-01); the
  team sync itself can only be proven on the server.
- **Distant Horizons `upstream-preview8-rple-biomes`** (2026-10-18): the 2.8.4 jar was
  `alpha18`; this is the newest build and the first from the 2.9 period. Enable
  Aggressive Chunk Loading under Video Settings, Performance, to stop transparent
  chunks. `config/DistantHorizons.toml` has `lodChunkRenderDistanceRadius=128`,
  `numberOfThreads=4`, `threadRunTimeRatio="0.5"`, `enableCaveCulling=true` with a
  height of 60 and `enableCloudRendering=false`; the client generator is
  `PRE_EXISTING_ONLY` because the server now builds the LODs. The server runs the same
  jar with `chunkGeneratorMode="INTERNAL_SERVER"`, `generatorPlan="SURFACE_THEN_CHUNKS"`,
  `pauseIfMovingQuickly=false`, four threads at a 0.5 ratio, a 128 chunk generation
  distance and no bandwidth limit on the LAN. The 2.8.4 setup also picked Quality Preset
  High and CPU Load Balanced in the mod's settings. Known issues are unchanged: memory
  creep, unstable server side, and LODs that need a render-distance toggle to refresh.
- **Dynamic Surroundings 1.0.9.0** (2026-09-30): mist475's 1.7.10 fork, newer than the
  2.8.4 jar's 1.0.7.7; adds Seasonal Horizons compatibility.
- **Sound-Physics 1.1.1** (2026-06-27): the 1.7.10 mixin edition.
- **Euphoria Patcher 1.9.3** is installed to match the NeonTech settings. 1.10.5 exists,
  but moving to it means copying the NeonTech values by hand.
- **BetterSprinting 1.1.3**: 2.3.0's coremod fails on 2.9 at the
  `EntityPlayerSP.onLivingUpdate` insertion point. 1.1.3 hooks through PlayerAPI 1.5.0
  instead, which the pack ships, and was installed on both sides on 2026-11-03 to test.
  It gives sprint toggle, sneak toggle and fly boost, not step assist.
- **Advanced Memory Card 1.2.0-1.7.10-GTNH** (2026-11-02): AE2 memory card with bulk
  configuration copy and P2P tunnel management. Declares no dependencies beyond AE2, and
  the copy volume defaults to 2048 blocks.
- **WTCT 1.0.63-rc1** (2026-10-11): ME combined work terminal, 63-slot extended buses,
  pattern auto-upload, wireless transceiver and upgrade cards. Built against 2.9.0-RC-1
  and AE2 `rv3-beta-1073`; the pack runs `rv3-beta-1095`, so the launch is the test. It
  ships `en_US.lang`.

## Dropped after testing

- **BetterSprinting 2.3.0**: its coremod cannot find its `EntityPlayerSP.onLivingUpdate`
  insertion point under 2.9 and aborts the launch with "Could not find insertion point".
  The 1.1.3 jar is installed instead (see above).

- **deconfigintegration 1.0.2**: its late mixins still declare Draconic Evolution's
  `IConfigurableItem` interface on IC2 and Avaritia classes. 2.9's Draconic Evolution no
  longer has that class, the failed transform poisons the class cache, and Avaritia then
  aborts pre-init with `NoClassDefFoundError`. Removed; each mod's own config file is
  enough.

## Runtime notes from the first successful launch

- **Programmable Hatches**: three optional compat mixins have no target in 2.9
  (`GuiInterfaceTerminalX`, `GregtechWailaDataProvider`,
  `FluidPatternTerminalRecipeTransferHandler`). Its own hatches load; only those
  cross-mod hooks are inactive.
- **NH-Utilities** logs `lang files not found` at startup; that is its own translation
  file, harmless.

- **ModernKeyBinding 2.1.0**: 2.9's Controlling 2.1.10 ships built-in key combo support
  and throws `IllegalStateException: Controlling now ships built-in key combo support and
  is incompatible with ModernKeybinding (mkb)` from `Controlling.init`. Removed; use
  Controlling's own combo support.

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

## Scripts

- **`scripts/simplestorage_gregified.zs`**: carried from 2.8.4. It removes EZStorage's
  default recipes and rebuilds them from GT materials. Every block and item id it uses
  (`storage_core`, `storage_box`, `condensed_storage_box`, `hyper_storage_box`,
  `crafting_box`, `input_port`, `portable_storage_terminal`) still exists in EZStorage
  1.8.2.

## Quest data

- **Twist-Stuff**: installed from the 2.9 set in
  [AdityaVG13/Twist-Stuff](https://github.com/AdityaVG13/Twist-Stuff) (last commit
  2026-08-27). The `TwistSpaceTechnology` folders sit in the server and client
  `config/betterquesting/DefaultQuests/{QuestLines,Quests}`, and its line is inserted
  after "Mass Processing" in `QuestLinesOrder.txt`. The repo's order file omits the
  123Technology line, so only the Twist line was added. New worlds pick it up from
  `DefaultQuests`; existing worlds need `bq_admin default load`. It is a community
  questbook: Twist 0.8.0 ships no BetterQuesting data of its own.

## Mod configs

The per-mod settings for GTNL, GTNHRates, EZNuclear and NH-Utilities are in
[config-tweaks.md](./config-tweaks.md#added-mod-configs).
