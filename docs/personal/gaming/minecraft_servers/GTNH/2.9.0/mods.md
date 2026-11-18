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
| EZMiner | 6.6-balanced.4 | B | local fork of 6.6 at `~/Projects/ezminer-balanced`; ten Tinkers tiers, axe tree felling, feature switches and a player-placed-only Block Swap, see below. 6.4 fixed a toolbox crash; 6.5 and 6.6 add a config validation tooltip and fix its message system, and 6.6's `dependencies.gradle` sets `gtnhVersion = "2.9.0"` |
| EZNuclear | 1.1.1 | B | README table: 2.9+ uses 1.0.8 to 1.1.1 |
| EZStorage | 1.8.3 | B | builds against GTNHLib 0.11.52, NEI 2.8.158; 1.8.3 fixes NEI bookmark pull with large stacks |
| Programmable Hatches | 0.2.1p7-beta | B | p7 notes: only 2.9.0 supported; builds against GT 5.09.54.264, GTNHLib 0.11.54, NEI 2.8.171 |
| NH-Utilities | 1.7.0 | B | commit "Fit 29x" |
| YesSteveModel Unofficial | 3.0 | B | [czqwq fork](https://github.com/czqwq/YesSteveModel-Unofficial); 3.0's `dependencies.gradle` sets `gtnhVersion = "2.9.0"`, and its one commit says "Fix Amim system"; 2.9 added the preview setting's entrance and fixed the math parser, 2.6 fixed the animation loop and 2.7 restored the animation storage system, 2.5 disabled the lighting map |
| MineMenu | 1.2.0.B44 | C | latest on Modrinth, 2025-12-07 |
| Spark | 1.10.19 | C | latest 1.7.10 |
| FPS Reducer | 1.10.3 | C | latest, 2023-09-06 |
| Trash Slot | 1.0.31 | B | latest 1.7.10 on CurseForge |

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

**The 2026-11-15 update is on the client only, thirteen jars.** Side B, so legion needs
the same ten before a world can be joined: EZMiner 6.6, EZStorage 1.8.3, YesSteveModel
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
day on the client; legion still needs 7.3.12 and the rest of the side B jars above. Not
launched yet.

**The 2026-11-16 update is on the client only:** 123Technology 2.2.1.3 and MyCTMLib
1.4.6-290. 123Technology is side B, so legion needs 2.2.1.3 before a world can be joined.
Its release adds a Positron_e+ artillery piece, AbstractSanctum and Steam9in1 fixes and a
Fishtorio loot-table blacklist update, and its body says it contains WIP content.
`123Technology.cfg` has the same 14 options, so the edits in
[config-tweaks.md](./config-tweaks.md) stand. MyCTMLib adds JSON models for the redstone
torch, repeater and comparator and renames a config node (`mc` to `minecraft`); the agent's
table was re-keyed for two strings 123Technology moved between classes, and its one new
string is a log line, left untranslated. Old jars are in `backups/replaced-mods/2026-11-16/`.
Not launched yet.

**The 2026-11-17 update is on the client only, eight jars.** Side B, so legion needs the
same eight: YesSteveModel Unofficial 3.0, MIAOKATZE Core 0.2.21, GT-Miao-Blueprint
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

**2026-11-18: EZMiner is now Omni Miner, the local fork `6.6-balanced.7`, client only so
far.** The source is still `~/Projects/ezminer-balanced`; the jar is
`mods/omniminer-6.6-balanced.7.jar`, and the old jars are disabled beside it
(`EZMiner-6.6-balanced.jar.bak-2026-11-18.disabled`,
`omniminer-6.6-balanced.5.jar.bak-2026-11-18.disabled` and
`omniminer-6.6-balanced.6.jar.bak-2026-11-18.disabled`). The mod id is `omniminer`, so
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
list under `tools { }`; the OP server tab opens a NEI-style editor per family with icons,
a search box, hover name and id, right-click removal and a list reset. The unbound
`Add Block to Tool List` key adds the block under the cursor or the NEI item under the
mouse (Shift removes). The server allows that only for OPs, a cheats-enabled
single-player world, or the server-owner list. The GUI cycles named options instead of
numbered fields, every row has an `R` reset button, and Block Swap's preview now shows
every matching block in the swap radius instead of a connected chain.
`stopOnUnbreakable` and `fireBreakEvent` stay true, `smallRadius=1`,
`addExhaustion=0.01`, `breakPerTick=128`, and the tier table is unchanged. Side B, so
legion needs the same jar and no `EZMiner` jar before a world can be joined: the mod id
changed, so a client without it is rejected by a server that still has EZMiner.

**2026-11-10: GTNL and GTNLLib were removed; Better Questing API went with them.** BQ API
was installed on 2026-11-01 for GTNL's quest lines, so it is unused now and its jar is gone
from `mods/`; the pack's BetterQuesting stays. GTNL's Steam Revolution machines (Cactus
Wonder, Steam Circuit Assembler, Steam Assembly Line) shortcut the steam age; the Cactus
Wonder alone outputs up to 32M L/s. The GTNL jars are in `backups/removed-mods/2026-11-10/`.

**ElytraMining, SharedProspecting, BetterLineBreak and GTIT were removed on 2026-11-10;**
their jars are in `backups/removed-mods/2026-11-10/`. VisualProspecting 1.5.42 in 2.9.0
already shares within GTNHLib teams; SharedProspecting only bridged ServerUtilities teams.
BetterLineBreak only changes line breaks for non-alphabetic languages.

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
| MIAOKATZE Core | 0.2.21 | B | required by the three Miao mods below, on both sides; the three bundle it in their release assets, all updated together on 2026-11-17 (Core's release says compatible with 2.9.0 final) |
| GT-Miao-Blueprint | 0.3.34 | B | Neko Blueprint Hologram Projector: blueprint, cut and demolition modes; 0.3.34 adds public library permissions, a projector address and QR code, and selection fixes |
| GT-Steam-Reborn | 2.1.52 | B | steam industry, hubs and nodes, singularity tech, the Prosperity dimension, portable weapons, a BQ line; 2.1.52 adds dimension-bound stone making and retires the legacy natural singularity item |
| GT-Simple-Wireless-Network | 2.1.39 | B | wireless EU link nodes, monitors, ME quantum terminal; 2.1.39 groups terminal controls and adds a network information screen |

All but Waystones come from [MIAOKATZE](https://github.com/MIAOKATZE) and are tagged
"for GTNH 2.9.0 stable". Their `en_US.lang` files are complete, so the in-game text is
English; the READMEs are Chinese. GT-Miao-Blueprint needs Applied Energistics and
StructureLib, GTSWN needs AE2, GTSR only GregTech. Since 2026-11-03
123Technology's overpowered recipes are off; the values are in
[config-tweaks.md](./config-tweaks.md#balance-edits-2026-11-03).

One more joined them later on 2026-11-02, client and server:

| Mod | Build | Side | Note |
| --- | --- | --- | --- |
| ThinkTech | 0.3.3 | B | chemistry and materials: briquettes, methane clathrate, catalysts, computing chips, explosives (PETN, HMX, HNIW), separation control cores; 0.3.3 fixes the implosion generator's power display and structure and the crucible recipes for Nichrome and Platinum |

TenkeiTech 1.1.0 was installed with it and removed the same day: it hands you an
"Useless Tools" staff on spawn with force kill, spawn eggs, area damage, bedrock mining
and time acceleration modes, and the AE automation it adds was not worth that. Its jar and
`config/tenkeitech.cfg` are gone from both sides and FML removed its items from the world.

Four client-side additions on 2026-11-02:

| Mod | Build | Side | Note |
| --- | --- | --- | --- |
| World Tooltips | 1.2.3-90 | C | floating tooltip over dropped items; shader-compatible continuation of GenuineSounds' mod; [source code](https://github.com/GTNotLeisure/WorldTooltipsContinuation) |
| MyCTMLib | 1.4.6-290 | C | connected-texture support for resource packs; builds against GT 5.09.54.265, the GT in 2.9.0 |
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
10+ seconds at startup; the fix is in a commit after the release.

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
| Vintage Resourcify, with AngelLib 1.0.2 | 1.0.6 | C | in-game resource and shader pack browser; 1.0.2 marks server list pings with port 0 rather than a hostname suffix, so e4mc worlds stop showing as "Unknown server" |
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
| GTNH Modernization Upgrade | 0.3.6-alpha | B | Structure terminal (project, build, replace and dismantle a GT multiblock from its StructureLib definition), ME packing tape, integrated 36-pattern item, AE order element, colour power budget for the Plasma Forge and fusion, and an ME storage vault. 0.3.6 adds order diagnostics and a storage vault lighting fix under Angelica. Alpha, one author, AI-written; the vault keeps inventory in `<world>/data/aestoragevault/`, and 0.3.0 changed that format without reading 0.2.x |
| AE2 Wireless Transceiver | 1.2.1 | B | [peco331](https://github.com/peco331/AE2WirelessTransceiver-GTNH) fork; each release ships a plain 2.9 asset and a separate `-gtnh2.8.4` one, and the plain one is installed |
| Benzene Fuels | 0.5.1-alpha | B | Eight staged benzene fluids from LuV to UIV and the Resonance Fuel Generator; needs GoodGenerator and GT++ ([arturia-Xayah](https://github.com/arturia-Xayah/gtnh-benzene-fuels)) |
| GT:NH Processing+ | 0.2.5.3-alpha | B | New processing chains built on materials chemistry, meant to fill progression gaps ([shusidefloof](https://github.com/shusidefloof/GTNH-ProcessingPlus)) |
| MouseSideButtonFix | 1.0 | C | Binds the mouse side buttons, which 1.7.10 ignores ([asdflj](https://github.com/asdflj/MouseSideButtonFix)) |
| Patchee | 1.7.3 | B | Cross-mod fixes: JABBA Dolly carries single-block bee housings, Tinkers' Mattock digs sand and snow at shovel speed, a filled Super Tank or Super Chest stops applying its effects to the carrier, VeinMiner stays server-controlled, ServerUtilities team chunk limits read the best member's rank instead of summing, F7 marks only pitch-dark blocks, and the Twilight Forest aurora and arctic fur blocks break faster once earned. No public page, so update checks report it as no-source |
| Thaumic Duality Interface | 1.0.2 | B | ME essentia dual interface as a block, item part and P2P tunnel ([CaelixOrbit](https://github.com/CaelixOrbit/ThaumicDualityInterface)) |
| Wildcard Pattern | 1.1.1 | B | AE2 processing pattern with configurable name and ore-dictionary matching that expands into real patterns ([clfpwp](https://github.com/clfpwp/WildcardPatternforGTNH-1.7.10)) |
| LagGoggles | 4.17.0 | B | Profiler; built against FalsePatternLib 1.10.7 while the pack ships 1.12.2, so loading is the proof. It moved here from the left-out list |

## EZStorage craft fix, written for this setup on 2026-11-10

`ezstoragecraftfix` 0.4.0 patches Simple Storage (`ezstorage`) crafting, client only so
far; the laptop's server `mods/` needs the same jar before the server benefits, and there
is no persistent server world yet. Source is `~/Projects/ezstorage-craftfix`, MIT like
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

`smoothswapping-1.0.0.jar` animates item stacks moving between slots, client only. It's a
port of [Schauweg's Smooth Swapping](https://github.com/Schauweg/Smooth-Swapping) (branch
`1.20.1/dev`), which is LGPL-3.0, so the port is LGPL-3.0 too and credits upstream in its
`NOTICE`. Source is `~/Projects/smoothswapping` (own git repo, tag `1.0.0`), built with
GTNH's ExampleMod starter. It replaces a 0.6.0 rewrite from 2026-11-10 that didn't work and
was deleted; that one's settings are in `config/smoothswapping.cfg.old-2026-11-10`. Tested
in game on 2026-11-17: every case below works, and all eight mixins apply with no warnings
in `logs/fml-client-latest.log`.

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

## Dashboard, added on 2026-11-15

`dashboard-1.0.22.jar` (1.0.22, 2026-11-11) is on the client only. It is GTNH's own HUD
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

`ae2thing-1.3.4.jar` (1.3.4, 2026-11-17) is on the client only so far. It is side B, so
legion needs the same jar before a world can be joined.

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
- Config: `config/ae2thing/ae2thing.cfg`, written on the first launch. Kept on 2026-11-17.

## DiskTerminal, added on 2026-11-17

`disk_terminal-1.0.2.jar` (1.0.2, 2026-11-16) is on the client only so far. It is side B, so
legion needs the same jar before a world can be joined.

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

## Better Foliage, added on 2026-11-17

`BetterFoliage-LegacyEdition-2.0.0.jar` (2.0.0, 2026-11-16) is on the client. It is client
only; the server has no use for it. The jar's sha512 matches the one Modrinth lists.

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
- Kept on 2026-11-17.

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

- **Realistic World Gen 2 2.1.2** (2026-11-14, client only so far): keeps one landmark per
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
  `numberOfThreads=6` (16 took every CPU thread from the game), `threadRunTimeRatio="1.0"`,
  `enableCaveCulling=false` with a height of 60 and `enableCloudRendering=false`; the
  client generator is
  `PRE_EXISTING_ONLY` because the server now builds the LODs. The server runs the same
  jar with `chunkGeneratorMode="INTERNAL_SERVER"`, `generatorPlan="SURFACE_THEN_CHUNKS"`,
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
