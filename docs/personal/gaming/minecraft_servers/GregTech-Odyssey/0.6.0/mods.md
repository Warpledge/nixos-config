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
| `BetterControls-Forge-1.20+v1.3.0.jar` | Better Controls | New ways to control sprinting, sneaking and flying |
| `ShoulderSurfing-Forge-1.20.1-5.3.1.jar` | Shoulder Surfing Reloaded | Configurable third-person camera |
| `moreoverlays-1.22.7-mc1.20.2.jar` | More Overlays Updated | Light level and chunk border overlays, and a JEI item search highlight |
| `chromapatch-1.0.3-forge1201-1.20.1.jar` | Chroma Patch | Builds the coloured-light Eclipse edit from the Eclipse zip in `shaderpacks/` ([shaders.md](./shaders.md)) |

Better Controls (2026-11-08), Shoulder Surfing Reloaded (2026-11-10), More Overlays
Updated (2026-11-11) and Chroma Patch (2026-11-15) were added without a staging trial.
All four are client-only, so `gto server` leaves them out.

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
| `trashslot-forge-1.20.1-15.1.5.jar` | TrashSlot | Trash slot in the inventory screen |
| `creeperoverhaul-3.0.2-forge.jar` | Creeper Overhaul | Biome-specific creepers |
| `endermanoverhaul-forge-1.20.1-1.0.4.jar` | Enderman Overhaul | Biome-specific endermen |
| `fzzy_config-0.7.7+1.20.1+forge.jar` | Fzzy Config | Library; Simply Swords needs it |
| `yet_another_config_lib_v3-3.6.6+1.20.1-forge.jar` | YACL | Library added for Sounds and MRU, which called it without declaring it; no remaining mod declares it |

Kotlin for Forge, which Fzzy Config needs, already ships in dev27. Sounds, MRU,
Particular and Particle Core were removed on 2026-11-08
([candidates.md](./candidates.md#skip)).

Ziplines: Rezipped! 1.3.0 and Reconnectible Chains 2.2.5 were removed on 2026-11-15:
Zipline's Connectible Chains compat crashed the client with a
`ConcurrentModificationException` while ziplining (2026-11-11).

**Configs:** EMF, ETF and Presence Footsteps crashed a dedicated server in Cosmic
Frontiers, so they're in `overlay.json`'s `clientOnly` list ([server.md](./server.md)).

The shader pack is `Eclipse-Shader Warpledge Edit.zip` in `shaderpacks/`, built for
1.20.1 with Chroma Patch and the GTNH notes'
[build.py](../../GTNH/2.9.0/eclipse-warpledge-edit/build.py), with its own `.zip.txt`
settings and the generated `Warpledge GT PBR.zip` resource pack
([shaders.md](./shaders.md)).

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
new world.** Alex's Mobs (EMI's reload failed; back on 2026-11-12 as
[Continued](#alexs-mobs-continued-2026-11-12)), Celestisynth, YUNG's Cave Biomes and the
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
| `config/tectonic.json` | Tectonic 3.0.17's defaults (since 2026-11-12; checked against the jar's constants on 2026-11-13) | The Cosmic Frontiers-style tweaks first used here (`ultrasmooth`, height -128 to 544, fewer oceans, no islands) were dropped; terrain stays at vanilla height, so GT's ore layers sit where the pack expects |
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
false, which only drops that module. `disableLoggingShutdownHook` is false too
(2026-11-15), since its forced exit hung the dedicated server ([server.md](./server.md)).

With that, a new singleplayer world on the desktop ran DH generation at 68 chunks/s
(2026-11-08), against about 8 on the laptop server without it. With Tectonic added back
it ran at 32 chunks/s, far above Tectonic's earlier trial without FastChunkGen.

On the laptop server, with Tectonic, a new world's DH pregen (radius 256, 14 DH threads)
ran at 42 chunks/s with every CPU thread busy (2026-11-08). No broken chunks were seen
flying over the new terrain that day.

At startup FastChunkGen warns `Could not disable ModernFix
mixin.perf.release_protochunks` with a `NullPointerException` (`"option" is null`). It
tries to switch off that ModernFix option, which frees a chunk's in-progress copy early
and could clash with threaded generation, but dev27's ModernFix 5.26.2 has no such
option: the jar has no mixin by that name and `config/modernfix-mixins.properties`
doesn't list it. Nothing to set; check again if ModernFix is updated.
`overrideModernFixWorldGenAllocations` in `fastchunkgen.toml` covers the ModernFix
worldgen mixin that does exist (`perf.worldgen_allocation`).

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
| `quarkblocks-1.0.0.jar` | Quark Blocks | The 514 Quark blocks the structures use, built here ([tools/quarkblocks](../tools/quarkblocks/README.md)) |
| `integrated_cataclysm_forge-1.0.5+1.20.1.jar` | Integrated Cataclysm | Rebuilds Cataclysm's boss arenas with Create, Quark and Supplementaries blocks, with other mods' loot in their chests (added 2026-11-12) |
| `L_Enders_Cataclysm-3.31.jar` | L_Ender's Cataclysm | Bosses, their arenas and boss-drop gear |
| `lionfishapi-3.0.jar` | Lionfish API | Library Cataclysm requires |
| `integrated_simply_swords-forge-1.3.1+1.20.1.jar` | Integrated Simply Swords | Simply Swords weapons for other mods' materials; only the silver ones are craftable here. Back on 2026-11-15 |
| `IMM v1.3.2-1.20.1.jar` | Integrated Mowzie's Mobs | Rebuilds Mowzie's Monastery, Umvunthana Grove, Frostmaw and Wroughtnaut structures (added 2026-11-12) |
| `mowziesmobs-1.8.2.jar` | Mowzie's Mobs | Bosses and mobs; its gear needs their drops, so nothing is gregified |
| `mowzies_cataclysm-1.2.1.jar` | Mowzie's Cataclysm | Cataclysm-style locator eyes (Ender Eye recipes) for Mowzie's boss structures |
| `IBOMD v1.0.0-1.20.1.jar` | Integrated Bosses of Mass Destruction | Rebuilds BOMD's Lich Tower, Obsidilith and Gauntlet arenas (added 2026-11-12) |
| `BOMD-Forge-1.20.1-1.1.2.jar` | Bosses of Mass Destruction | Four bosses; its recipes need their drops or netherite scrap, so nothing is gregified |
| `CerbonsAPI-Forge-1.20.1-1.1.0.jar` | Cerbon's API | Library BOMD requires |
| `legendarymonsters-2.2.4 MC 1.20.1.jar` | Legendary Monsters | Bosses and their structures (added 2026-11-12); gear needs their drops, so nothing is gregified |

Critters and Companions 2.7.1 and More Mob Variants 1.3.0.1 were removed on 2026-11-15
to trim the mob mods.

**Integrated Cataclysm** reskins Cataclysm at the same 147 data paths, so the pack carries
all its data, as with Integrated Dungeons Arise. Its recipes stay out: it turns 6 of
Cataclysm's (Mechanical Fusion Anvil, Mech Eye, the Incinerator, Meat Shredder, Laser
Gatling, Wither Assault Shoulder Weapon) into Create recipes the bans below remove, and
[gregify.py](../tools/gregify.py) writes Cataclysm's own at those paths instead.

**Integrated Mowzie's Mobs** and **Integrated BOMD** do the same to their base mods, and
have no recipes.

**Quark isn't installed.** IDAS, Integrated Dungeons Arise, Seven Seas, Integrated
Cataclysm, Integrated Mowzie's Mobs and Integrated BOMD require it in
`mods.toml`; [libgate.py](../tools/libgate.py) patches that to optional in the jars
themselves, so a fresh download needs `libgate.py` rerun before it loads. It also
writes the `warpledge-gto-integrated` Open Loader pack (gitignored): their 812 templates
and 161 data files that name Quark, renamed to `quarkblocks:`, plus all of Integrated
Dungeons Arise's, Integrated Cataclysm's, Integrated Mowzie's Mobs' and Integrated
BOMD's other data. Since 2026-11-13 Quark's blocks, block entities, items and mobs keep
Quark's ids under `quarkblocks:` (see [quarkblocks](../tools/quarkblocks/README.md)), so
chests' loot, crates' contents, glass item frames, wraiths, forgotten and the rest load
as placed; only Quark entities quarkblocks lacks are dropped.
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
but their recipes check for Ice and Fire by mistake, so they never load. Removed with
Knaves' Needs earlier on 2026-11-15, it came back on its own the same day.

**Minka villages** (Integrated Villages) spawn in its `collections/floral` biome tag,
which names BWG's pre-rename `#byg:is_floral`; libgate.py adds `#biomeswevegone:floral`
to it in the integrated pack.

## Advancements and QoL (2026-11-12)

Passed a staging trial in a new world on 2026-11-12.

| Jar | Mod | What it does |
| --- | --- | --- |
| `LeavesBeGone-v8.0.0-1.20.1-Forge.jar` | Leaves Be Gone | Fast leaf decay after a tree is cut; Puzzles Lib ships in dev27 |
| `particular-1.20.1-Forge-1.5.7.jar` | Particular Reforged | Ambient particles; client only. Also in from 2026-11-07 to 2026-11-08 |

**AdvancementNoMore is off** (`advancementnomore-1.20.1-1.0.1.jar.disabled`, listed under
`removed` in [overlay.json](../tools/overlay.json), so `gto carry` disables it in a new
pack build and `gto server` leaves it out). GTO ships it to skip advancement checks for
performance, but Born in Chaos's infected diamond ore throws on every break without
the advancement it grants, and Nether Remastered crashed on joining a world
([candidates.md](./candidates.md#skip)), so that one can be retried.

**GTO loads no advancements anyway.** Every session's log, with AdvancementNoMore on
or off, says `Loaded 0 advancements`, and `/advancement grant @s only
minecraft:story/root` answers "Unknown advancement" (2026-11-12). No config or readable
mixin does it, so it's in gtolib's obfuscated or native code. Better Advancements, added
in this batch, showed an empty screen and was removed on 2026-11-12.

## Structure spacing (2026-11-12)

| Jar | Mod | What it does |
| --- | --- | --- |
| `structurify-forge-2.0.43+mc1.20.1.jar` | Structurify | Stops structures overlapping and thins the common structure sets; YACL ships in dev27 |

Its `config/structurify.json` is written by
[structures.py](../tools/structures.py), not the in-game screen.
[structure-spacing.md](./structure-spacing.md) has the settings, why, and what to do
when a structure mod is added.

## Nether and End (2026-11-12)

Passed a staging trial in a new world on 2026-11-12. GTO gates both dimensions itself
(gtocore 26.11.1 source): Nether portals never light, the Nether opens at HV through
the Nether Reactor Core (Nano suit for its missing oxygen), and the End at LuV through
End Remastered's 12 eyes. GTO adds GT ore veins there but no terrain, biomes or
structures, so these overlap nothing.

| Jar | Mod | What it does |
| --- | --- | --- |
| `Incendium_1.20.x_v5.3.5.jar` | Incendium | Nether terrain and 8 biomes, 9 structures and loot-only weapons |
| `MoogsEndStructures-universal-1.20-2.1.0.jar` | MES - Moog's End Structures | 24 End structures, no recipes |
| `MoogsStructureLib-forge-1.20-3.1.2.jar` | Moog's Structure Lib | Library MES requires; held at 3.1.2 |
| `Nullscape_1.20.x_v1.2.8.jar` | Nullscape | End terrain and 3 biomes, no items |

**Jaden's Nether Expansion 2.3.5 and Elysium API 1.1.3 were removed on 2026-11-15**
to trim the Nether mods; Incendium stays. Jaden's added Nether mobs, blocks,
structures and the Black Ice Glaciers biome, and nothing was gregified. gregify.py
still lists it in `AIRLESS_JARS`, which skips a missing jar.

**Moog's Structure Lib stays at 3.1.2.** 3.3.0 and later add a `TagLoaderMixin` that
can't inject past gtolib's (the 3.4.2 crash in [candidates.md](./candidates.md#skip)),
and MES 2.1.0 came out while 3.1.2 was current.

**Incendium and Nullscape replace the dimensions' biome lists.** Nullscape drops End
Midlands, so the structures limited to Midlands and Highlands (Cataclysm's Ruined
Citadel, Dungeons Arise's End ones, Legendary Monsters' towers) only come in Highlands.
Incendium also rewrites vanilla's piston, dispenser, dropper, observer, comparator,
repeater and lever recipes at vanilla's ids, which GT's `removeVanillaBlockRecipes`
removes.

**Mobs need Ad Astra's tags to live there.** GTO makes the Nether and End airless (hot
and cold) and tags only vanilla's mobs, so Cataclysm's bosses and structure spawns died
in seconds. [gregify.py](../tools/gregify.py) writes `lives_without_oxygen`,
`can_survive_extreme_heat` and `can_survive_extreme_cold` with every entity of the mods
in its `AIRLESS_JARS` and vanilla's hostiles. A new mod whose mobs reach the Nether or
End goes in that list.

## Food and weapons (2026-11-12)

Passed a staging trial on 2026-11-12. It gets no recipe overrides.

| Jar | Mod | What it does |
| --- | --- | --- |
| `Delightful-1.20.1-3.8.1.jar` | Delightful | Farmer's Delight foods, wild cantaloupe, mini melons and salmonberries, and knives from other mods' metals |

Delightful's knives are one GT ingot or gem and a stick, like Farmer's Delight's own
knives, which GTO leaves alone too.

**Knaves' Needs 3.1.0-beta.1 was removed on 2026-11-15** to trim the Simply Swords
stack: only Deeper Darker's Warden set loaded here (its resonarium set doesn't show,
since GTO reworks Deeper Darker's items in `DDItemsMixin`). The 3.1.0 beta is the only
build on Fzzy Config; 2.0 (2023) needs Architectury.

EMI logs `Exception thrown registering repair recipes` six times since this batch: an
item whose repair material is empty, so EMI skips its anvil recipe. It's harmless.

## Born In Configuration (2026-11-12)

Passed a staging trial on 2026-11-12.

| Jar | Mod | What it does |
| --- | --- | --- |
| `born_in_chaos_[Forge]1.20.1_1.7.5.jar` | Born in Chaos | Horror mobs, bosses and their gear; needs GeckoLib (in dev27). Added from Prism on 2026-11-11; runs on both sides |
| `borninconfig-FORGE.jar` | Born In Configuration | Config file and screen for Born in Chaos's game rules, mob and item stats and per-mob spawning; 4.0, needs Born in Chaos 1.7.5 or later |

`config/borninconfiguration-general.toml` (common, carried by `gto carry`) keeps every
mob and item stat at -1, Born in Chaos's own value, and changes:

- `INFESTED_DIAMONDS_ENABLED = false`: the ore that throws without the advancement it
  grants, which never exists here (GTO loads no advancements, see above).
- `DAYS_TILL_NIGHTMARE = 20` (default 3) and `NIGHTMARE_STRENGTH_ENABLED = false`: the
  Nightmare Stalker came on day 3 and kept growing with world age, too early and too
  open-ended for GTO's pace.
- `KRAMPUS_HENCHMAN_DROPING_ENABLED = false`: its hits knocked items out of the
  inventory.

Chaotic Spring (Easter) and Chilling Horror (Christmas) stay date-based; forcing them
on makes their mobs carry and drop event gear all year.

## Maid addons and Youkai's Homecoming (2026-11-12)

Passed a staging trial in a new world on 2026-11-12. None get recipe overrides: the
maid items are made at TLM's altar for power points or from cheap vanilla items, and
Youkai's utensils cost iron ingots like Farmer's Delight's cooking pot.

| Jar | Mod | What it does |
| --- | --- | --- |
| `1.20.1-maid_useful_task-1.4.2.jar` | Maid Useful Task | Logging, locate and revive-player tasks |
| `1.20.1-maid_storage_manager-1.15.6.jar` | Maid Storage Manager | Maids sort storage and craft from craft guides; any item inventory (GT machines included), AE2 and Create's stock keeper. Patched, see below |
| `maidsoulkitchen-1.20.1-alpha-v0.3.0.9-all.jar` | Maidsoul Kitchen | Maids cook and farm at other mods' stations (Farmer's Delight) |
| `touhou_little_maid_spell-1.8.0.1-forge+mc1.20.1.jar` | Touhou Little Maid: Spell | Maids cast from spell books (Ars Nouveau here); held at 1.8.0.1, structures off |
| `maid_rpg_task-release.jar` | Touhou Little Maid RPG Task | RPG-style combat tasks |
| `tlm_atrribute_display-1.0.2-forge+mc1.20.1.jar` | Attribute Display | A screen with a maid's attributes |
| `solmaid-1.0.1.jar` | Spice of Life: Maid | Spice of Life for maids |
| `solmaiddream-1.0.1.jar` | Spice of Life: Maids' Dream | Rewards maids for a varied diet |
| `touhou-maid-affection-1.7.5.2.jar` | Touhou Maid: Affection | Kissing and bond abilities: Emergency Rescue shields you from a fatal hit, Random Gift brings items |
| `youkaishomecoming-2.7.2.jar` | Youkai's Homecoming | Japanese food, crops and cooking utensils, sakura biomes, Hakurei Shrine and two nests, Touhou characters and animals; bundles L2 Harvester and its libraries. Patched, see below |

Tamable Fairy 1.2.0-beta.5 and Self-Talk 1.4.1 were removed on 2026-11-15 to trim the
maid add-ons.

**Maid Spell stays on a plain jar.** From 1.9.0 it's a bootstrap jar that registers a
ModLauncher service (`maidspell_hurt_head`), and `gto_native` refuses unknown services,
so the game stops before a crash report. dev27 pins 1.8.0.1; dev31 runs 1.8.2, also a
plain jar and the newest one before the bootstrap. Its own `ArsNouveauProvider` and three
Ars mixins let maids cast Ars Nouveau spells. Its 12 structure sets are built for Iron's
Spells (their loot names 49 Iron's items), so
[structures.py](../tools/structures.py) keeps them off in Structurify
(`DISABLED_NAMESPACES`). Where Structurify isn't installed, the
[warpledge-gto datapack](../datapack/warpledge-gto/) gates the six unconditional sets on
`irons_spellbooks` with `forge:mod_loaded`, so they load only while
[Iron's Spells](#irons-spells-2026-11-12) is in.

**Two jars are patched** by [mixinpatch.py](../tools/mixinpatch.py), rerun after
updating either: Maid Storage Manager's `JEIRecipeTransferHook` fails against the
pack's JEI 15.59 (it applies whenever JEI is installed) and left JEI's recipe transfer
button unloadable, and Youkai's `CriterionGridMixin` wrapped a call Better Advancements
0.6.0.73 doesn't make and crashed the game on launch.

**Maidsoul Kitchen can't run Youkai's kettle or fermentation tank**: it calls 9 methods
Youkai's 2.7.2 no longer has (its kettle accessor wants a `MAP` field that 2.6.1
lacks too), and blocks those tasks. `YhcTeaKettleTaskEnabled` and
`YhcFermentationTaskEnabled` are false in `maidsoulkitchen-common.toml`, but its Maid
Storage Manager kettle and fermentation tasks have no toggle, so its task check posted a
chat warning at every login. Since 2026-11-15 [classpatch.py](../tools/classpatch.py)
swaps in a `ReportErrorEvent` that never sends it (source in
`tools/classpatch/maidsoulkitchen/`); the two tasks stay off, and
`logs/maidsoulkitchen_task_clazz_analysis.txt` is still written. Kept, since its other
25 tasks load. It and Maid Storage Manager
log "task can not load" and "added for twice" lines at startup; both are harmless.

**Configs**, all carried by `gto carry`:

- `touhou_little_maid-common.toml`: `MaidWorkRange = 32` (default 12; the max is 64, but
  farm tasks scan every block in range) and `MaidNonHomeRange = 16` (default 8), for
  GTO-size bases. `TTSEnabled` and `STTEnabled` are off: both expect the Player2 app.
  `LLMEnabled` turns maid chat on and off.
- `touhou_little_maid/sites/llm.json`: a `local` site for llama-swap
  (`127.0.0.1:8090`), first `gemma-4-12b-it-qat-instruct` (thinking off, from the
  desktop's `localModels`), then plain `gemma-4-12b-it-qat`. DeepSeek, the default, is
  off. Gemma 12B (6.7 GB) is the largest model that leaves VRAM for the game.
- `maid_storage_manager-common.toml`: crafting, collect and place speeds 1.0 (default
  0.5).

Maid Spell's structures are off while Iron's Spells is out; the datapack gate above
also covers instances without Structurify.

## Alex's Mobs Continued (2026-11-12)

Passed a staging trial on 2026-11-12. None get recipe overrides: the Delight foods
follow Farmer's Delight, and no structures are added (only a structure tag).

| Jar | Mod | What it does |
| --- | --- | --- |
| `alexsmobs-2.3.0-forge+1.20.1.jar` | Alex's Mobs Continued | About 90 animals and monsters, their drops, gear and potions; the maintained fork of Alex's Mobs (1.22.9, 2024), same `alexsmobs` mod ID. Patched, see below |
| `codxlib-1.6.1-forge+1.20.1.jar` | CodxLib | Library Continued and its Delight require (Continued dropped Citadel) |
| `amcdelight-1.0.1-forge+1.20.1.jar` | Alex's Mobs Continued Delight | Farmer's Delight cuts and dishes from Alex's Mobs' meats |
| `domesticationinnovation-1.7.1-1.20.1.jar` | Domestication Innovation | Pet enchantments, beds and commands; no fork exists, works without Alex's Mobs |
| `citadel-2.6.3-1.20.1.jar` | Citadel | Library Domestication Innovation requires |

**Alex's Mobs broke EMI** (1.22.9, staging, 2026-11-08 and 2026-11-12): the
reload failed every time with a `NullPointerException` in gtolib's native recipe index
(`com.gtolib.ㅤࣱࣻࣾ`, which replaces EMI's `EmiRecipeIndex`). GTO's EMI fork ids each
Forge `BrewingRecipe` as `brewing/forge/<input>/<ingredient>/<output>` by item
(`EmiForgePlatform`), so Alex's Mobs' potion-to-potion recipes collide: every "long"
variant is `potion/redstone/potion`. Citadel alone passed; with Alex's brewing stubbed
out, EMI loaded. Continued's `ProperBrewingRecipe` still extends `BrewingRecipe`, so it
gets the same patch.

[classpatch.py](../tools/classpatch.py) replaces Alex's `ProperBrewingRecipe` with a
copy that implements Forge's `IBrewingRecipe` instead of extending `BrewingRecipe`
(source in `tools/classpatch/alexsmobs/`). EMI's Forge loop skips it, and the brewing
stand still brews every potion, but **EMI shows no recipe for Alex's potions**, and
its JEI plugin stays off ([EMI and JEI plugins](#emi-and-jei-plugins-2026-11-12)).
GTO's own potions come from GT's Brewery as fluids.

## EMI and JEI plugins (2026-11-12)

GTO loads only its own list of EMI and JEI plugins
([internals/mixins.md](./internals/mixins.md#emi-and-jei)), so 13 of the added mods'
plugins never ran. Ten are now listed under `misc.enableEmiJeiExternalPlugins` in
`config/gtocore.yaml` (each mod's EMI plugin where it has one, else its JEI plugin):
Create, Supplementaries, Tom's Simple Storage, Touhou Little Maid, Maid Storage
Manager, Maidsoul Kitchen, Cataclysm, Reliable Recipes, Reliable Remover and TrashSlot
(Iron's Spells' `JeiPlugin` went with it on 2026-11-15). They passed staging on
2026-11-12, with EMI loading and its search working. The file is
in `overlay.json`'s carry list. Three stay off:

- **Youkai's Homecoming** (`YHJeiPlugin`): crashed the game on load. GTO loads listed
  classes while mods are still being built, and this one's static fields start
  `YoukaisHomecoming` too early, so the mod fails with `NoClassDefFoundError`.
- **Delightful** (`JEIPlugin`): JEI refuses its call to hide items from the loader
  thread (`IllegalStateException`), so it only adds an error.
- **Alex's Mobs Continued**: its brewing broke EMI before (above).

## spark and Clumps (2026-11-12)

Passed a staging trial on 2026-11-12. Both were checked first with `gto map --mod`:
spark patches nothing, and Clumps only patches XP orbs. **spark was removed the same
day** ([candidates.md](./candidates.md#skip) has why); Clumps stays.

| Jar | Mod | What it does |
| --- | --- | --- |
| `Clumps-forge-1.20.1-12.0.0.4.jar` | Clumps | Merges nearby XP orbs into one |

spark's native profiler also crashed Java 25: with `backgroundProfiler` on (its
default), world creation killed the JVM (SIGSEGV in `libasyncProfiler.so`) with no
crash report. If it comes back, set `"backgroundProfiler": false` in
`config/spark/config.json` and profile with `/spark profiler start --force-java-sampler`.

The trial's two-minute profile ([report](https://spark.lucko.me/B0mnQ0C3Z9)) had a
median tick of 3.9 ms (5.4 ms over five minutes) and a 95th percentile of 13 to 22 ms;
the 2.8 s worst tick was world creation. Block entity ticking took 36% of tick time,
led by Supplementaries hourglasses (5.7%) and Create machines (3.6%), likely placed by
the Integrated structures near spawn.

## Iron's Spells (2026-11-12)

**Iron's Spells 'n Spellbooks 3.16.3, Iron's Lib 2.2.0 and Mana Unification 2.0.0
were removed on 2026-11-15** to trim the magic mods; Ars Nouveau stays. Mana
Unification requires Iron's. The notes below are for bringing them back: gregify.py's
`IRONS_*` code still runs whenever the jar is in `mods/`, its JEI plugin
(`io.redspace.ironsspellbooks.jei.JeiPlugin`) goes back in `gtocore.yaml`, and Maid
Spell's namespace comes out of `DISABLED_NAMESPACES`.

It passed two staging trials on 2026-11-12. `gto map --mod` found no ModLauncher
service and no mixin GTO overwrites; Curios, GeckoLib and Player Animator already ship
in dev27. It came from the Integrated MC instance, with spells, spell books, scrolls,
mage armour, curios, bosses and 9 structure sets; Mana Unification (added 2026-11-13)
gave it and Ars Nouveau one mana pool.

**Mithril is GTOCore's.** GTOCore has its own MV Mithril, which Iron's recipes don't
accept (its parts are under `c:`, Iron's asks for `forge:ingots/mithril`). So Iron's
mithril recipes take GTOCore's ingot, its mithril ore is off (a `forge:none` biome
modifier), and `reliable/reliable_remover/irons_spellbooks.json` hides its ore, raw
mithril and ingot. Mithril scrap, which most rings and curios need, comes from blasting
GTOCore's ingot or salvaging Iron's gear. All of it is written by
[gregify.py](../tools/gregify.py) (`IRONS_*`), with the plate swaps in
[Recipe overrides](#recipe-overrides).

**Two loot tables are rewritten for 1.20.1**: 3.16.3 ships `chests/catacombs/crypt_loot`
with a 1.21 table reference (`value` for `name`) and `chests/citadel/citadel_tomes`
with 1.21's `set_written_book_pages`, so neither loaded. gregify.py rewrites both from
the jar (the tome pages go in through `set_nbt`).

Its JEI plugin was listed in `gtocore.yaml` ([EMI and JEI plugins](#emi-and-jei-plugins-2026-11-12)).
Harmless log lines: EMF gives up on the pyrium staff's two model parts, and Maid
Storage Manager logs `cooked_ice_spider_egg_from_campfire_cooking` as added twice.

**Mana Unification** (staging trial 2026-11-13) hooks 7 classes in GTO's Ars Nouveau
fork (mana capability, regen, `ManaUtil`, the spell resolver's mana checks, the mana
HUD) with a required mixin config; every method and field it names exists in the
fork's 4.12.24, so check them first when GTO updates its Ars Nouveau. Its Apotheosis,
EB Wizardry and Put Mana In mixins skip, since the pack has none of those classes. Its
conversion rates are the 1.0 defaults in `config/manaunification-common.toml`.

## Mob tuning (2026-11-15)

In staging since 2026-11-15, trial pending. Modelled on Integrated MC 1.6.9's configs,
with boss buffs halved because GTO already boosts mobs. All of it stays clear of GTO's
own mob code: no rule or value touches vanilla's or GTO's mobs, spawn rates, light
checks, despawning or regeneration.

**GTO's boost** (gtocore 26.11.1 `MobMixin`, rule `survival.mob_enhancement`): when a
mob spawns, every boss (Jade's boss check) and half of the other mobs get extra max
health and attack damage, a random amount between `base / 2` (bosses) or `base / 10`
(others) and `base`, times difficulty / 2. On Hard that's +75 to 150% for bosses and +15
to 150% for the rest, on top of whatever base the mod's own config sets.
`mobConfig.naturalRegeneration` in `gtocore.yaml` also makes every mob regenerate, so no
boss healing below goes up.

| Jar | Mod | What it does |
| --- | --- | --- |
| `incontrol-1.20-9.5.1.jar` | In Control! | Rule files that allow or deny spawns; here, Born in Chaos's day phases |
| `cataclysm_compat_1.20.1-1.0.2.jar` | Cataclysm & BetterCombat - Compatibility | Data only: Better Combat weapon attributes (swing animations, reach) for 20 Cataclysm weapons, several of which had none |

`gto map --mod` found no mixin target shared with GTO, and gtocore subscribes to no
Forge spawn event (only `EntityJoinLevelEvent`), so In Control's checks don't collide.

**Born in Chaos spawn weights are a third of its own**: its 44 `forge:add_spawns` biome
modifiers add 544 weight to every biome (a plains biome's vanilla hostiles total about
515), now 181. [gregify.py](../tools/gregify.py) rewrites them from the jar
(`BIC_WEIGHT_DIVISOR`), keeping their `forge:any` biomes so the airless tags still
apply.

**In Control** (`config/incontrol/spawn.json` and `phases.json`, Integrated MC's rules
for the mods GTO has; first match wins):

| Rule | Mobs |
| --- | --- |
| Always denied | Born in Chaos: zombie clown (both), dire hound leader, glutton fish, maggot, corpse fly, swarmer, dark vortex, bloody gadfly, baby spider, krampus. Also Alex's crow and Cataclysm's five deeplings (Integrated MC's koi fish rule left out with Critters and Companions) |
| Day 5, 75% | door knight, baby skeleton, zombie lumberjack, zombie fisherman, zombie bruiser |
| Day 10, 25% | skeleton demoman, skeleton thrasher |
| Day 15, 75% | bonescaller, siamese skeletons, phantom creeper, restless spirit, seared spirit |
| Day 25, 50% | mother spider, spirit guide, spirit guide assistant |
| Day 50, 50% | missioner, spirit of chaos, supreme bonescaller |
| Day 75 | fallen chaos knight (50%), nightmare stalker (60%) |
| Day 100, 50% | lifestealer |

A phased mob is denied before its day, and after it spawns at the given share of its
(already cut) weight. Zombie bruiser isn't in Integrated MC's final deny, so nothing
denies it and it spawns from day 1 at its full (cut) weight; kept as Integrated MC has
it. Its
rules for Alex's Caves biomes and mods GTO lacks (Biome Makeover, Eidolon, Quark,
Forbidden Arcanus, Upgrade Aquatic, Caverns and Chasms) were left out.

**Boss stats** take half of each Integrated MC buff: a multiplier m becomes
1 + (m - 1) / 2, and a flat value moves halfway from the default to Integrated MC's.

| File | Changed |
| --- | --- |
| `bosses_of_mass_destruction.json5` | Night Lich health 300 to 400, missile damage 9 to 10.5, comet explosion 4 to 5.5; Void Blossom idle healing 0.5 to 0.4 |
| `mowziesmobs-common.toml` | Frostmaw health 1.75, attack 1.65; Ferrous Wroughtnaut 1.25 and 1.25 |
| `legendary_monsters-common.toml` | 45 Mob Settings multipliers: most to 1.25; Ancient Guardian damage 2.5, health 3.5; Cloud Golem and Dune Sentinel 1.5 and 2.0; Frostbitten Golem, Bomber and Skeletosaurus health 1.5; Withered Abomination damage 1.75, health 1.5; Obliterator 1.5 and 1.75; Flame Drifter and Wandering Eye 1.5; Mossy Golem damage 1.15. Damage caps and toggles unchanged |

Taken as Integrated MC has them: BOMD's `eternalNighttime` false (the Night Lich no
longer keeps it night) and `numEntitiesKilledToDropSoulStar` 50 to 1000, Mowzie's
`suns_blessing_duration` 60 to 120, and Citadel's April Fools content off. Integrated MC
left Cataclysm, Alex's Mobs and Born in Chaos's own stats at their defaults, and so does
this.

## Overlay

The same jars, with their modIds and sources, are in
[overlay.json](../tools/overlay.json), which `gto carry` reads to copy them into a new
build. A mod added or removed here changes there too. Candidates from Cosmic Frontiers
are sorted by risk in [candidates.md](./candidates.md), and the trial steps are in
[updating.md](./updating.md#a-mod-trial).
