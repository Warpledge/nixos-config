# GTO 0.6.0 Added Mods

The jars added by hand to dev27, on top of the pack's 157. Descriptions come from each
jar's `META-INF/mods.toml`.

## Before the staging setup

| Jar | Mod | What it does |
| --- | --- | --- |
| `DistantHorizons-3.3.3-1.20.1-fabric-forge.jar` | Distant Horizons | Renders simplified terrain past the normal view distance |
| `KeepStepping-Forge-1.20.1-1.0.0.jar` | Keep Stepping | Toggles smooth step-up, auto jump, or neither |
| `Resourcify (1.20.1-forge)-1.8.7.jar` | Resourcify | In-game browser for resource packs, data packs and shaders |
| `touhoulittlemaid-1.5.3-forge+mc1.20.1.jar` | Touhou Little Maid | Maid companions |
| `ysm-2.6.5-forge+mc1.20.1-release.jar` | Yes Steve Model | Replaces the player model (GeckoLib based) |

Distant Horizons, Touhou Little Maid and Yes Steve Model were also in the 0.5.6
instance at the same versions. dev27 ships Embeddium, Oculus and Xaero's maps itself.

## From Cosmic Frontiers (2026-11-07)

Passed a staging trial in a new world on 2026-11-07, then copied to main. The Diagonal
mods from the same batch crashed on tag reload and were dropped
([candidates.md](./candidates.md#skip)).

| Jar | Mod | What it does |
| --- | --- | --- |
| `Presence Footsteps [FORGE] 1.0.0.jar` | Presence Footsteps | Footstep sounds by surface (Forge port) |
| `sound-physics-remastered-forge-1.20.1-1.5.1.jar` | Sound Physics Remastered | Sound attenuation, reverb and absorption through blocks |
| `coolrain-1.20.1-Forge-1.0.3.jar` | Cool Rain Reforged | Rain visuals |
| `entity_model_features-3.3.12-1.20.1-forge.jar` | Entity Model Features | Custom entity model (CEM) resource pack support |
| `entity_texture_features-7.2.7-1.20.1-forge.jar` | Entity Texture Features | Resource-pack entity texture features; EMF needs it |
| `smoothswapping-0.9.3.2-1.20.1-forge.jar` | Smooth Swapping | Animates items moving in inventories |
| `better_climbing-forge-3.jar` | Better Climbing | Climbing improvements |
| `connectiblechains-forge-1.20.1-2.2.5.jar` | Reconnectible Chains | Decorative chains between fences |
| `zipline-forge-1.20.1-1.3.0.jar` | Ziplines: Rezipped! | Ziplines |
| `trashslot-forge-1.20.1-15.1.5.jar` | TrashSlot | Trash slot in the inventory screen |
| `creeperoverhaul-3.0.2-forge.jar` | Creeper Overhaul | Biome-specific creepers |
| `endermanoverhaul-forge-1.20.1-1.0.4.jar` | Enderman Overhaul | Biome-specific endermen |
| `fzzy_config-0.7.7+1.20.1+forge.jar` | Fzzy Config | Library; Simply Swords needs it |
| `yet_another_config_lib_v3-3.6.6+1.20.1-forge.jar` | YACL | Library added for Sounds and MRU, which called it without declaring it; no remaining mod declares it |

Kotlin for Forge, which Fzzy Config needs, already ships in dev27. Sounds, MRU,
Particular and Particle Core were removed on 2026-11-08
([candidates.md](./candidates.md#skip)).

**Configs:** `config/zipline.json` sets `consumeDurability` false, so ziplining doesn't
wear the item (2026-11-08). EMF, ETF and Presence Footsteps crashed a dedicated server in
Cosmic Frontiers, so they're in `overlay.json`'s `clientOnly` list ([server.md](./server.md)).

The shader pack is `Eclipse-Shader Warpledge Edit.zip` in `shaderpacks/`, a copy of the
one the GTNH notes' [build.py](../../GTNH/2.9.0/eclipse-warpledge-edit/build.py) makes,
with its own `.zip.txt` settings.

## Storage and weapons (2026-11-07)

Passed a staging trial on 2026-11-07, then copied to main.

| Jar | Mod | What it does |
| --- | --- | --- |
| `toms_storage-1.20-1.7.1.jar` | Tom's Simple Storage | Cables, connectors and a search terminal over ordinary inventories, before AE2 |
| `Toms-Performant-Storage-forge-0.1.0+1.20.1.jar` | Tom's Performant Storage | Rebuilds the terminal's item list at most once a second, and only when the contents changed. CurseForge only, installed through Prism. Its `mods.toml` makes FTB Teams mandatory, which dev27 ships |
| `simplyswords-forge-neoforge-1.70.2-1.20.1.jar` | Simply Swords | Weapon types in iron, gold, diamond, netherite and runic, plus loot-only uniques |
| `SimplyTooltips-forge-0.1.5-1.20.1.jar` | Simply Tooltips | Library Simply Swords requires |
| `IllagerInvasion-v8.0.7-1.20.1-Forge.jar` | Illager Invasion | New illagers and the imbuing table |

Simply Swords Overhaul was dropped: it only works with Simply Swords 1.56.0
([candidates.md](./candidates.md#skip)).

### Recipe overrides

The [warpledge-gto datapack](../datapack/warpledge-gto/) replaces these recipes;
[updating.md](./updating.md#recipe-overrides) has how it's built and installed.

| Mod | Recipes | Change |
| --- | --- | --- |
| Tom's Simple Storage | 16 | Steam/ULV tier: wrought iron plates and rods replace planks, trapdoors and sticks; bronze plates go in the connectors and the wireless terminal; vacuum tubes replace diamonds and glowstone. The 3 recipes with none of those stay |
| Tom's Simple Storage | 1 | The advanced wireless terminal is an LV crafting recipe instead of a netherite upgrade: 2 LV emitters, an LV circuit, 4 steel plates, an LV sensor and the wireless terminal |
| Simply Swords | 46 | Iron, gold and diamond weapons and sword-on-a-stick: ingots and diamonds become GT plates of the same material, sticks become iron rods. Netherite, runic and the uniques (loot only) stay |
| Illager Invasion | 1 | The imbuing table's 4 copper blocks become 2 copper plates and 2 LV circuits |
| L_Ender's Cataclysm | 11 | Iron, gold and diamond become GT plates in the 5 boss eyes, Belt of Beginner and Netherite Effigy that use them, and in 6 recipes [Integrated Cataclysm](#integrated-structures-2026-11-12) replaces with Create ones (written even where nothing swaps, to put Cataclysm's crafting recipe back). Boss-drop gear stays |
| Integrated Simply Swords | 15 | Its silver weapons, the only ones whose recipes load without Ice and Fire, Oreganized or Caverns and Chasms: GT silver plates and iron rods replace silver ingots and sticks |
| Terralith | 5 | Its cheap piston, dispenser, observer, dropper and lever recipes from any stone are switched off, since GT replaces those vanilla recipes |

**Tom's ranges** are per world in `serverconfig/toms_storage-server.toml`; the
instance's `defaultconfigs/` copy sets them for new worlds:

| Setting | Default | Set | Note |
| --- | --- | --- | --- |
| `wirelessReach` | 16 | 64 | The config's maximum; a higher value is reset to 16 |
| `advWirelessRange` | 64 | 512 | The config's maximum |
| `wirelessTermBeaconLvl` | 1 | 0 | Infinite range for the advanced terminal with any beacon block near the storage terminal |

## Worldgen and combat (2026-11-08)

Passed a staging trial on 2026-11-08, then copied to main. **Worldgen changes need a
new world.** Alex's Mobs (EMI's reload failed), Celestisynth, YUNG's Cave Biomes and the
other dropped mods are in [candidates.md](./candidates.md#skip). Tectonic and
Lithostitched were removed on 2026-11-08 for slow generation, then added back the same
day once FastChunkGen made it fast enough. Tectonic's mod jar has Terralith support
built in, so the separate Terratonic datapack isn't needed. Lithostitched isn't declared
on Modrinth, so Prism doesn't download it; Tectonic's `mods.toml` requires 1.4.11 or newer.

| Jar | Mod | What it does |
| --- | --- | --- |
| `Terralith_1.20.x_v2.5.4.jar` | Terralith | Replaces vanilla's overworld biomes with about 100 of its own. Can't be removed from a world later |
| `tectonic-3.0.17-forge-1.20.1.jar` | Tectonic | Reshapes overworld terrain: continents, mountain ranges, rivers |
| `lithostitched-forge-1.20.1-1.4.12.jar` | Lithostitched | Worldgen library Tectonic requires |
| `YungsApi-1.20-Forge-4.0.6.jar` | YUNG's API | Library for the YUNG's mods |
| `YungsBetterDesertTemples-1.20-Forge-3.0.3.jar` | YUNG's Better Desert Temples | Reworked desert temples |
| `YungsBetterDungeons-1.20-Forge-4.0.4.jar` | YUNG's Better Dungeons | Reworked and new dungeons |
| `YungsBetterJungleTemples-1.20-Forge-2.0.5.jar` | YUNG's Better Jungle Temples | Reworked jungle temples |
| `YungsBetterMineshafts-1.20-Forge-4.0.4.jar` | YUNG's Better Mineshafts | Reworked mineshafts |
| `YungsBetterNetherFortresses-1.20-Forge-2.0.6.jar` | YUNG's Better Nether Fortresses | Reworked Nether fortresses |
| `YungsBetterOceanMonuments-1.20-Forge-3.0.4.jar` | YUNG's Better Ocean Monuments | Reworked ocean monuments |
| `YungsBetterWitchHuts-1.20-Forge-3.0.3.jar` | YUNG's Better Witch Huts | Reworked witch huts |
| `bettercombat-forge-1.9.0+1.20.1.jar` | Better Combat | Melee combat system from Minecraft Dungeons: per-weapon swing animations and combos |
| `player-animation-lib-forge-1.0.2-rc1+1.20.jar` | playerAnimator | Animation library Better Combat requires |
| `ApothicCombat-1.20.1-1.1.0.jar` | Apothic Combat | Compatibility between Apotheosis (in dev27) and Better Combat |

All of these are carried by `gto carry`, along with these configs:

| File | Setting | Why |
| --- | --- | --- |
| `config/tectonic.json` | Defaults plus `ultrasmooth`, `elevation_boost` 0.2, `min_y`/`max_y` -128/544, `ocean_offset` -0.5, `continents_scale` 0.3, `ridge_scale` 0.3, `flat_terrain_skew` -0.1, `islands.enabled` false | Smoother, taller terrain with rare oceans and no islands, as in Cosmic Frontiers. Above -0.45, deep oceans and their monuments stop spawning. GT ores below -64 are unchecked |
| `config/terrablender.toml` | `overworld_region_size` 4 | Smaller biome-mod regions, so they swap more often |
| `config/biomeswevegone/world_generation.json` | 51 of dev27's 54 BWG biomes on; off: crimson_tundra, eroded_borealis, pumpkin_valley. Allium Shrubland, Amaranth Grassland and Rainbow Beach came back on 2026-11-12 (giant alliums give the petal blocks GTO turns into purple, pink and white wool; red wool's rose petal blocks are on Forgotten Forest's Florus trees). Eroded Borealis, off by BWG's default, was tried the same day and turned off again. Region weights 8 to 2 | At 8, BWG's 3 regions outweighed the vanilla region (10, where Terralith's biomes live) and the world was mostly BWG. At 1, BWG showed up in about 1% of 3,510 visited chunks (2026-11-08) |
| `config/bettermineshafts-forge-1_20.toml` | `Enable Ore Deposits` false | Its deposits are vanilla ores outside GT's veins |
| `config/DistantHorizons.toml` | `chunkGeneratorMode` `INTERNAL_SERVER`, `generatorPlan` `SURFACE_THEN_CHUNKS`, `lodChunkRenderDistanceRadius` 256, `numberOfThreads` 4, `horizontalQuality`/`verticalQuality` `HIGH`, `enableCaveCulling` true, `playerBandwidthLimit` 0, `enableAdaptiveTransferSpeed` true (2026-11-08) | DH saves real chunks as it pregenerates, as on the GTNH server. The same file goes to the laptop server, which does the generating, so 4 threads leave its other 12 for ticks; the desktop only builds LODs from what the server sends. HIGH instead of EXTREME and cave culling cut LOD build work and VRAM. `INTERNAL_SERVER` tops out near 8 chunks/s on the laptop whatever the thread count, since each chunk goes through the server's own generation; `SURFACE_THEN_CHUNKS` draws a rough surface first so the horizon fills in sooner. No bandwidth cap on the LAN, with adaptive speed against lag. FastChunkGen (below) is the C2ME-style speedup |

## FastChunkGen (2026-11-08)

An unofficial Forge 1.20.1 port of C2ME: threaded world generation, async chunk IO and
threaded lighting. No GTO or GregTech test has been published, and a threading bug can
write broken chunks without crashing; after a throwaway singleplayer trial it goes to
the laptop server, where `gto server` copies it since it's in `overlay.json` and not in
`clientOnly`. Watch new terrain there for cut-off or missing chunks.

| Jar | Source |
| --- | --- |
| `fastchunkgen-0.43-all.jar` | Built from [shuttheirprayer/FastChunkGen](https://github.com/shuttheirprayer/FastChunkGen) at `18bbfe4`; no published releases. 0.40, from another download, came out the same day |

Built with JDK 17 (Gradle 8.8 can't run on Java 25, so `JAVA_HOME` has to point at it):

```bash
nix-shell -p jdk17 --run 'export JAVA_HOME=$(dirname $(dirname $(readlink -f $(command -v java)))); sh ./gradlew build --no-daemon'
```

Use `build/libs/fastchunkgen-<version>-all.jar`, which bundles its libraries. It accepts
any Forge 47, though it's built against 47.4.22. Its settings go in
`config/fastchunkgen.toml`, which `gto carry` copies.

With defaults, creating a world crashed (2026-11-08): its `reduceAllocations` mixin
`NbtOps$NbtRecordBuilderASM` couldn't inject into `NbtOps$NbtRecordBuilder.build`, which
dev27's LeanObject (`leanobject`) had already rewritten. `reduceAllocations` is set to
false, which only drops that module.

With that, a new singleplayer world on the desktop ran DH generation at 68 chunks/s
(2026-11-08), against about 8 on the laptop server without it. The two aren't the same
CPU, so the laptop's own figure is still to be measured, as is a check for broken chunks.
With Tectonic added back it ran at 32 chunks/s, far above Tectonic's earlier trial without
FastChunkGen.

## Integrated structures (2026-11-12)

Passed a staging trial one layer at a time on 2026-11-11 and 2026-11-12 (each layer a new
world, EMI search, `gto check`), then copied to main. **The structures only generate in
new chunks.** [candidates.md](./candidates.md#integrated-mods) has what failed on the
way: Quark breaks EMI, and Integrated Dungeons Arise overlaps When Dungeons Arise.

| Jar | Mod | What it does |
| --- | --- | --- |
| `integrated_api-forge-1.20.1-1.9.2.jar` | Integrated API | Structure library the others run on |
| `integrated_patches v1.2.0-1.20.1.jar` | Integrated Patches | Fixes for the Integrated mods |
| `idas_forge-1.13.0+1.20.1.jar` | Integrated Dungeons and Structures | 95 structures: dungeons, towers, ruins, camps |
| `IDA_v2.1.3-1.20.1.jar` | Integrated Dungeons Arise | Rebuilds dev27's When Dungeons Arise structures with Create and Quark blocks |
| `ISS-1.20.1.jar` | Integrated Seven Seas | Ships, in the style of WDA: Seven Seas (not needed) |
| `integrated_villages-1.3.2+1.20.1-forge.jar` | Integrated Villages | 11 village types |
| `create-1.20.1-6.0.8.jar` | Create | Block library: its decor stays, its machines are banned |
| `supplementaries-1.20-3.1.44-forge.jar` | Supplementaries | Block library; nothing banned |
| `amendments-1.20-2.2.6.jar` | Amendments | Supplementaries' companion, needed by Integrated Dungeons Arise |
| `moonlight-1.20-2.16.39-forge.jar` | Moonlight Lib | Library Supplementaries and Amendments require |
| `reliable_remover-3.9.0+1.20.1-forge.jar` | Reliable Remover | Bans items by JSON: hidden in EMI, recipes, tags, loot, drops and trades stripped |
| `reliable_recipes-3.9.0+1.20.1-forge.jar` | Reliable Recipes | Removes recipes by JSON; Reliable Remover requires it |
| `quarkblocks-1.0.0.jar` | Quark Blocks | The 513 Quark blocks the structures use, built here ([tools/quarkblocks](../tools/quarkblocks/README.md)) |
| `integrated_cataclysm_forge-1.0.5+1.20.1.jar` | Integrated Cataclysm | Rebuilds Cataclysm's boss arenas with Create, Quark and Supplementaries blocks, with other mods' loot in their chests (added 2026-11-12) |
| `L_Enders_Cataclysm-3.31.jar` | L_Ender's Cataclysm | Bosses, their arenas and boss-drop gear |
| `lionfishapi-3.0.jar` | Lionfish API | Library Cataclysm requires |
| `integrated_simply_swords-forge-1.3.1+1.20.1.jar` | Integrated Simply Swords | Simply Swords weapons for other mods' materials; only the silver ones are craftable here |

**Integrated Cataclysm** reskins Cataclysm at the same 147 data paths, so the pack carries
all its data, as with Integrated Dungeons Arise. Its recipes stay out: it turns 6 of
Cataclysm's (Mechanical Fusion Anvil, Mech Eye, the Incinerator, Meat Shredder, Laser
Gatling, Wither Assault Shoulder Weapon) into Create recipes the bans below remove, and
[gregify.py](../tools/gregify.py) writes Cataclysm's own at those paths instead.

**Quark isn't installed.** IDAS, Integrated Dungeons Arise, Seven Seas and Integrated
Cataclysm require it in
`mods.toml`; [libgate.py](../tools/libgate.py) patches that to optional in the jars
themselves, so a fresh download needs `libgate.py` rerun before it loads. It also
writes the `warpledge-gto-integrated` Open Loader pack (gitignored): their 780 templates
and 160 data files that name Quark, renamed to `quarkblocks:`, plus all of Integrated
Dungeons Arise's and Integrated Cataclysm's other data. Quark's variant chests, furnaces,
crate and blossom sign become the vanilla blocks, keeping their loot and text; its wraith
and forgotten mobs become a stray and a skeleton; 746 Quark entities such as glass item
frames are dropped.
The same pack holds the village tag fix: Integrated Villages 1.3.2 names a
`swamp_village` it doesn't ship, which fails the whole `#minecraft:village` tag, so
every entry is made optional.

**Create** is gated by `libgate.py` too, through Reliable Remover and Recipes
(`reliable/` in the repo, installed into `config/` by `gto datapack`):

| Rule | What |
| --- | --- |
| Banned | 206 items: kinetics, logistics, processing machines, contraptions, trains, tools (wrench and goggles included) and machine parts. Structures still place them, but breaking one drops nothing |
| Kept | 479 items: cut and polished stone, windows, seats, sails, ladders, bars, doors, casings, copycats, zinc and brass materials, food |
| No right-click | The 21 processing machines (millstone, crushing wheels, press, mixer, basin, blaze burner, deployer, fan, spout, drain, mechanical crafter, arm, drill, saw, harvester, plough, roller, schematic machines). Cranks, levers, valves and contraption controls work, so the structures' doors and contraptions do |
| Recipes | Every Create machine recipe type removed (crushing, milling, mixing, pressing, washing and the rest), plus 3 crafting recipes for other mods' items |
| Worldgen | Zinc ore and Create's stone layers off (`forge:none` biome modifiers in the warpledge-gto datapack) |

Supplementaries needed no rules: none of its recipes turns vanilla ingredients into
vanilla items. Integrated Stronghold stayed out (frame rate), and Integrated API's
`dread_citadel` spawner list logs an error at every start because Ice and Fire isn't
installed; the structure needing it never generates.

**Integrated Simply Swords** registers its silver weapons only when it recognises a mod
that adds silver, and GT doesn't count; its creative tab icon is the silver cutlass, so
opening the tab crashed. `config/integrated_simply_swords/silver.json5` sets `ENABLED`
to `TRUE` (carried by `gto carry`). Its Born in Chaos dark metal weapons register too,
but their recipes check for Ice and Fire by mistake, so they never load.

**Minka villages** (Integrated Villages) spawn in its `collections/floral` biome tag,
which names BWG's pre-rename `#byg:is_floral`; libgate.py adds `#biomeswevegone:floral`
to it in the integrated pack.

## Advancements and QoL (2026-11-12)

Passed a staging trial in a new world on 2026-11-12.

| Jar | Mod | What it does |
| --- | --- | --- |
| `BetterAdvancements-Forge-1.20.1-0.6.0.73.jar` | Better Advancements | Reworked advancements screen; client only |
| `LeavesBeGone-v8.0.0-1.20.1-Forge.jar` | Leaves Be Gone | Fast leaf decay after a tree is cut; Puzzles Lib ships in dev27 |
| `particular-1.20.1-Forge-1.5.7.jar` | Particular Reforged | Ambient particles; client only. Also in from 2026-11-07 to 2026-11-08 |

**AdvancementNoMore is off** (`advancementnomore-1.20.1-1.0.1.jar.disabled`, listed under
`removed` in [overlay.json](../tools/overlay.json), so `gto carry` disables it in a new
pack build and `gto server` leaves it out). GTO ships it to skip advancement checks for
performance, but Born in Chaos's infected diamond ore throws on every break without
the advancement it grants, and Nether Remastered crashed on joining a world
([candidates.md](./candidates.md#skip)), so that one can be retried.

## Overlay

The same jars, with their modIds and sources, are in
[overlay.json](../tools/overlay.json), which `gto carry` reads to copy them into a new
build. A mod added or removed here changes there too. Candidates from Cosmic Frontiers
are sorted by risk in [candidates.md](./candidates.md), and the trial steps are in
[updating.md](./updating.md#a-mod-trial).
