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
| GTNHRates | 1.12.0-2.9 | B | release tag, 2026-11-01 |
| Twist Space Technology | 0.8.0 | B | 0.8.1 and 0.8.2 both crash world start on the Bottled Chaos null; 0.8.0 is installed, see below |
| 123Technology | 2.2.1.3 | B | its README says 2.1.9+ supports GTNH 2.9.0; 2.2.1's release notes say it's adapted to 2.9.0 stable |
| Omni Miner | 6.6-balanced.13 | B | warpledge's fork of EZMiner 6.6, renamed on 2026-11-18; local fork at `~/Projects/ezminer-balanced`; ten Tinkers tiers, per-tool block lists, one-tree felling, empty-hand ground clearing, feature switches and a player-placed-only Block Swap, see below. 6.4 fixed a toolbox crash; 6.5 and 6.6 add a config validation tooltip and fix its message system, and 6.6's `dependencies.gradle` sets `gtnhVersion = "2.9.0"` |
| EZNuclear | 1.1.1 | B | README table: 2.9+ uses 1.0.8 to 1.1.1 |
| EZStorage | 1.8.3 | B | builds against GTNHLib 0.11.52, NEI 2.8.158; 1.8.3 fixes NEI bookmark pull with large stacks |
| Programmable Hatches | 0.2.1p9-beta | B | p9 (2026-11-20) fixes a Crafting Dumper stall on item-and-essentia patterns; p8 fixes a startup crash with GT-Never-Reset; p7 notes: only 2.9.0 supported; builds against GT 5.09.54.264, GTNHLib 0.11.54, NEI 2.8.171 |
| NH-Utilities | 1.7.0 | B | commit "Fit 29x" |
| YesSteveModel Unofficial | 3.1 | B | [czqwq fork](https://github.com/czqwq/YesSteveModel-Unofficial); 3.1 (2026-11-20) fixes the settings menu; 3.0's `dependencies.gradle` sets `gtnhVersion = "2.9.0"`, and its one commit says "Fix Amim system"; 2.9 added the preview setting's entrance and fixed the math parser, 2.6 fixed the animation loop and 2.7 restored the animation storage system, 2.5 disabled the lighting map |
| MineMenu | 1.2.0.B44 | C | latest on Modrinth, 2025-12-07 |
| FPS Reducer | 1.10.3 | C | latest, 2023-09-06 |
| GT-Interesting-Thing | 2.1.31 | B | release says compatible with 2.9.0 final; Neko shop; see below |

Trash Slot 1.0.31 was removed on 2026-11-21: Omni Tweaks 0.3.0 replaces it (see below).

**2026-11-24: four client-only updates and Better Foliage back, on the 2.9.0 client.**
Angelica 2.2.46 → 2.2.47 (translucency sorting, early TESR draws, layer and terrain split,
glow depth and depth peeling, and flowing water through LiquidLogged blocks), AngelLib
1.0.2 → 1.0.3 (the Java4Shell Base64 fix), Dashboard 1.0.23 → 1.0.25 (Extra Utilities TPS
line, redone bar atlas and Customize screen, new themes) and MyCTMLib 1.4.7-290 → 1.4.9-291
(1.4.8 moves to GTNHLib 0.11.58 and NEI 2.8.175, the 2.9.1 pair; 1.4.9 adds Forestry
machine and escritoire models). MyCTMLib is unproven on 2.9.0, which has GTNHLib 0.11.54
and NEI 2.8.171. Better Foliage 2.0.1 is back with both configs restored; its notes still
name no performance fix, so watch the FPS. Angelica#2092 is still open, so check
ChromaPatch and the shaders, Distant Horizons and Xaero's maps at launch. The four old
jars are in `backups/replaced-mods/2026-11-24/`.

**2026-11-24: GT-Interesting-Thing is back, with a storage-only AE shop.** `gtit-v2.1.31.jar`
on the 2.9.0 client and eclipse's debug server; side B, so legion needs it too. It needs
MIAOKATZE Core 0.2.29, already installed. The Neko shop preset `ae-storage-only` keeps the
AE basic pages for cables, terminals, network/power, drives/cells and panels/buses, drops
the auto-crafting/interface page, and removes the Creative Energy Controller, security
terminal, pattern/interface terminals and crafting/acceleration cards. Apply it once with
`/gtit presets`; the old `gtit-base` preset is deselected by the preset's exclusion list.
The mod was removed on 2026-11-10; the old 2.1.6 jar stays in
`backups/removed-mods/2026-11-10/`.

**The 2026-11-08 update is on the client and the laptop server:** GTNLLib
1.1.5, YesSteveModel Unofficial 2.3, MIAOKATZE Core 0.2.6, GT-Steam-Reborn 2.1.28,
GT-Interesting-Thing 2.1.6, GT-Simple-Wireless-Network 2.1.19 and Realistic World Gen 2
2.1.1. The three Miao mods need
Core 0.2.6 and their release notes say "compatible with GTNH 2.9.0 final"; GTNLLib and
YSMU name no pack version. GTSWN 2.1.19 lets items and fluids in through the covered face of
both wireless covers by default (screwdriver or cover UI to turn it off). Not launched yet.

**The 2026-11-09 update is on the client only:** EZMiner 6.4 (toolbox crash fix) and
YesSteveModel Unofficial 2.5 (disables the lighting map, built against 2.9.0). The laptop
server still has 6.3 and 2.3.

**The 2026-11-11 update is on the client only:** YesSteveModel Unofficial 2.8, Neo ECO AE
Extension 7.3.10 and GTNH Modernization Upgrade 0.3.5-alpha-GTNH-2.9.0. YesSteveModel's
releases carry almost no notes (2.8 none, 2.7 warns off its WIP features) but build
against 2.9.0. Neo ECO's notes say 2.9.0-RC1 and later. GTNH Modernization says it
requires 2.9.0, but its testing stopped at a headless server, and 0.3.5 is a
pre-release. All three are side B, so the laptop needs the same jars.

**The 2026-11-15 update is on the client only, thirteen jars.** Side B, and legion got
the same ten later: EZMiner 6.6, EZStorage 1.8.3, YesSteveModel
Unofficial 2.9, Realistic World Gen 2 2.1.2, MIAOKATZE Core 0.2.15, GT-Miao-Blueprint
0.3.30, GT-Steam-Reborn 2.1.45, GT-Simple-Wireless-Network 2.1.34, ThinkTech 0.3.3 and
Neo ECO AE Extension 7.3.11. The three Miao mods name Core 0.2.15 as their prerequisite,
and all four say they are compatible with 2.9.0 final. GT-Steam-Reborn 2.1.45 moves its
portable assembler recipes to configuration circuit 24: existing patterns and machine
selectors need setting to 24, though the ingredients and costs are unchanged.
Realistic World Gen 2 2.1.2 renames `rwg_data.dat` to stop it clashing with the RWG 1.5.3
jar in the same `mods/`. Side C, client alone: Angelica 2.2.46, AngelLib 1.0.2 and Better
Search 1.6.4. Later that day ChromaPatch went to 1.0.3 and Eclipse to `e89e6c6`, the
commit 1.0.3's patch targets, with the old Eclipse zip moved to the same backup folder
(see [shaders.md](./shaders.md#eclipse-with-chromapatch)). Old jars are in
`backups/replaced-mods/2026-11-15/`. Neo ECO AE Extension then went to 7.3.12 the same
day on the client. Legion has the side B jars above too, with Neo ECO at 7.3.13 (checked
2026-11-21).

**The 2026-11-16 update is on the client only:** 123Technology 2.2.1.3 and MyCTMLib
1.4.6-290. 123Technology is side B; legion has 2.2.1.3 too.
Its release adds a Positron_e+ artillery piece, AbstractSanctum and Steam9in1 fixes and a
Fishtorio loot-table blacklist update, and its body says it contains WIP content.
2.2.1.3 renamed its mod id to `123technology` and so reads a new `123technology.cfg`; the
edits in the old `123Technology.cfg` were not applied until they were moved over on
2026-11-19 (see [config-tweaks.md](./config-tweaks.md#balance-edits-2026-11-03)). MyCTMLib adds JSON models for the redstone
torch, repeater and comparator and renames a config node (`mc` to `minecraft`); the agent's
table was re-keyed for two strings 123Technology moved between classes, and its one new
string is a log line, left untranslated. Old jars are in `backups/replaced-mods/2026-11-16/`.
Not launched yet.

**The 2026-11-17 update is on the client only, eight jars.** Side B, and legion got the
same eight later: YesSteveModel Unofficial 3.0, MIAOKATZE Core 0.2.21, GT-Miao-Blueprint
0.3.34, GT-Steam-Reborn 2.1.52, GT-Simple-Wireless-Network 2.1.39, Neo ECO AE Extension
7.3.13, GTNH Modernization Upgrade 0.3.6-alpha and AE2Things 1.3.4. The three Miao mods
require Core 0.2.20 or newer, and all four name 2.9.0 final. GT-Steam-Reborn adds
dimension-bound stone making and retires the legacy natural singularity item.
GT-Miao-Blueprint adds public library permissions, and its 103 new hard-coded Chinese
strings were added to the translation table; GT-Steam-Reborn and GT-Simple-Wireless-Network
only added version and log lines. **Twist 0.8.2 was tried and crashed world start with the
same Bottled Chaos null as 0.8.1, so Twist stays 0.8.0.** GTNH Modernization 0.3.6 is a
pre-release. Old jars are in `backups/replaced-mods/2026-11-17/`. The client reached the
main menu with the eight; a world still needs a launch after the Twist rollback.

**2026-11-18: EZMiner is now Omni Miner, the local fork `6.6-balanced.12`, client only so
far.** The source is still `~/Projects/ezminer-balanced`; the jar is
`mods/omniminer-6.6-balanced.12.jar` (replaced by `.13` below), and upstream's jar is
disabled beside it as `EZMiner-6.6.jar.bak-2026-11-17.disabled`. The mod id is `omniminer`, so
its configs moved to `config/omniminer/omniminer.cfg` and `omniminer/omniminer_server.cfg`,
copied from the EZMiner files. Blast is gone, leaving Chain and Special; the mode key
cycles those two and the packet carries three indices. Chains now pass only through a
tool's own blocks: pickaxe for stone and ores, shovel for dirt and sand, axe for wood,
and shears for leaves, wool, vines and webs. A mattock uses the shovel and axe lists
together. A scythe starts no chain because it already clears an area itself. Hammers,
excavators and lumber axes start no chain; empty hands, swords and the wrong tool for
the target block are refused with the no-tool message, while a held axe still fells
trees through the tree founder. The founder now uses a 4-block horizontal radius (2..16,
`Axe Tree Radius`) and up to 32 blocks vertically, so it fells one tree instead of the
forest, and it treats leaves as part of the tree, so a branch log behind leaf layers is
still felled; leaves never trip `stopOnUnbreakable`. Shears use tier 1. Each family has an extra-blocks and a blocked-blocks
list under `tools { }`, one entry per block type so it covers every metadata variant; the OP
server tab opens a NEI-style editor per family with icons,
a search box, hover name and id, right-click removal and a list reset. Every config row
shows its full help text and action on hover, and a hovered `R` explains the reset. The unbound
`Add Block to Tool List` key adds the block under the cursor or the NEI item under the
mouse (Shift removes). The server allows that only for OPs, a cheats-enabled
single-player world, or the server-owner list. The GUI cycles named options instead of
numbered fields, every row has an `R` reset button, and Block Swap's preview now shows
every matching block in the swap radius instead of a connected chain.
`stopOnUnbreakable` and `fireBreakEvent` stay true, `smallRadius=1`,
`addExhaustion=0.01`, `breakPerTick=128`, and the tier table is unchanged. Side B, so
legion has the same jar and no `EZMiner` jar: the mod id
changed, so a client without it is rejected by a server that still has EZMiner.
Omni Miner is warpledge's own fork and takes upstream EZMiner changes only when needed
(crash, 2.9 or pack fixes). `mod-sources.json` tracks upstream as a parked `EZMiner`
entry with `lastTried` 6.6, so a new EZMiner release shows up for review.

**2026-11-18, later: Omni Miner `6.6-balanced.13` (fork commit `c83b3f5`), client only.**
The jar is `mods/omniminer-6.6-balanced.13.jar`; the test builds sit beside it as
`omniminer-6.6-balanced.13-pre{2,3,4}.jar.disabled`. What changed from `.12`, tested in game:

- **Built-in lists:** each tool's defaults come from the ore dictionary and block types
  instead of material, which had let GT machines, casings, chests and glass in. Pickaxe:
  ores and natural stone (GT granites, basalt, marble, cobble, netherrack, end stone,
  obsidian, sandstone, hardened clay). Shovel: dirt, grass, sand, gravel, clay, snow.
  Axe: logs and huge mushrooms. Shears: leaves, vines, webs, wool. Blocks with a tile
  entity (ores aside) and crafted shapes (bricks, slabs, stairs, storage blocks) never
  chain. `/omniminer dumplists` writes every family's effective list to
  `config/omniminer/default-lists.txt`.
- **Exact variants:** an entry is `mod:name@damage`, one variant, so adding one GT casing
  no longer adds all its siblings; a bare `mod:name` still covers every variant. The
  editor shows one icon per variant and has a fifth tab, Hand.
- **Trees:** the axe fills one connected tree up to 4 blocks sideways (2..4), walks up to
  2 leaves in a row to reach branches but never breaks them, and takes up to
  `logBlockLimit` (1024) logs of the clicked kind. Lumber axes don't fell, and the axe
  blocked list applies.
- **Empty hand:** clears up to 16 tall grass, ferns, flowers, double plants and dead bushes
  within 8 blocks; anything else with an empty hand still refuses.
- **Defaults** now match warpledge's settings: Minesweeper and Sudoku on, wave HUD
  animation, full-inventory smart tool switch, 0.1 s probe cooldowns, prospect probe 3600 s.
  The probe settings had been saved with category and key swapped; they now sit in
  `general` and the old sections are migrated away.
- **Settings screen:** client tab Preview, HUD, Controls, Smart Tool Switch; server tab
  Modes, Tool Tiers, Tool Block Lists, Mining, Tree Felling, Block Swap, Item Collection,
  Performance, Stability. New HUD Text Size (50 to 150%, default 75%).
- **Fixes:** block variants use `getDamageValue`, so a dedicated server matches blocks the
  way clients do; a world reloads its own server config, so a remote server's lists and
  tiers no longer leak into single player; tier limits are capped by `bigRadius` and
  `blockLimit`; list edits reach every player and stop at 32000 characters; a mouse-bound
  tool list key no longer crashes the client; GT electric snips count as shears.

Still open in the fork: cached chain mode (off) skips the tool gate, the GT toolbox is
resolved by reflection per block off the main thread, and Witchery vampires lost
bare-hand chaining.

**2026-11-20: eleven updates, on the client and eclipse's debug server.** MIAOKATZE
Core 0.2.29 (faster NEI structure previews, inline tooltip pin and tier controls),
GT-Steam-Reborn 2.1.67 and GT-Simple-Wireless-Network 2.1.44 (both need Core 0.2.29),
GT-Miao-Blueprint 0.3.39, Programmable Hatches 0.2.1p9-beta (Crafting Dumper stall with
essentia patterns, GT-Never-Reset startup crash), AE2Things 1.3.7 (cell content display),
ThinkTech 0.3.4 (catalyst detection), YesSteveModel Unofficial 3.1 (settings fix), GTNH
Modernization Upgrade 0.3.8-alpha (Portal Projector, BuildCraft work ranges), MyCTMLib
1.4.7-290 and Dashboard 1.0.23 (elements avoid overlapping). The four Miao mods name 2.9.0
final in their releases and Modernization's jar names 2.9.0; the rest are proven only by a
launch. All but MyCTMLib and Dashboard are side B; legion got them the same day (entry below).
GT-Steam-Reborn's two new Cluster Performance page strings are in the translation table;
its and Wireless's other new strings are version and log lines. Old jars are in
`backups/replaced-mods/2026-11-20/`.

**2026-11-18: five more updates, on the client only.** MIAOKATZE Core 0.2.22 (tooltip
fix for unregistered items), GT-Miao-Blueprint 0.3.37 (immediate controller preview,
decoration vouchers, AE orders from the controller review, Escape and reopen fixes),
GT:NH Processing+ 0.2.6.1-alpha (Twist Space compat, textures on two machines, updated
block requirements on every multi), AE2Things 1.3.5 (config rewritten with a GUI,
universal baubles slots for the 2-in-1 and backpack terminals) and Better Foliage 2.0.1
(FalseTweaks crash fix, short grass no longer clips modded blocks). Core, Blueprint and
Processing+ name 2.9.0 in their releases; AE2Things and Better Foliage are proven only by
a launch. The first four are side B; legion got them later. Blueprint's 10 new
strings are in the translation table. Old jars are in `backups/replaced-mods/2026-11-18/`.

**2026-11-20: nine updates, on the legion server.** The same nine side B jars eclipse got
that day (entry above), so legion matches it: MIAOKATZE Core 0.2.29, GT-Miao-Blueprint 0.3.39,
GT-Steam-Reborn 2.1.67, GT-Simple-Wireless-Network 2.1.44, Programmable Hatches
0.2.1p9-beta, AE2Things 1.3.7, ThinkTech 0.3.4, YesSteveModel Unofficial 3.1 and GTNH
Modernization Upgrade 0.3.8-alpha. GTSWN 2.1.44 needs Core 0.2.29 or newer, and all four
Miao mods name 2.9.0 final. Programmable Hatches p8 fixes a server start crash with
GT-Never-Reset; p9 fixes Crafting Dumper orders stalling on mixed item and essentia
patterns. GTNH Modernization 0.3.7 and 0.3.8 are pre-releases (Portal Projector,
BuildCraft work ranges). The other five are proven only by a launch. Twist stays 0.8.0:
0.8.2's notes don't mention the Bottled Chaos null. Realistic World Gen 2 stays 2.1.2:
GTNewHorizons' 2.0.9 release is numbered below it. Old jars are in the server folder's
`backups/replaced-mods/2026-11-20/`. Not launched yet.

**2026-11-10: GTNL and GTNLLib were removed; Better Questing API went with them.** BQ API
was installed on 2026-11-01 for GTNL's quest lines, so it is unused now and its jar is gone
from `mods/`; the pack's BetterQuesting stays. GTNL's Steam Revolution machines (Cactus
Wonder, Steam Circuit Assembler, Steam Assembly Line) shortcut the steam age; the Cactus
Wonder alone outputs up to 32M L/s. The GTNL jars are in `backups/removed-mods/2026-11-10/`.
GTNL came back on 2026-11-18; see [GTNL, re-added](#gtnl-re-added-on-2026-11-18).

**ElytraMining, SharedProspecting and BetterLineBreak were removed on 2026-11-10;**
their jars are in `backups/removed-mods/2026-11-10/`. VisualProspecting 1.5.42 in 2.9.0
already shares within GTNHLib teams; SharedProspecting only bridged ServerUtilities teams.
BetterLineBreak only changes line breaks for non-alphabetic languages. GTIT was removed
with them and came back on 2026-11-24; see
[GT-Interesting-Thing, re-added](#gt-interesting-thing-re-added-on-2026-11-24).

**The 2026-11-06 update is on the client and the laptop server, and both sides must match to
join:** GTNLLib 1.1.4, 123Technology 2.2.1.1, EZMiner 6.3, Programmable Hatches 0.2.1p7-beta
and the five MIAOKATZE mods below. The server booted on them that evening and a client
joined it (server log); nothing's been tested past that.

**123Technology is back on its release.** Releases before 2.2.1 crash during init on 2.9.0
stable, so the set ran the build from
[PR #269](https://github.com/CallmeSHaobe/123Technology/pull/269), merged 2026-11-02, until
2.2.1.1. Use 2.2.1.1 rather than 2.2.1: with Twist loaded, 2.2.1 skips the recipes of two
multiblocks (fix for #277).

Twist's tracker had the matching startup-crash report (#1390, from 2026-11-01), and the
0.8.0 release caught up on 2026-11-02: its changelog lists PR #1386 and its tag sits 11
commits past that PR's head. `TwistSpaceTechnology-0.8.0.jar` replaced the PR build on
both sides and the server loads it. On a Twist update, reset `GregTech.lang` and `TwistSpaceTechnology.cfg` to avoid
config conflicts.

**0.8.1 (2026-11-08) crashes the server at world start on 2.9.0**, tried on the client on
2026-11-09. Its new Bottled Chaos recipes can't resolve thionyl chloride ("unresolved
intermediate input in route 150: thionylchloride"), since GT 5.09.54.265 makes it from
cells in the chemical reactor map, not as a fluid recipe.
`BottledChaosFakeRecipes.registerCredentialRecipes:203` then passes a null to `GTRecipeBuilder.itemInputs`, and
FML aborts the server-about-to-start event. A singleplayer client looks frozen on the
loading screen. Back on 0.8.0 with its own config and lang; the 0.8.1 jar and the files it
generated are in `backups/replaced-mods/2026-11-09/twist-0.8.1/`. Skip 0.8.1 until a
release fixes Bottled Chaos (PR #1361).

0.8.2 (2026-11-17) was tried on the client the same day and hit the same
`BottledChaosFakeRecipes.registerCredentialRecipes:203` null at world start, so it is
rolled back to 0.8.0. The 0.8.2 jar is in `backups/replaced-mods/2026-11-17/`. Do not
install 0.8.1 or 0.8.2 until Bottled Chaos is fixed.

## Installed on 2.9.0 only

These are not carried from 2.8.4; they went in on top of 2.9.0 on 2026-11-02, client and
server, and the server boots with all of them.

| Mod | Build | Side | Note |
| --- | --- | --- | --- |
| Waystones-X | 1.0.16 | B | [JackOfNoneTrades fork](https://github.com/JackOfNoneTrades/WaystonesFork) of BlayTheNinth's mod; `config/waystones.cfg` sets `xpBaseCost=-1` |
| MIAOKATZE Core | 0.2.29 | B | required by the three Miao mods below, on both sides; the three bundle it in their release assets; 0.2.29 (2026-11-20) is the minimum for Steam-Reborn 2.1.67 and Wireless 2.1.44, and adds faster NEI structure previews and tooltip pin controls (release says compatible with 2.9.0 final) |
| GT-Miao-Blueprint | 0.3.39 | B | Neko Blueprint Hologram Projector: blueprint, cut and demolition modes; 0.3.39 opens the workspace straight from a controller and fixes Escape during a scan; 0.3.37 added an immediate controller preview, decoration vouchers and AE orders from the material review |
| GT-Steam-Reborn | 2.1.67 | B | steam industry, hubs and nodes, singularity tech, the Prosperity dimension, portable weapons, a BQ line; 2.1.67 lets non-owners reopen permitted machines from Machine Terminal history; 2.1.52 added dimension-bound stone making and retired the legacy natural singularity item |
| GT-Simple-Wireless-Network | 2.1.44 | B | wireless EU link nodes, monitors, ME quantum terminal; 2.1.44 refuses quantum bus swaps that lose parts and links mirrored matrix layouts; 2.1.42 fixes Assembly Line matrix research; 2.1.39 grouped terminal controls |

All but Waystones come from [MIAOKATZE](https://github.com/MIAOKATZE) and are tagged
"for GTNH 2.9.0 stable". Their `en_US.lang` files are complete, so the in-game text is
English; the READMEs are Chinese. GT-Miao-Blueprint needs Applied Energistics and
StructureLib, GTSWN needs AE2, GTSR only GregTech. Since 2026-11-03
123Technology's overpowered recipes are off; the values are in
[config-tweaks.md](./config-tweaks.md#balance-edits-2026-11-03).

One more joined them later on 2026-11-02, client and server:

| Mod | Build | Side | Note |
| --- | --- | --- | --- |
| ThinkTech | 0.3.4 | B | chemistry and materials: briquettes, methane clathrate, catalysts, computing chips, explosives (PETN, HMX, HNIW), separation control cores; 0.3.4 fixes the general chemical factory missing catalysts; 0.3.3 fixes the implosion generator's power display and structure and the crucible recipes for Nichrome and Platinum |

TenkeiTech 1.1.0 was installed with it and removed the same day: it hands you an
"Useless Tools" staff on spawn with force kill, spawn eggs, area damage, bedrock mining
and time acceleration modes, and the AE automation it adds was not worth that. Its jar and
`config/tenkeitech.cfg` are gone from both sides and FML removed its items from the world.

Four client-side additions on 2026-11-02:

| Mod | Build | Side | Note |
| --- | --- | --- | --- |
| World Tooltips | 1.2.3-90 | C | floating tooltip over dropped items; shader-compatible continuation of GenuineSounds' mod; [source code](https://github.com/GTNotLeisure/WorldTooltipsContinuation) |
| MyCTMLib | 1.4.9-291 | C | connected-texture support for resource packs; 1.4.8 moves to GTNHLib 0.11.58 and NEI 2.8.175, the 2.9.1 pair, and 1.4.9 adds Forestry machine and escritoire JSON models; 1.4.7 added ProjectRed and Automagy torch models. Unproven on 2.9.0's 0.11.54 and 2.8.171 |
| OmniOcular Unofficial | 1.7.2 | B | WAILA add-on showing machine internals; client full jar, server `-server.jar`; see the scripts note below |

World Tooltips moved from 1.2.3-87 to 1.2.3-90 on 2026-11-17. Builds 88 to 90 have no
Java changes: they move the mod to GTNHLib 0.11.52, NEI 2.8.155, FalsePatternLib 1.12.2
and the 2.9-era Gradle toolchain. The old jar is in `backups/replaced-mods/2026-11-17/`.
The source moved from kotmatross28729's repo to GTNotLeisure, and Modrinth still lists
1.2.3-87, so the update check reads GitHub now.

Fancy Block Particles 2.4.1 was removed again on 2026-11-17; see
[Dropped after testing](#dropped-after-testing).

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
these files, so new Chinese strings would need translating again. From 1.7.x the mod pulls
config from luomolhx/GTNH_OmniOcular on every launch (`gtnhConfigAutoUpdate`, on by
default): on 2026-11-10 it overwrote eight English scripts with Chinese ones, added
`GregTech5U-GTNH.xml` and blanked `GregTech5U.xml`, keeping the originals in
`config/OmniOcular/oo-backup/`. On 2026-11-15 the client got the English files back from
there, `gtnhConfigAutoUpdate=false`, and `forceUseClientXml=true` so a server's copy can't
override them; the upstream files are in `config/OmniOcular.upstream-zh-2026-11-10/`. The
server needs the same. 1.7.2 still stalls on the config merge for
10+ seconds at startup; the fix is in a commit after the release. The English scripts
came from the CCYF78 pack, which wrote line breaks as `"\\n"`; 1.7.x prints that
literally, so multi-line fields overlapped the next column. On 2026-11-20 every `"\\n"` in
`GregTech5U.xml`, `Avaritia.xml` and `AWWayofTime.xml` became `"\n"` (what the upstream
1.7.x scripts use) on both sides; the old files are in
`config/OmniOcular-before-newline-fix-2026-11-20.tar.gz`.

One mod written for this setup on 2026-11-04, client and server:

| Mod | Build | Side | Note |
| --- | --- | --- | --- |
| Omni Tweaks | 0.3.4 | B | Step height 1.0 (0.5 while sneaking), better ladder and vine climbing, and since 0.3.0 a trash slot with an auto-trash filter, recovery and a valuables check |

It reimplements the wanted features of Keep Stepping and Better Climbing, neither of which
has a 1.7.10 build; no code comes from them. Its climbing mixin hooks
`EntityLivingBase.moveEntityWithHeading` and only acts on the client's own player. Holding
jump in a climbable climbs up, and looking down 45° or more descends instead of climbing
when walking into a ladder. Toggles and speeds are in `config/omnitweaks.cfg`. These
features passed in-game testing on 2026-11-04, under the mod's first name, Footwork. The
source is in `~/Projects/omni-tweaks`, a local git repo built with GTNH's ExampleMod
starter; the jar is `build/libs/omnitweaks-<version>.jar`.

0.3.0 (2026-11-21, tag `0.3.0`) adds a trash slot that replaces Trash Slot 1.0.31,
reimplementing its behaviour with no code from it: drop a stack in, take the last one back,
Delete trashes the hovered stack and Shift+Delete every exact match in the main inventory.
The card under the slot has a funnel key for the auto-trash filter and an arrow key for
recovery, both panels left of the window. The filter holds exact matches (item, damage
and NBT) per player, each switched on or off without leaving the list, and deletes them on
pickup; since 0.3.2 it takes up to 504 items, growing a row at a time and scrolling once
it reaches the bottom of the screen. The server keeps the last 54 hand-trashed stacks and 27 merged auto-trashed ones in
the persisted player tag. Ops can restore from both; everyone else sees and restores only
their newest 5 hand-trashed stacks (`backup.playerRestoreCount`), so the backup can't be
used as extra storage. Enchanted, renamed, rare or NBT-carrying items, plus
`valuables.extra`, need a confirm popup and are never auto-trashed. Settings are in the
`trash`, `autotrash`, `backup` and `valuables` sections of `config/omnitweaks.cfg`.

0.3.1 (same day, tag `0.3.1`) fixes the first in-game test: dropping a stack on a full
trash slot handed the old one back, the side panels drew over items dragged from NEI, and
hovered keys showed almost no change. It also adds the 5-stack limit above. 0.3.2 adds the
growing filter, moves the panels left of any button beside the window (ServerUtilities'
sidebar sat on top of them) and centres the close key's x. 0.3.3 draws the card, panels
and popup in Craft Chain's dark see-through style and drops NEI drag onto the filter,
which never fired in the pack; items are dropped in from the inventory. 0.3.4 keeps the
trash panels closed while Craft Chain's overlay is open, since both sit left of the
inventory (looked up by reflection, so Craft Chain stays optional). 0.3.4 passed in-game
testing on the client on 2026-11-21. Every older jar,
Trash Slot's jar and `trashslot.cfg` are in the client's
`mods.bak-2026-11-21-omnitweaks-0.3.0/` and the server copy's
`backups/pre-omnitweaks-0.3.0-2026-11-21/`. Copy the server folder to the laptop to apply
it there.

## Added on 2026-11-05

Latest 1.7.10 Forge builds from Modrinth, hashes checked. None has an explicit 2.9
release; all of them passed in-game testing on 2026-11-05.

| Mod | Build | Side | Note |
| --- | --- | --- | --- |
| World Preview NH | 1.0.3 | C | biome and height preview on Create New World |
| Vintage Resourcify, with AngelLib 1.0.3 | 1.0.6 | C | in-game resource and shader pack browser; 1.0.2 marks server list pings with port 0 rather than a hostname suffix, so e4mc worlds stop showing as "Unknown server"; 1.0.3 decodes animated server icons in plain Java to avoid Java's Base64 intrinsics on AVX-512 VBMI (CVE-2026-114938), and Java itself still needs updating |
| Better Search | 1.6.4 | C | typo-tolerant search, with NEI and AE2 hooks; 1.6.4 fixes its AE2 mixin errors and works with Language Reload |
| Effortless Building Gadgets | 0.10.1 | B | shape building through a crafted gadget; `B:consumesEnergy=false` on both sides, so it needs no power |
| Shoulder Surfing Reloaded | 2.4.1 | C | over-the-shoulder camera; a 2023 build that patches vanilla code, so suspect it first after a pack update |

Vintage Pick Up Notifier 1.0.0 was removed on 2026-11-17; Dashboard's HUD editor covers
pickup notices. Its jar and config are in `backups/removed-mods/2026-11-17/`.

Vintage Resourcify lists `forgelin-legacy` as required. It has the same `forgelin` mod id
as the pack's `forgelin-2.0.3-GTNH.jar`, so it was left out and runs on the pack's copy.

Right Proper GUI Scale 2.1.1 is also on the client. It keeps the scale as a decimal in
`options.txt` (`guiScale:3.5`, between vanilla's 3 and 4) and applies a change when the
settings screen closes, so it can look like nothing happened. `/guiscale` sets it in game.

Neo ECO AE Extension 7.3.13 is on the client (2026-11-17), on trial since
2026-11-05: three tiered AE2 multiblock systems for storage, crafting and computation, an
optional upgrade path rather than a replacement for normal AE2. Both sides must match.
Modrinth lags the official 1.7.10 repo
([Yang120231/GTNH-ECO-1.7.10](https://github.com/Yang120231/GTNH-ECO-1.7.10), 7.3.13 on
2026-11-17 against Modrinth's 7.3.7), so `mod-sources.json` checks GitHub. Its 7.3.11
notes name GTNH 2.9.0-RC1 and later, and so do 7.3.13's. 7.3.13 adds pattern upload
filters, machine grouping and target statistics, voltage tier display and ranking, NEI
recipe source restore, unified status cards, workstation priority and scroll slots with
the old fifth slot refunded, a read-only NEI view of ECO storage cells, L4/L6/L9
computation cell disassembly recipes, and processing monitor improvements. 7.3.12 added
extended resource keys with exact inventory accounting, CraftTweaker recipes for the
single-block Integrated Workstation, processing status for TecTech multiblocks and the
Space Elevator, and batched structure validation for the computation subsystems; it fixed
a stuck 100% progress bar on completed materials, a stalled ME Fluid Auto-Filler, Assembly
Matrix batch
inputs and container returns, and keeps running crafting CPUs through structure changes.
7.3.11 batched processing patterns against remaining demand
and fixed a scan cursor that left later recipes unscanned.
Its recipes looked in line with GTNH in NEI. Still to check: autocrafting through GT
machines alongside WTCT, and what a world loses when it's removed. The world from before it
went on the server is `~/Documents/Minecraft_Servers/World-Backups/World3-before-neoecoae-2026-11-05.tar.gz`.

## Added on 2026-11-09

Nine jars went into the client instance that day; the laptop's `mods/` has not been checked
from this repo since, so treat the server side as unconfirmed. Every one is side **B** except
MouseSideButtonFix. Only the two arturia-Xayah mods name 2.9.0 in their release; for the rest
a launch is the proof.

| Mod | Build | Side | Note |
| --- | --- | --- | --- |
| GTNH Modernization Upgrade | 0.3.8-alpha | B | Structure terminal (project, build, replace and dismantle a GT multiblock from its StructureLib definition), ME packing tape, integrated 36-pattern item, AE order element, colour power budget for the Plasma Forge and fusion, and an ME storage vault. 0.3.8 adds the Portal Projector (paired gates between dimensions, optional destination view) and 0.3.7 BuildCraft work ranges and a main menu update button fix; 0.3.6 added order diagnostics and a storage vault lighting fix under Angelica. Alpha, one author, AI-written; the vault keeps inventory in `<world>/data/aestoragevault/`, and 0.3.0 changed that format without reading 0.2.x |
| AE2 Wireless Transceiver | 1.2.1 | B | [peco331](https://github.com/peco331/AE2WirelessTransceiver-GTNH) fork; each release ships a plain 2.9 asset and a separate `-gtnh2.8.4` one, and the plain one is installed |
| Benzene Fuels | 0.5.1-alpha | B | Eight staged benzene fluids from LuV to UIV and the Resonance Fuel Generator; needs GoodGenerator and GT++ ([arturia-Xayah](https://github.com/arturia-Xayah/gtnh-benzene-fuels)) |
| GT:NH Processing+ | 0.2.6.1-alpha | B | New processing chains built on materials chemistry, meant to fill progression gaps ([shusidefloof](https://github.com/shusidefloof/GTNH-ProcessingPlus)) |
| MouseSideButtonFix | 1.0 | C | Binds the mouse side buttons, which 1.7.10 ignores ([asdflj](https://github.com/asdflj/MouseSideButtonFix)) |
| Patchee | 1.7.3 | B | Cross-mod fixes: JABBA Dolly carries single-block bee housings, Tinkers' Mattock digs sand and snow at shovel speed, a filled Super Tank or Super Chest stops applying its effects to the carrier, VeinMiner stays server-controlled, ServerUtilities team chunk limits read the best member's rank instead of summing, F7 marks only pitch-dark blocks, and the Twilight Forest aurora and arctic fur blocks break faster once earned. No public page, so update checks report it as no-source |
| Thaumic Duality Interface | 1.0.2 | B | ME essentia dual interface as a block, item part and P2P tunnel ([CaelixOrbit](https://github.com/CaelixOrbit/ThaumicDualityInterface)) |
| Wildcard Pattern | 1.1.1 | B | AE2 processing pattern with configurable name and ore-dictionary matching that expands into real patterns ([clfpwp](https://github.com/clfpwp/WildcardPatternforGTNH-1.7.10)) |
| LagGoggles | 4.17.0 | B | Profiler; built against FalsePatternLib 1.10.7 while the pack ships 1.12.2, so loading is the proof. It moved here from the left-out list |

## EZStorage craft fix, written for this setup on 2026-11-10

`ezstoragecraftfix` 0.4.0 patches Simple Storage (`ezstorage`) crafting, on the client
and the laptop's server `mods/` (there since 2026-11-10). Source is `~/Projects/ezstorage-craftfix`, MIT like
EZStorage, built with GTNH's ExampleMod starter.

- The crafting box recomputes its result on every grid slot change, and setting a recipe
  fills nine slots, so one craft cost nine full scans of the recipe list. GTNH registers
  thousands and its GT recipe classes are heavier than vanilla's.
- The mixin caches results per grid, NBT included (128 entries, five seconds), and keeps
  a second key without NBT that maps to the matched `IRecipe`. A tool whose NBT changes
  with each use still hits, because only that one recipe's `matches()` runs and a failure
  falls back to the full scan.
- Measured with JFR on 2026-11-10: `findMatchingRecipe` 7.6/s to 1.4/s on the server and
  8.3/s to 1.6/s on the client. Repeated clay dust crafts became instant. GT tool recipes
  still pause, since that is GT's own per-recipe cost, but far less than before.
- Do not retry the first attempt, which deferred the recompute to the next tick to
  coalesce the nine calls. It broke shift-click (one item instead of a stack) and made
  the grid refill consume the grid instead of pulling from storage.

## Smooth Swapping, ported for this setup on 2026-11-17

`smoothswapping-1.0.1.jar` animates item stacks moving between slots, client only. It's a
port of [Schauweg's Smooth Swapping](https://github.com/Schauweg/Smooth-Swapping) (branch
`1.20.1/dev`), which is LGPL-3.0, so the port is LGPL-3.0 too and credits upstream in its
`NOTICE`. Source is `~/Projects/smoothswapping` (own git repo, tag `1.0.1`), built with
GTNH's ExampleMod starter. It replaces a 0.6.0 rewrite from 2026-11-10 that didn't work and
was deleted; that one's settings are in `config/smoothswapping.cfg.old-2026-11-10`. Tested
in game on 2026-11-17: every case below works, and all eight mixins apply with no warnings
in `logs/fml-client-latest.log`.

1.0.1 (2026-11-22) fixes a client crash in ModularUI 2 screens. MUI2's
`drawContainer` null-checks the real cursor stack, but a swap can hide the whole stack
while it flies, so `drawItemStack` received null and threw an NPE on a wood click into a
coke oven. The mixin now cancels `drawItemStack` for a null stack. The old jar is in
`backups/replaced-mods/2026-11-22/`; installed, in-game test pending. Crash report:
`crash-reports/crash-2026-11-22_04.26.35-client.txt`.

- Upstream's model: slots that lost items are paired with slots that gained the same item,
  and a copy moves in a straight line from one to the other while the destination shows its
  count minus what's still in flight. Pairs come from a diff around
  `PlayerControllerMP.windowClick`, where the client applies a click, and from a diff before
  each screen draw for moves the server makes (Bogosorter, hoppers). A gain left over after
  a click is credited to the clicked slot, which covers shift-clicking a crafting output.
- Covers vanilla `GuiContainer` screens, the cursor stack (picking up and putting down),
  ModularUI 1 and 2 screens (GT machines, AE2), and the hotbar with no GUI open, where a
  refill from the main inventory rises from below the bar. The ModularUI hooks are late
  mixins loaded only when `modularui` or `modularui2` is present. The AE2 ME grid uses
  virtual slots outside the container, so scrolling it doesn't animate. The creative
  inventory is skipped.
- Config screen behind the Mods list, saved to `config/smoothswapping.cfg`: on/off, speed
  10 to 1000 (default 350, about 143 ms a move whatever the distance, as upstream), ease-out
  0 to 1 (default 0), and toggles for server moves, the cursor, ModularUI and the hotbar.
  Upstream's curve editor wasn't ported.

## Craft Chain, written for this setup on 2026-11-20

`craftchain` is a crafting overlay in the spirit of Magic Storage's crafting interface,
client only. Source is `~/Projects/craftchain` (own git repo, MIT), built with GTNH's
ExampleMod starter against NEI 2.8.171. The first build (`fae8311`) worked in game with
Simple Storage on 2026-11-20. The docked redesign (`f5d9f99`) was tested the same day: no
C button, clicks and the wheel went through to AE2 and Simple Storage, and GT tools on
hand were planned as crafts. `de4c074` fixed those (tested in game) but left surplus
intermediates, five extra iron plates after a helmet. `80be471` fixes that, and
`184bdbc` on top of it swaps the grey and white slots for dark ones. `bd59523` (2026-11-20,
after a code review) adds quick-craft sub-chains, tool wear, batch rounds, saved picks,
a missing-items bookmark group, NEI search in the recipe picker and a refresh button, and
fixes the planner crafting tools you don't hold. Testing it turned up a diamond planned
from a diamond and quick-craft picking a Bismutite saw from iron and wood; `924f0f8`
fixes both (can-make now counts tools you could craft first, and a chain never uses up
what it makes) and makes the scrollbars draggable. Counting craftable tools made the old
search time out before reaching GT tools ("search cut short", no hammers listed from iron
and logs); `ac7551d` replaces it with one round-by-round pass per stock change.
`9311454` adds a search depth control (− N +) to the top bar and raises the default
from 4 to 6, the depth a GT saw from logs and ingots needs; this instance's
`config/craftchain.cfg` was set to 6 by hand, since an existing config keeps its value.
The 9311454 log showed the recipe index taking 32 s for 62,340 recipes, started only on
the first crafting GUI, and a 2 to 5 s wait on each GUI switch. `6a71826` starts the
index at world join, converts NEI's shaped and shapeless recipes in parallel, and reuses
the craftable search when only counts change or a GUI is revisited; the log now gives
each handler's read and convert times (`Recipe index: ... read in ... ms, converted in
... ms`). On 2026-11-21 a batch from `5d3e2ba` to `5f679de` (eight commits) redesigned
the dock and added the features listed below. Tested in game the same day: all worked
except that the GUI underneath still showed its tooltips through the panels and some
recent targets (GT tools, after a restart) couldn't be right-clicked away; the machine
list and AE2 requests weren't tried. `8a622f8` fixes both, keeps recents per GUI kind,
groups the settings under labelled sections and gives the C button NEI's own background
with a centred gold C. `829b1e8` raises the search depth's ceiling from 8 to 16 (Shift-click
steps by 5; its tooltip warns in yellow that deeper results are less exact).
`e8fb9a2` (2026-11-21) opens it over the player's inventory too, through NEI's
`crafting2x2` overlay (`DefaultOverlayHandler(63, 20)` on `GuiInventory`, which NEI's
shaped and shapeless handlers fall back to for recipes passing `isRecipe2x2`): there it
plans, lists and crafts only recipes with every slot in the top-left 2x2, a step needing
3x3 shows as missing ("needs a crafting table"), and worn armour isn't counted as stock.
It's the *Open in the inventory (2x2)* setting under Opening, on by default.
Tried in game the same day: Craft made nothing once the inventory already held as many
of the target as asked for (planks crafted once, then never), at a table too. NEI's chain
maths counts the inventory as supply, the target included (`RecipeChainIterator`
`.refreshInitialItems`); `00a8fa4` adds what's held to the target step's multiplier.
That fixed the table, but the inventory still made nothing: GTNH's inventory grid sits at
(90, 22), vanilla's at (88, 26), and NEI registers its 2x2 overlay at the fixed offset
(63, 20), so it found no slot to fill (NEI's own 2x2 fill is broken in the pack too).
`3ea863f` logs NEI's view of each step when a Craft makes nothing, which showed it;
`24b6e8d` replaces the 2x2 handler with one that reads the grid's real slots.
`craftchain-24b6e8d.jar` is installed; tested in game on 2026-11-21, crafting works in
both the inventory and a crafting table. It is client only (GUI mixins, no packets); a
copy put on legion's server was moved to its `backups/removed-mods/2026-11-21/`. `00a8fa4`, `e8fb9a2`, `4fdceaf`
and `3ea863f` are kept as `.jar.disabled` (the older disabled jars were gone by then).

`craftchain-2534e5e.jar` replaced it on 2026-11-21 and looked right in game the same day:
the card layout, the Craftable category rail and grouped grid, tooltips through Chromatic
Tooltips (so the mod name shows), and the full-screen Tree/Stages diagram with the
inventory tray and craft log (Craft Chain's README has the details). `24b6e8d` stays as
`.jar.disabled`.

`craftchain-tooltracker.jar` (built on 2026-11-22 from the tree committed as `3406b64`)
replaced it. It adds the GT tool tracker and Craft Chain's own runner (below),
and recipe lookup now matches a GT tool's material, so an ardite hammer target no longer
takes another material's recipe. Tested in game on 2026-11-22: a screwdriver chain in the
Simple Storage box crafted exactly 2 rods and the screwdriver in one Craft, and the
material list no longer crashes the AE2 terminal. In AE2's terminal the output slot refuses
plain clicks, so the runner sends AE2's `CRAFT_ITEM` inventory action per craft. Tool
picks being remembered and quest counting through the runner are still to confirm.
`craftchain-gttoolfix.jar` and `craftchain-bookmarks-test.jar` are kept as `.jar.disabled`.

`craftchain-overhaul.jar` (built on 2026-11-22 from `473ac75`, three commits on
`3406b64`) replaced it; `craftchain-tooltracker.jar` is kept as `.jar.disabled`. It is the
visual overhaul picked on the Craft Chain Overhaul Options and Craft Chain Tree Options
pages: live STEPS rows, crafted items flying to the target, the GUI's grid outlined
while a step fills, a red row with Retry step / Skip / Stop on a failure, sounds, a
target card with a typeable amount and ±1/16/32/64 keys, have/need counts, roomier rows,
tooltip details behind Left Ctrl, a tab row (or rail) with sub-chain and bookmark-group
tabs, the Tree tab, and the diagram's tiles or slot cards, bus lines and side panel
(Craft Chain's README has the details). It looked right in game on 2026-11-22, with some
minor issues still to list. The same day it was rebuilt from `3b1a8eb` (effect toggles,
a compact Chain view, Max with its count, the Tree tab's tool tracker, Settings beside the
dock; `docs/todo/craftchain-overhaul-followups.md`), not yet tried in game.

`craftchain-96fa3ba.jar` replaced it on 2026-11-23, built from `96fa3ba`, the three merged
pull requests: bookmark tabs with an amount (right-click → *Set amount…*; Shift+wheel
steps 1, Ctrl 16), the amount field taking sums (`9*18`, `3x5`, `(2+1)*64`), a Tree tool
display setting (Target slots or the old Strip), the Tree tab's amount field on the
wheel, and TAKES/MISSING rows showing one number each, the plan's count and the
shortfall, with have/need left to the tooltip. The same merge adds the live-reload tools:
`tools/deploy.sh` builds and drops the jar into the instance's mods folder, and
`tools/hotswap.sh` redefines changed method bodies in the running game over JDWP
(`tools/CLAUDE.md`), not yet tried in game.

`craftchain-5fb9896.jar` replaced it on 2026-11-23, the repo after the Browse revert and the
logic review. The Browse tab rework (`e4e53a2`) is gone (PR #6, after the local revert
`2603e92`), so the tab is the old Craftable with All, Now and Sub-crafts. PR #7 fixes the
planner: steps now run after the steps making their ingredients (an item could run before
what its second use needed), recipes with a slot no item can fill are dropped from the
recipe index and its saved format is bumped, the grid runner clicks partial stacks and
says "Inventory full", a GUI closing mid-run clears the step like Stop, the most worn
tool that lasts the chain is picked, and a zero result count is guarded. Unit tests pass;
the jar is deployed, not yet tried in game.

- Opens with `C` (rebindable) or the C button after GTNH Planner's P in NEI's
  bottom-left row, on any GUI where NEI has a `crafting` overlay: crafting tables, the AE2
  crafting terminal, the EZStorage crafting box. Shift opens it expanded.
- Docked, it takes the place of NEI's bookmark panel (hidden through an
  `INEIGuiHandler` while it's open) and takes input only over its own panels, so the GUI,
  the inventory and NEI's item list stay usable. Expanded, it reaches to NEI's item list.
- The Craftable tab lists what grid recipes make from the inventory plus the storage the
  GUI's NEI bookmark container handler reports, filtered All, Now or Sub-crafts (depth and
  time budget in `config/craftchain.cfg`).
- The Chain tab builds the grid-recipe chain for an item, stock first. An ore-dictionary
  slot (any planks) is one step offering every variant's recipes. Docked, the tab is the
  overview column: target, amount (with *Max*, the most that plans in full), TAKES,
  MISSING, LEFTOVERS and STEPS (a Steps | Tree pill shows the full tree), with the status
  line above Craft. A step's recipes pop out beside the dock, listed "Can make" (tools on hand, materials
  on hand or craftable) or "All", best yield first. Craft runs each step itself
  (`GridRunner`): the GUI's own NEI overlay handler fills the grid (vanilla grids,
  EZStorage's `NeiCraftingOverlay`, NotEnoughEnergistics' terminal handler), the picked
  tool is swapped in, and each craft is clicked out one at a time. It never shift-clicks,
  because EZStorage's box refills the grid from storage after every shift-clicked craft
  up to a full stack. Results leave through the output slot, so the questbook's crafting
  tasks count them (EZStorage's own NEI craft packet, which `AutoCraftingManager` uses in
  that box, crafts server-side without the crafted event BetterQuesting listens for).
  `ownRunner=false` (config `server` section) or a GUI without a known handler falls back to
  NEI's `BookmarkPanel.pullBookmarkItems` and `AutoCraftingManager`, the path a
  crafting-mode bookmark group takes. Machine-made ingredients show as missing; clicking
  one lists NEI's other handlers for it (`GuiCraftingRecipe.getCraftingHandlers`), with
  EU/t and time read from GT's `mRecipe` by reflection.
- It draws through NEI's container hooks rather than as its own screen, because
  `AutoCraftingManager` stops when the open screen changes. Two mixins: one on NEI's
  `LayoutManager.updateWidgetVisiblities` adds the C button (NEI rebuilds its widgets every
  frame, as GTNH Planner's P is added), and one on vanilla `GuiScreen.handleInput` stops
  mouse events over its panels, because AE2 and Simple Storage read clicks and the wheel
  before NEI's input hooks.
- Recipe slots match stock by item and damage, ignoring NBT, as crafting does: NEI's
  recipe permutations for GT tools are dummy stacks whose NBT never matches a real tool.
- On the NEI fallback, only the target's step goes to NEI with the amount as its
  multiplier; every other step gets 1. NEI's `RecipeChainMath` reads a multiplier above 1
  on any step as extra output asked for, which is what made the surplus plates. It also
  treats every GT tool of a kind as one item, any material, which is why the runner exists.
- The look is GTNH Planner's palette (MIT, credited in the mod's `NOTICE`); panel opacity,
  UI scale, default list and every on/off behaviour are in its settings popover, each
  with a tooltip.
- Tools are never crafted by the plan. The MAKING card has a tool tracker: a slot per
  tool kind (its `craftingTool…` ore-dictionary name, or the item for other mods' tools)
  with a durability bar and the uses the chain needs, green, amber (wears out first) or
  red (none held). Clicking a slot picks the tool from inventory or storage; picks are
  kept per GUI class in `config/craftchain-tools.json` by item and GT material, and with
  none the most worn tool that lasts the chain is used. A red slot lists the tool's
  recipes per material, and the chosen one is crafted as a sub-chain. The TOOLS card and
  *Tools ›* queue are gone. GT tool wear is read from GT's `MetaGeneratedTool` API by
  reflection, so there's no compile dependency on GT.
- On the server it stays client-only (the server needs no jar). Waits for pulled items and
  crafted results settle on the inventory; `pullSettleTicks` (8) and `pullTimeoutTicks`
  (100) are in the config's `server` section if the server lags. Picks are saved in
  `config/craftchain-picks.json` under registry-name item keys, so they carry across worlds.
- The open key over an item (NEI's list, the inventory, a recipe card, NEI's recipe
  screen) opens its chain. The Craftable tab has favourite and recent targets
  (`config/craftchain-targets.json`, recents per GUI kind), a sort key (NEI, amount, name, mod) and category
  icons (building, machines, parts, materials, tools, weapons, armour, food, rest). Each
  kind of crafting GUI keeps its own chain and list across switches.
- The recipe index is saved to `.minecraft/craftchain/recipe-index.bin` and reused at
  world join while a SHA-256 fingerprint (mods and versions, handlers, every crafting
  recipe, ore dictionary, NEI hidden items) matches; Shift+↻ re-reads NEI.
- AE2 requests (off by default, untested): an *ME* button on a missing item with a
  pattern opens AE2's crafting amount screen with the amount filled in, through
  reflection into `GuiMEMonitorable.sendAction`.

## Dashboard, added on 2026-11-15

`dashboard-1.0.25.jar` (1.0.25, 2026-11-23; 1.0.22 was added on 2026-11-15, 1.0.23 on
2026-11-20) is on the client only. 1.0.23 makes elements move aside instead of
overlapping; 1.0.24 adds an Extra Utilities TPS line, and 1.0.25 redoes the bar texture
atlas and Customize screen and adds themes. It is GTNH's own HUD
editor: every HUD element, from Minecraft and from the mods it supports, gets a box you
drag, resize or hide, and bars, the crosshair, the hotbar and the screen overlays can be
restyled. Three layouts are kept, switched with a key.

- 2.9.0 does not ship it, and it names no pack version. Its `dependencies.gradle` builds
  against GTNHLib 0.11.52 and NEI 2.8.158; the pack has 0.11.54 and 2.8.171, and its
  `mcmod.info` requires `gtnhlib` alone. Not launched yet.
- Keybinds under **Controls**, **Dashboard**: Open Dashboard HUD Editor (none by
  default), Next HUD Layout and Show/Hide Pictures. Without a key, Mod Options,
  Dashboard, Config, then Open HUD Editor.
- Everything changed in the editor saves as you go, to `config/dashboard/editor.cfg`.
  PNGs put in `config/dashboard/images/` become movable elements after **F3 + T**.
- InGameInfoXML was removed on 2026-11-17, so Dashboard has no IGI text areas to move.
  Watch the shaders (Eclipse through ChromaPatch) and Xaero's maps on the first launch,
  since Dashboard draws over the same frame.
- The jar came from the 1.0.22 release and its sha256 matches the one GitHub lists. The
  server needs nothing; side C.

## AE2Things, added on 2026-11-17

`ae2thing-1.3.7.jar` (1.3.7, 2026-11-20; 1.3.4 was added on 2026-11-17) is on the client,
eclipse's debug server and legion. It is side B, so every side needs the same jar.

- Source: [GTNotLeisure/AE2Things](https://github.com/GTNotLeisure/AE2Things), the
  maintained repo its README names for 2.9.0. It continues asdflj's repo, which stops at
  v1.2.14, the build left out on 2.9.0. The jar's sha256 matches the digest GitHub
  lists.
- Built against the pack's own libraries: AE2 `rv3-beta-1095-GTNH`, AE2FluidCraft
  `1.5.116-gtnh`, GTNHLib 0.11.54 and NEI 2.8.171. 1.2.14 wanted 2.8.4's
  `rv3-beta-695` and `AE2FluidCraft 1.4.120`, which is why it was left out.
- What it adds: DISK cells with no type limit, the Infinity Cell (link mode shares one
  item pool across cells and networks), backpack, wireless and dual-interface terminals,
  Thaumcraft infusion and thaumatorium interfaces, crafting completion notifications and
  a fluid packet encoder.
- 1.3.0 adds the Applied Botanics submodule: a fluix mana pool, mana cells from 1k to
  256k, and mana input and output buses. It needs Botania and extends its internals; the
  pack has Botania 1.13.42. 1.3.1 adds NEI auto craft to its crafting terminal, and 1.3.3
  adds a config for modern container interaction in the terminal. 1.3.4 adds a Universal
  Infinity Cell, optimizes infinity storage and its safety checks, reworks the pattern
  modifier, and disables the 2-in-1 terminal when GT-Never-Reset is installed.
- The NEI usage handler in 1.3.4 and 1.3.5 is broken: `InfinityStorageCellUsageHandler` reads
  `this.cell` before assigning it (`InfinityStorageCellUsageHandler.java:80`), so any
  usage lookup can put "There was error during loading recipe" in chat. The handler is
  hidden in `config/NEI/hiddenhandlers.cfg` and showed nothing anyway. Remove that line
  once a release fixes it.
- Config: `config/ae2thing/ae2thing.cfg`, written on the first launch. Kept on 2026-11-17.

## DiskTerminal, added on 2026-11-17

`disk_terminal-1.0.2.jar` (1.0.2, 2026-11-16) is on the client and legion. It is side B, so both need the same jar.

- Source: [GTNotLeisure/DiskTerminal-Unofficial](https://github.com/GTNotLeisure/DiskTerminal-Unofficial),
  a 1.7.10 port of [Aedial's DiskTerminal](https://github.com/Aedial/DiskTerminal). The
  jar's sha256 matches the digest GitHub lists.
- A Cell Terminal part for an ME cable and a Wireless Cell Terminal, linked through the
  Security Terminal. It lists every ME Drive, ME Chest and storage bus with used and total
  bytes, ejects cells to the inventory, previews contents, edits partitions by drag and
  drop, sets priorities, and highlights a block in the world and prints its coordinates.
  It reads AE2FC fluid cells and buses, Thaumic Energistics essentia, NEI drag and drop,
  and GregTech ME buses and hatches.
- 1.0.2 only moves its dependencies to the pack's AE2 `rv3-beta-1095`, AE2FC `1.5.116`,
  GT `5.09.54.265` and NEI 2.8.171; 1.0.1 wanted AE2 `rv3-beta-1080` and AE2FC `1.5.113`.
  GTNHLib is 0.11.52 against the pack's 0.11.54.
- Config: `config/disk_terminal_server.cfg` gates the tabs and the cell operations and has
  to match on both sides; `config/disk_terminal_client.cfg` holds the client display
  options. Both are written on the first launch. Kept on 2026-11-17.

## NEI Guess, added on 2026-11-17

`neiguess-1.0.jar` (1.0, 2026-11-10) is on the client only. It is side C; the server needs
nothing. The jar's sha256 matches the digest GitHub lists.

- A suggestion panel for the NEI search box, in the style of a browser address bar:
  favorites, recent searches merged with NEI's own history, items needed by recently
  viewed unfinished BetterQuesting quests, the most-used terms, recommendations, and the
  item picked last time for the same search. Tab accepts a completion.
- Clicking an item name in chat opens its recipe, Ctrl-click shows its uses and Alt-click
  copies its item id. A `/neiguess` command set handles quest items, favorites, history
  export and stats.
- Chinese search conversion (mod names, ore dictionary names, `@` and `$` prefixes),
  pinyin search through NotEnoughCharacters, and typo correction such as 钻石搞 to 钻石镐.
  The UI is English or Chinese, but the pack has no NotEnoughCharacters, so pinyin search
  does nothing, and the conversions only matter when searching Chinese names.
- Built against NEI 2.8.155, GTNHLib 0.11.52, GTNHExtLib 1.0.5 and BetterQuesting
  3.8.92-GTNH; the pack has NEI 2.8.171, GTNHLib 0.11.54, GTNHExtLib 1.0.5 and the same
  BetterQuesting. The release is from after 2.9.0. Kept on 2026-11-17; it shares the NEI
  search box with Better Search.
- Config: `config/neiguess/neiguess.cfg`, and history and favorites in
  `config/neiguess/history.json`. Extra word lists go in `config/neiguess/lexicon/`.

## Better Foliage, added on 2026-11-17, removed on 2026-11-18, re-added on 2026-11-24

`BetterFoliage-LegacyEdition-2.0.1.jar` (2.0.1, 2026-11-17; 2.0.0 was added first) is on
the client, side C. The jar's sha512 matches the one Modrinth lists.

**Removed on 2026-11-18 for its FPS cost:** 190 FPS fell to 150-160 at the default
features and to 120-140 with more on. 2.0.0 also crashed chunk meshing once on an oak
leaf (`Only quads are supported, got: 66`, through its Angelica mixin). **Re-added on
2026-11-24** with both configs restored from `backups/removed-mods/2026-11-18/`; 2.0.1's
notes still name no performance fix, so the cost may return. `mod-sources.json` is an
added entry again.

- 2.0.0 is a rewrite from Kotlin to Java. It fixes the pitch-black rendering that older
  builds showed under shaders with Angelica 2.0.0-alpha9 or later, plus black leaves from
  extra-leaves ambient occlusion and several invisible-face bugs. That is the issue this
  install is testing.
- Features, each toggleable in its F8 menu: extra leaves, round logs, connected grass,
  short grass and mycelium, falling leaves, algae, coral, reeds, netherrack vines, rising
  souls, better cactus and better lilypads.
- Needs UniMixins, which 2.9.0 ships as `+unimixins-all-1.7.10-0.3.1.jar`; 2.0.0 no longer
  needs Forgelin.
- Config: `config/BetterFoliage_LegacyEdition.cfg`. The old `config/BetterFoliage.cfg`
  from the earlier install is still there and is not read. Its block and biome lists are
  the old format, so any custom entries need redoing as block and biome filters in the
  new file.
- Normal maps and specular textures for extra leaves and short grass are not
  reimplemented yet, so those parts will not react to the PBR packs under Eclipse.

## DEConfig Integration, added on 2026-11-17

`deconfigintegration-1.0.3.D424.jar` (1.0.3.D424, 2026-03-17) is on the client.
It is side C. The jar's sha256 matches the digest GitHub lists.

- Moves the settings of GTNH's gear into Draconic Evolution's config GUI, so one keybind
  replaces the mod-specific ones: IC2 night vision goggles, jetpacks, nano and quantum
  armor and the mining laser; GraviSuite's chestplate, jetpacks, lappack, chainsaw, drill
  and Vajra; GraviSuite Neo's chainsaw treecapitator; Thaumic Boots speed, jump and omni
  modulation; EMT's electric, nano and quantum goggles and travelling boots; Avaritia's
  infinity armor movement stats and node vision; and Witching Gadgets' primordial armor.
- Adds NBT toggles for IC2 quantum sprint and EMT magic vision, and night vision on the
  Avaritia helmet.
- **The build predates 2.9.0.** 1.0.3.D424 is labelled for the March 2026 nightlies, not
  2.9.0 stable, and was compiled against Avaritia 1.78, Draconic Evolution 1.5.19,
  GraviSuite Neo 1.3.8, Thaumic Boots 1.5.5 and Witching Gadgets 1.8.14; the pack has
  1.100, 1.5.35, 1.3.16, 1.5.13 and 1.8.53. It applies its mixins through GTNH Mixins'
  late loader, so a changed target shows as an error at launch instead of doing nothing.
- No config of its own. Kept on 2026-11-17.

## InfoHUD, added on 2026-11-17

`infohud-0.0.25.jar` (0.0.25, 2026-10-22) is on the client. It is side C; the server needs
nothing. The jar's sha256 matches the digest GitHub lists.

- Replaces InGameInfoXML, which is dropped: its jar, `config/InGameInfoXML.cfg` and
  `config/InGameInfoXML/` are in `backups/removed-mods/2026-11-17/`.
- A configurable HUD with a tag-based line editor on `J`: vanilla, item, target, server,
  system, condition, GregTech, Thaumcraft, BloodMagic, Forestry and Nutrition tags, plus a
  classic bar renderer and a light-level overlay toggled on `L`.
- It ships no pack version and was built against GTNHLib 0.9.53, where the pack has
  0.11.54. BloodMagic, Thaumcraft and Baubles Expanded are optional compile-time tags. The
  release is from 2026-10-22, before 2.9.0 stable, so it is unproven. 0.0.25 fixes a crash
  on the first multiplayer join and moves the CPU-load read off the client thread.
- Config: `config/InfoHUD/Layout.json`, `GeneralConfig.cfg`, `LightOverlayConfig.cfg` and
  `ClassicBarConfig.cfg`. Kept on 2026-11-17.

## GTNL, re-added on 2026-11-18

`sciencenotleisure-0.2.7.jar` (GT: Not Leisure 0.2.7, 2026-11-16), `gtnllib-1.1.8.jar`
and `bqapi-1.1.4.jar` are on the client and legion; all three are side B. The sha256 of
each matches the digest GitHub lists. 0.2.7 merged "适配 GTNH 2.9.0 正式版" (#666) and
builds against GT 5.09.54.265, the pack's own. It was removed on 2026-11-10 as too
strong; it's back because the world is solo. Its steam machines (Cactus Wonder and the
rest) have no config switch and stay as they are.

Config edits in `config/GTNotLeisure/` (the rc2.1 files were kept and reused):

- `recipe.cfg`: `enableChamberRecipesBuff=false` [true]; `enableSomethingRecipe=false`
  [true], set before. `enableDeleteRecipe` stays true: it removes the assembly line
  recipes GTNL replaces with its own.
- `machine.cfg`: `enableRecipeOutputChance=false` [true], the bonus output chance per
  voltage tier above the recipe's (2.5% a tier, like QFT).
- `item.cfg`: `elaina_brooch { enabled=false }` [true], which turns off every brooch
  effect (creative flight, death prevention, heals, potion effects). The section is new in
  0.2.7, written by hand ahead of the first launch. `vein_miner_pickaxe { maxRange=-1 }`
  [32]; `maxAmount=1` [327670] was set before.

**The Vein Mining Pickaxe is disabled by `scripts/gtnl_disable_vein_pickaxe.zs`.** It
chains up to 32767 blocks from an LV crafting or assembler recipe. The config caps only
clamp values its GUI has written into the item's NBT, and a fresh pickaxe falls back to a
3-block gap and 32767 blocks (`VeinMiningPickaxe.chainBreak` in 0.2.7), so the config
alone can't stop it. The script removes both recipes and hides it in NEI. The assembler
removal names GT item ids by hand; if `minetweaker.log` says "Could not find recipe to
remove!", check them with `/mt hand`.

The other items were reviewed on 2026-11-18 and left alone. The Portal Gun (LV, cheap
shimmer fuel, crosses dimensions) adds little over Waystones-X's free teleports, and
Elaina's Broom (unlimited flight) is gated behind void-metal Thaumcraft. The Steam Rocket
is tier 1 (Moon only), and the Time Stop Pocket Watch can't be crafted (its infusion asks
`Integer.MAX_VALUE` of each aspect).

GTNL hooks in the other added mods (none changed):

- GT-Steam-Reborn, `config/gtsr/gtsr.cfg`: `gtnlEnhancement` [false] gives GTNL steam
  machines 4x speed at 4x steam when fed real superheated steam, and enables GTSR's cooling
  hatch; `gtnlPipelessSteam` [false] lets GTSR's steam machines draw from GTNL's pipeless
  steam hatch tank. Both off; restart after a change.
- Twist Space Technology: `Debug_remove_sciencenotleisure_CompressedStargateTier7_ExtremeRecipe`
  [true] drops one Mega Crafting Center recipe that runs out of memory with GTNL loaded.
  Keep it on.
- Neo ECO AE Extension uploads patterns into GTNL's Super Crafting Input Hatch (ME) and
  Assembler Matrix; Wildcard Pattern hooks GTNL's pattern slots in the same hatch;
  AE2Things reads GTNL's Yog-Sothoth terminal and its Processing Pattern Terminal size
  (`OtherConfig`). No switches.
- GT:NH Processing+ reuses GTNL's BartWorks materials when GTNL defines the same one,
  instead of registering a duplicate; 123Technology checks whether GTNL is loaded. No
  switches.
- GT-Miao-Blueprint recognises GTNL's steam tree farm hatches; Chromatic Tooltips Compat
  has `scienceNotLeisureEnabled` [true]; NH-Utilities' lang manager lists
  `ScienceNotLeisure`; ChromaPatch gives GTNL's glowing blocks light colours.

## GT-Interesting-Thing, re-added on 2026-11-24

`gtit-v2.1.31.jar` (2.1.31, 2026-11-24; 2.1.6 was the old build) is on the client and
eclipse's debug server, side B. It needs MIAOKATZE Core 0.2.29, already installed. The mod
adds the Neko Vending Machine shop, Neko Coins, a BQ quest line, rings, flight cores, the
ore scanner, the Infinity Cell and the dimensional pocket.

The shop is set to the `ae-storage-only` preset in `MiaoTrade/ae-storage-only.json`:
cables, terminals, network/power, drives and cells, and panels/buses, with the
auto-crafting/interface page dropped and the Creative Energy Controller, security
terminal, pattern/interface terminals and crafting/acceleration cards removed. Apply it
with `/gtit presets`; the preset's exclusion list deselects `gtit-base`. The preset is on
the client and the debug server; copy it to legion if you use the shop there.

## Left out until their author ships a 2.9 build

- **BoxPlusPlus 2.1.2**: last release 2025-12-10, built against Galaxy Space 1.1.121.
  It sits on GT multiblock internals, which 2.9 rewrote across more than fifty machines.

Check it again after its next release; it has no 2.9 build.

## Installed, still unproven on 2.9

These are in the 2.9 instance but have no explicit 2.9 release, so a launch is the proof.

- **Xaero's Minimap 21.10.44 and World Map 1.14.1.33** (2026-11-07, client only): the
  last 1.7.10 Forge builds, from Modrinth, and the CurseForge files Navigator 1.1.10
  compiles against (`dependencies.gradle`). They replace JourneyMap, which is disabled.
  Angelica#1851, a crash on opening NEI, was closed 2026-06-11.
- **Angelica#2092** (open, checked 2026-11-07): Xaero's World Map crashes the game with
  an `OpenGLException` when Witching Gadgets' Thaumic Stone Extruder is on screen and a
  resource pack retextures lava. The Extruder's model uses the active lava texture. Both
  Modernity packs ship `assets/minecraft/textures/blocks/lava_still.png` and
  `lava_flow.png`, each with a `.png.mcmeta`. Rather than editing the Modernity zips,
  which an update replaces, the folder pack `resourcepacks/VanillaLava/` (2026-11-07)
  holds a `pack.mcmeta` and the four vanilla lava files from
  `~/.local/share/PrismLauncher/libraries/com/mojang/minecraft/1.7.10/minecraft-1.7.10-client.jar`.
  It sits right after both Modernity packs in `options.txt`'s `resourcePacks`, where
  later entries override earlier ones, so it shows above them in game. Keep it above
  any new pack that retextures lava. Untested against the crash itself; if it still
  happens, remove `XaerosWorldMap_*.jar` until the issue is fixed.

- **Angelica 2.2.45** (2026-11-08, client only): replaces the pack's 2.2.43 for the shader
  fix for flat item icons on drawers and barrels, and 2.2.44's fix for black patches over
  the world. Angelica#2092 (the Xaero crash) is still open. Mods that patch Angelica can break
  on a bump: check ChromaPatch and the shaders, Distant Horizons and
  Xaero's maps at launch.

- **Angelica 2.2.46** (2026-11-13, client only): restores FluidLogged and LiquidLogged
  fluid rendering, fixes LOTR compatibility and a world client leak, adds a weather API
  for mods, and tags profiler captures with its version. Angelica#2092 is still open, so
  the Xaero workaround above still applies. Check ChromaPatch and the shaders, Distant
  Horizons and Xaero's maps at launch.

- **Angelica 2.2.47** (2026-11-23, client only): translucency sorting improvements, early
  TESR draws, layer and terrain split, glow depth and depth peeling, and flowing water
  through LiquidLogged blocks. Angelica#2092 is still open. Check ChromaPatch and the
  shaders, Distant Horizons and Xaero's maps at launch.

- **Realistic World Gen 2 2.1.2** (2026-11-14, client and legion): keeps one landmark per
  river junction, improves `runPreview`, and renames `rwg_data.dat` so it stops clashing
  with the RWG 1.5.3 jar in the same `mods/`. `rwg2.cfg` is unchanged, so `Biome Size
  Multiplier` stays at 1.7.

- **Realistic World Gen 2 2.1.1** (2026-11-08, client and server): replaces the
  pack's `rwg2-2.0.6.jar`. Builds against GTNHLib 0.11.54 and NEI 2.8.171, the versions 2.9
  ships. Adds climate bands, per-continent Tainted Land and the `Biome Size Multiplier`,
  set to 1.7 in `config/rwg2.cfg` under `continental rwg` (default 1.0, range 0.25 to 10).
  Only `RWG2_CONTINENTS` worlds read it, and changing it on an existing world leaves borders
  between old and new chunks, so it's for a new world. The server's `rwg2.cfg` has it at 1.7 too.

- **Distant Horizons `upstream-preview8-rple-biomes`** (2026-10-18): the 2.8.4 jar was
  `alpha18`; this is the newest build and the first from the 2.9 period. Enable
  Aggressive Chunk Loading under Video Settings, Performance, to stop transparent
  chunks. `config/DistantHorizons.toml` has (checked 2026-11-07)
  `lodChunkRenderDistanceRadius=256`, HIGH horizontal and vertical quality,
  `numberOfThreads=6` (16 took every CPU thread from the game; it's raised to 16 only to
  build LODs fast in a test world, then set back), `threadRunTimeRatio="1.0"`,
  `enableCaveCulling=false` with a height of 60 and `enableCloudRendering=false`; the
  client generator is
  `PRE_EXISTING_ONLY` because the server now builds the LODs. The server runs the same
  jar with `chunkGeneratorMode="INTERNAL_SERVER"`, `generatorPlan="CHUNKS_ONLY"` (the only plan
  the GTNH build's settings offer),
  `pauseIfMovingQuickly=false`, four threads at a 0.5 ratio, a 128 chunk generation
  distance and no bandwidth limit on the LAN. The 2.8.4 setup also picked Quality Preset
  High and CPU Load Balanced in the mod's settings. Known issues are unchanged: memory
  creep, unstable server side, and LODs that need a render-distance toggle to refresh.
- **Dynamic Surroundings 1.0.9.0** (2026-09-30): mist475's 1.7.10 fork, newer than the
  2.8.4 jar's 1.0.7.7; adds Seasonal Horizons compatibility.
- **Sound-Physics 1.1.1** (2026-06-27): the 1.7.10 mixin edition.
- **ChromaPatch 1.0.3** (2026-11-13, installed 2026-11-15): builds the patched Eclipse
  shader pack at launch. The asset names 1.7.10, not 2.9, so the launch is the test. 1.0.3
  brings its own GTNH patch with about 1600 more GTNH blocks lit, tinted or waving, and
  FSR fixes for GregTech multiblock effects and sign text; see
  [shaders.md](./shaders.md#eclipse-with-chromapatch).
- **Euphoria Patcher 1.9.3** is installed to match the NeonTech settings. 1.10.5 exists,
  but moving to it means copying the NeonTech values by hand.
- **BetterSprinting 1.1.3**: 2.3.0's coremod fails on 2.9 at the
  `EntityPlayerSP.onLivingUpdate` insertion point. 1.1.3 hooks through PlayerAPI 1.5.0
  instead, which the pack ships, and was installed on both sides on 2026-11-03 to test.
  It gives sprint toggle, sneak toggle and fly boost, not step assist. Newer versions break
  it, so the `gtnh-mod-updates` skill leaves it out of its checks.
- **Advanced Memory Card 1.2.0-1.7.10-GTNH** (2026-11-02): AE2 memory card with bulk
  configuration copy and P2P tunnel management. Declares no dependencies beyond AE2, and
  the copy volume defaults to 2048 blocks.
- **[WTCT](https://github.com/233max258/Wtcts-1.7.10) 1.0.63-rc1** (2026-10-11; the jar's
  hash matches that release, checked 2026-11-06): ME combined work terminal, 63-slot extended buses,
  pattern auto-upload, wireless transceiver and upgrade cards. Built against 2.9.0-RC-1
  and AE2 `rv3-beta-1073`; the pack runs `rv3-beta-1095`, so the launch is the test. It
  ships `en_US.lang`.
- **[GTNH Planner](https://github.com/jackwrichards/gtnh-planner-mod) 0.2.0-beta.3**
  (2026-11-09, client only; hash matches the release): in-game factory flowchart
  planner built on PlanNH. Add recipes from NEI with `+`, set a target rate or machine
  count, and it works out tiers, overclocks and machine counts. The planner button is at
  the bottom left of the inventory. The release says "Works on every GTNH 2.9 build
  from beta-1 to RC-2" and builds against RC-2's NEI 2.8.155, GTNHLib 0.11.52 and
  ModularUI2 2.3.92; it doesn't name 2.9.0 stable, so the launch is the test. Every
  release so far is a beta or alpha, though GitHub marks them stable. Plans save to
  `gtnhplanner/plans.dat` with backups beside it. Signing in to gtnhplanner.com (for
  cloud saves, shared plans and live co-editing) is optional, but the mod checks for
  updates and its bug key sends crash reports there.

## Dropped after testing

- **Smooth Third-Person Camera 2.0.0 and Cinematic Respawn 1.5.0** (added 2026-11-19,
  removed by 2026-11-20): both had issues in game and were taken out by hand. They are
  parked in `mod-sources.json`; on a retry, test Smooth Third-Person Camera together with
  Shoulder Surfing Reloaded, which drives the same camera. Their configs are still in
  `config/` (`smooththirdpersoncamera.json`, `cinematic_respawn.properties`).

- **BetterSprinting 2.3.0**: its coremod cannot find its `EntityPlayerSP.onLivingUpdate`
  insertion point under 2.9 and aborts the launch with "Could not find insertion point".
  The 1.1.3 jar is installed instead (see above).

- **deconfigintegration 1.0.2**: its late mixins still declare Draconic Evolution's
  `IConfigurableItem` interface on IC2 and Avaritia classes. 2.9's Draconic Evolution no
  longer has that class, the failed transform poisons the class cache, and Avaritia then
  aborts pre-init with `NoClassDefFoundError`. Removed; each mod's own config file is
  enough.

- **Fancy Block Particles 2.4.1** (removed 2026-11-17): it needed Angelica's Particle
  Batching disabled to stop particles rendering at the hand (Angelica#2237), which cost
  particle batching for the whole pack, so it was not worth keeping. Its jar is in
  `backups/removed-mods/2026-11-17/`; `enable_deferred_batching` is back to `true` and
  `config/FBP/Particle.properties` is back to `fancyRain=true` and `fancySnow=true`.

- **Functional Storage 1.2.3** (removed 2026-11-17): Storage Drawers already covers the
  drawer and controller role, and its fluid and essentia drawers and generator upgrades
  were not needed. Its jar and `config/functionalstorage/` are in
  `backups/removed-mods/2026-11-17/`.

- **Spark 1.10.19** (removed 2026-11-18): its async profiler crashes the JVM on Java 25
  (`SIGSEGV` in `VMThread::nativeThreadId`, 2026-11-10), and LagGoggles, Opis and JFR
  cover profiling. The jar is in `backups/removed-mods/2026-11-18/`.

- **Touhou Little Maid** (`touhou_little_maid-bc127db.jar`, a 1.7.10 port; tried and
  dropped 2026-11-18): it crashed five times that day, on a creeper spawn
  (`ClassCastException` in `CreeperJoinWorldEvent`), in two render handlers with an empty
  hand and on using a model coupon. `config/touhou_little_maid/` and
  `touhou-little-maid-server-pack/` are in `backups/removed-mods/2026-11-18/touhou_little_maid/`.

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
  `/warp` commands this setup enables. Keep or drop by preference; neither fights the
  other.
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
  1.8.3 (rechecked on the 2026-11-15 bump).
- **`scripts/gtnl_disable_vein_pickaxe.zs`**: written 2026-11-18. It removes GTNL's Vein
  Mining Pickaxe recipes and hides it in NEI; see
  [GTNL, re-added](#gtnl-re-added-on-2026-11-18). The server needs it too. **On a
  dedicated server the assembler removal misses at startup** ("Could not find recipe to
  remove!", tested 2026-11-19): GTNL adds that recipe after MineTweaker's first script
  pass. `minetweaker reload` in the console once the server is up removes it. In Omni
  Server, a quick command "MineTweaker reload" (`minetweaker reload`) with **Run when the
  server has started** on sends it at each start; the laptop's `gtnh` launcher
  (`machines/legion/minecraft-servers/gtnh-server.nix`) does the same. `start.sh`
  doesn't. Single player isn't affected, and the crafting-table recipe
  and NEI hiding work either way.

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

The per-mod settings for GTNHRates, EZNuclear and NH-Utilities are in
[config-tweaks.md](./config-tweaks.md#added-mod-configs).
