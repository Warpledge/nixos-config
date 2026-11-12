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
| Twist Space Technology | 0.8.0 | B | release 2026-11-02 includes the 2.9 fix (PR #1386); 0.8.1 crashes world start, see below |
| 123Technology | 2.2.1.1 | B | 2.2.1's release notes say it's adapted to 2.9.0 stable |
| EZMiner | 6.4 | B | 6.4 fixes a toolbox crash; still built against `2.9.0-beta-3` |
| EZNuclear | 1.1.1 | B | README table: 2.9+ uses 1.0.8 to 1.1.1 |
| EZStorage | 1.8.2 | B | builds against GTNHLib 0.11.52, NEI 2.8.158 |
| Programmable Hatches | 0.2.1p7-beta | B | p7 notes: only 2.9.0 supported; builds against GT 5.09.54.264, GTNHLib 0.11.54, NEI 2.8.171 |
| NH-Utilities | 1.7.0 | B | commit "Fit 29x" |
| YesSteveModel Unofficial | 2.8 | B | [czqwq fork](https://github.com/czqwq/YesSteveModel-Unofficial); 2.8's `dependencies.gradle` sets `gtnhVersion = "2.9.0"`; 2.6 fixes the animation loop and 2.7 restores the animation storage system; 2.5 disabled the lighting map |
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

## Installed on 2.9.0 only

These are not carried from 2.8.4; they went in on top of 2.9.0 on 2026-11-02, client and
server, and the server boots with all of them.

| Mod | Build | Side | Note |
| --- | --- | --- | --- |
| Waystones-X | 1.0.16 | B | [JackOfNoneTrades fork](https://github.com/JackOfNoneTrades/WaystonesFork) of BlayTheNinth's mod; `config/waystones.cfg` sets `xpBaseCost=-1` |
| MIAOKATZE Core | 0.2.14 | B | required by the three Miao mods below, on both sides; the three bundle it in their release assets, all updated together on 2026-11-12 (Core's release says compatible with 2.9.0 final) |
| GT-Miao-Blueprint | 0.3.26 | B | Neko Blueprint Hologram Projector: blueprint, cut and demolition modes |
| GT-Steam-Reborn | 2.1.42 | B | steam industry, hubs and nodes, singularity tech, the Prosperity dimension, portable weapons, a BQ line |
| GT-Simple-Wireless-Network | 2.1.28 | B | wireless EU link nodes, monitors, ME quantum terminal |

All but Waystones come from [MIAOKATZE](https://github.com/MIAOKATZE) and are tagged
"for GTNH 2.9.0 stable". Their `en_US.lang` files are complete, so the in-game text is
English; the READMEs are Chinese. GT-Miao-Blueprint needs Applied Energistics and
StructureLib, GTSWN needs AE2, GTSR only GregTech. Since 2026-11-03
123Technology's overpowered recipes are off; the values are in
[config-tweaks.md](./config-tweaks.md#balance-edits-2026-11-03).

One more joined them later on 2026-11-02, client and server:

| Mod | Build | Side | Note |
| --- | --- | --- | --- |
| ThinkTech | 0.3.2 | B | chemistry and materials: briquettes, methane clathrate, catalysts, computing chips, explosives (PETN, HMX, HNIW), separation control cores |

TenkeiTech 1.1.0 was installed with it and removed the same day: it hands you an
"Useless Tools" staff on spawn with force kill, spawn eggs, area damage, bedrock mining
and time acceleration modes, and the AE automation it adds was not worth that. Its jar and
`config/tenkeitech.cfg` are gone from both sides and FML removed its items from the world.

Four client-side additions on 2026-11-02:

| Mod | Build | Side | Note |
| --- | --- | --- | --- |
| World Tooltips | 1.2.3-87 | C | floating tooltip over dropped items; shader-compatible continuation of GenuineSounds' mod; [source code](https://github.com/kotmatross28729/WorldTooltipsShadersFix) |
| MyCTMLib | 1.4.4-290 | C | connected-texture support for resource packs |
| OmniOcular Unofficial | 1.7.2 | B | WAILA add-on showing machine internals; client full jar, server `-server.jar`; see the scripts note below |

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
these files, so new Chinese strings would need translating again. From 1.7.x the mod can
pull config from the GTNH repo; back these scripts up before a bump. The client's
`forceUseClientXml` ignores server config. 1.7.2 still stalls on the config merge for
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
| Vintage Pick Up Notifier | 1.0.0 | C | item pickup notices |
| Vintage Resourcify, with AngelLib 1.0.1 | 1.0.6 | C | in-game resource and shader pack browser |
| Better Search | 1.6.2 | C | typo-tolerant search, with NEI and AE2 hooks |
| Effortless Building Gadgets | 0.10.1 | B | shape building through a crafted gadget; `B:consumesEnergy=false` on both sides, so it needs no power |
| Shoulder Surfing Reloaded | 2.4.1 | C | over-the-shoulder camera; a 2023 build that patches vanilla code, so suspect it first after a pack update |

Vintage Resourcify lists `forgelin-legacy` as required. It has the same `forgelin` mod id
as the pack's `forgelin-2.0.3-GTNH.jar`, so it was left out and runs on the pack's copy.

Right Proper GUI Scale 2.1.1 is also on the client. It keeps the scale as a decimal in
`options.txt` (`guiScale:3.5`, between vanilla's 3 and 4) and applies a change when the
settings screen closes, so it can look like nothing happened. `/guiscale` sets it in game.

Neo ECO AE Extension 7.3.10 is on the client (2026-11-11; server still 7.3.7), on trial since
2026-11-05: three tiered AE2 multiblock systems for storage, crafting and computation, an
optional upgrade path rather than a replacement for normal AE2. Both sides must match.
Modrinth lags the official 1.7.10 repo
([Yang120231/GTNH-ECO-1.7.10](https://github.com/Yang120231/GTNH-ECO-1.7.10), 7.3.10 on
2026-11-11 against Modrinth's 7.3.7), so `mod-sources.json` checks GitHub. Its 7.3.10 notes
name GTNH 2.9.0-RC1 and later.
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
| GTNH Modernization Upgrade | 0.3.5-alpha | B | Structure terminal (project, build, replace and dismantle a GT multiblock from its StructureLib definition), ME packing tape, integrated 36-pattern item, AE order element, colour power budget for the Plasma Forge and fusion, and an ME storage vault. Alpha, one author, AI-written; the vault keeps inventory in `<world>/data/aestoragevault/`, and 0.3.0 changed that format without reading 0.2.x |
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

## Smooth Swapping, written for this setup on 2026-11-10

`smoothswapping` 0.6.0 animates item stacks moving between slots, client only. It is a
rewrite of the 1.20.1 mod's behaviour, not its code: upstream's licence is unset and its
renderer is Fabric's `DrawContext`, neither of which transfers. Source is
`~/Projects/smoothswapping`, built with GTNH's ExampleMod starter.

- Compares the open container at the top of every `GuiContainer.drawScreen`, pairs what
  left a slot with what arrived in another, and draws the pair on a quadratic arc at the
  end of that same frame. The destination slot is hidden while its copy travels, and
  detecting before the slots are drawn is what stops the stack showing there first and
  then flashing out.
- Config screen behind the Mods list: speed from 50 to 1000 (default 300, which is 200 ms),
  curve from 0 to 1 of the distance (default 0.35) and an on/off toggle. Settings save to
  `config/smoothswapping.cfg` and apply to the next move.
- Only `GuiContainer` screens animate. GT and AE ModularUI screens do not, and moving a
  stack onto the cursor is not animated yet, because hiding the GUI's own cursor stack
  needs its own hook.

## Left out until their author ships a 2.9 build

- **AE2Things 1.2.14**: built against 2.8.4's AE2 `rv3-beta-695`, `AE2FluidCraft 1.4.120`
  and `ae2stuff`, which 2.9 removed. AE2 was unified for items, fluids, gasses and
  essentia, so the mod's internals do not match the pack.
- **BoxPlusPlus 2.1.2**: last release 2025-12-10, built against Galaxy Space 1.1.121.
  It sits on GT multiblock internals, which 2.9 rewrote across more than fifty machines.

Check these again after their next release; none has a 2.9 build.

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
- **ChromaPatch 1.0.2** (2026-11-05): builds the patched Eclipse shader pack at launch;
  see [shaders.md](./shaders.md#eclipse-with-chromapatch).
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

The per-mod settings for GTNHRates, EZNuclear and NH-Utilities are in
[config-tweaks.md](./config-tweaks.md#added-mod-configs).
