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
| Iron's Spells | 24 | Iron, gold, copper and diamond become GT plates; its mithril is GTOCore's MV Mithril ingot, and its own scrap-to-ingot and ore recipes are off ([Iron's Spells](#irons-spells-2026-11-12)). Netherite, chains, nuggets, amethyst and the alchemist cauldron inks stay |
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
| `quarkblocks-1.0.0.jar` | Quark Blocks | The 514 Quark blocks the structures use, built here ([tools/quarkblocks](../tools/quarkblocks/README.md)) |
| `integrated_cataclysm_forge-1.0.5+1.20.1.jar` | Integrated Cataclysm | Rebuilds Cataclysm's boss arenas with Create, Quark and Supplementaries blocks, with other mods' loot in their chests (added 2026-11-12) |
| `L_Enders_Cataclysm-3.31.jar` | L_Ender's Cataclysm | Bosses, their arenas and boss-drop gear |
| `lionfishapi-3.0.jar` | Lionfish API | Library Cataclysm requires |
| `integrated_simply_swords-forge-1.3.1+1.20.1.jar` | Integrated Simply Swords | Simply Swords weapons for other mods' materials; only the silver ones are craftable here |
| `IMM v1.3.2-1.20.1.jar` | Integrated Mowzie's Mobs | Rebuilds Mowzie's Monastery, Umvunthana Grove, Frostmaw and Wroughtnaut structures (added 2026-11-12) |
| `mowziesmobs-1.8.2.jar` | Mowzie's Mobs | Bosses and mobs; its gear needs their drops, so nothing is gregified |
| `mowzies_cataclysm-1.2.1.jar` | Mowzie's Cataclysm | Cataclysm-style locator eyes (Ender Eye recipes) for Mowzie's boss structures |
| `IBOMD v1.0.0-1.20.1.jar` | Integrated Bosses of Mass Destruction | Rebuilds BOMD's Lich Tower, Obsidilith and Gauntlet arenas (added 2026-11-12) |
| `BOMD-Forge-1.20.1-1.1.2.jar` | Bosses of Mass Destruction | Four bosses; its recipes need their drops or netherite scrap, so nothing is gregified |
| `CerbonsAPI-Forge-1.20.1-1.1.0.jar` | Cerbon's API | Library BOMD requires |
| `legendarymonsters-2.2.4 MC 1.20.1.jar` | Legendary Monsters | Bosses and their structures (added 2026-11-12); gear needs their drops, so nothing is gregified |
| `crittersandcompanions-forge-1.20.1-2.7.1.jar` | Critters and Companions | Small ambient mobs and pets; its vanilla-metal dragonfly armor and grappling hook are left as they are |
| `moremobvariants-forge+1.20.1-1.3.0.1.jar` | More Mob Variants | Skin variants for vanilla mobs |

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
BOMD's other data. Quark's variant chests, furnaces,
crate and blossom sign become the vanilla blocks, keeping their loot and text; its wraith
and forgotten mobs become a stray and a skeleton; 760 Quark entities such as glass item
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
| `Jadens-Nether-Expansion-2.3.5.jar` | Jaden's Nether Expansion | Nether mobs, blocks, structures and the Black Ice Glaciers biome; its netherite recipes come after HV, so nothing is gregified |
| `ElysiumAPI-1.20.1-1.1.3.jar` | Elysium API | Library Jaden's requires |
| `Incendium_1.20.x_v5.3.5.jar` | Incendium | Nether terrain and 8 biomes, 9 structures and loot-only weapons |
| `MoogsEndStructures-universal-1.20-2.1.0.jar` | MES - Moog's End Structures | 24 End structures, no recipes |
| `MoogsStructureLib-forge-1.20-3.1.2.jar` | Moog's Structure Lib | Library MES requires; held at 3.1.2 |
| `Nullscape_1.20.x_v1.2.8.jar` | Nullscape | End terrain and 3 biomes, no items |

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

Passed a staging trial on 2026-11-12. Neither gets recipe overrides.

| Jar | Mod | What it does |
| --- | --- | --- |
| `Delightful-1.20.1-3.8.1.jar` | Delightful | Farmer's Delight foods, wild cantaloupe, mini melons and salmonberries, and knives from other mods' metals |
| `knavesneeds-forge-1.20.1-3.1.0-beta.1.jar` | Knaves' Needs | Simply Swords weapons for other mods' materials; only Deeper Darker's Warden set loads here |

Delightful's knives are one GT ingot or gem and a stick, like Farmer's Delight's own
knives, which GTO leaves alone too. Knaves' Needs gates every set on its mod; the
Warden weapons need reinforced echo shards, which GTO puts behind GT processing. Its
resonarium set doesn't show, since GTO reworks Deeper Darker's items (`DDItemsMixin`).
The 3.1.0 beta is the only build on Fzzy Config, which the pack already has; 2.0 (2023)
needs Architectury.

EMI logs `Exception thrown registering repair recipes` six times since this batch: an
item whose repair material is empty, so EMI skips its anvil recipe. It's harmless.

## Born In Configuration (2026-11-12)

Passed a staging trial on 2026-11-12.

| Jar | Mod | What it does |
| --- | --- | --- |
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
| `tlm-self-talk-1.4.1-forge-1.20.1.jar` | Self-Talk | Maids talk to themselves and greet you |
| `solmaid-1.0.1.jar` | Spice of Life: Maid | Spice of Life for maids |
| `solmaiddream-1.0.1.jar` | Spice of Life: Maids' Dream | Rewards maids for a varied diet |
| `tamablefairy-1.2.0-beta.5-forge+mc1.20.1.jar` | Tamable Fairy | Tame the maid fairies |
| `touhou-maid-affection-1.7.5.2.jar` | Touhou Maid: Affection | Kissing and bond abilities: Emergency Rescue shields you from a fatal hit, Random Gift brings items |
| `youkaishomecoming-2.7.2.jar` | Youkai's Homecoming | Japanese food, crops and cooking utensils, sakura biomes, Hakurei Shrine and two nests, Touhou characters and animals; bundles L2 Harvester and its libraries. Patched, see below |

**Maid Spell stays at 1.8.0.1.** From 1.9.0 it's a bootstrap jar that registers a
ModLauncher service (`maidspell_hurt_head`), and `gto_native` refuses unknown services,
so the game stops before a crash report. 1.8.0.1 is the last plain jar. It's built for
Iron's Spells: its structures' loot names 49 Iron's items, all of which 3.16.3 has.
[structures.py](../tools/structures.py) kept them off (`DISABLED_NAMESPACES`) until
[Iron's Spells](#irons-spells-2026-11-12) came in.

**Two jars are patched** by [mixinpatch.py](../tools/mixinpatch.py), rerun after
updating either: Maid Storage Manager's `JEIRecipeTransferHook` fails against the
pack's JEI 15.59 (it applies whenever JEI is installed) and left JEI's recipe transfer
button unloadable, and Youkai's `CriterionGridMixin` wrapped a call Better Advancements
0.6.0.73 doesn't make and crashed the game on launch.

**Maidsoul Kitchen can't run Youkai's kettle or fermentation tank**: it calls 9 methods
Youkai's 2.7.2 no longer has (its kettle accessor wants a `MAP` field that 2.6.1
lacks too), and blocks those tasks. `YhcTeaKettleTaskEnabled` and
`YhcFermentationTaskEnabled` are false in `maidsoulkitchen-common.toml`, but its Maid
Storage Manager kettle and fermentation tasks have no toggle, so it still posts a chat
warning at every login; nothing switches that off. Kept anyway, since the rest of its
tasks work. It and Maid Storage Manager
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

With Iron's Spells in (2026-11-12), Maid Spell's structures generate again.

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
Manager, Maidsoul Kitchen, Cataclysm, Reliable Recipes, Reliable Remover and TrashSlot,
plus Iron's Spells' `JeiPlugin` since it came in. They passed staging on 2026-11-12, with EMI loading and its search working. The file is
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

Passed two staging trials on 2026-11-12, the second with the overrides below. `gto map
--mod` found no ModLauncher service and no mixin GTO overwrites; Curios, GeckoLib and
Player Animator already ship in dev27. Taken from the Integrated MC instance.

| Jar | Mod | What it does |
| --- | --- | --- |
| `irons_spellbooks-1.20.1-3.16.3.jar` | Iron's Spells 'n Spellbooks | Spells, spell books, scrolls and inks, mage armour, curios, bosses and 9 structure sets (towers, catacombs, a citadel) |
| `irons_lib-1.20.1-2.2.0.jar` | Iron's Lib | Its required library |

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

Its JEI plugin is listed in `gtocore.yaml` ([EMI and JEI plugins](#emi-and-jei-plugins-2026-11-12)).
Harmless log lines: EMF gives up on the pyrium staff's two model parts, and Maid
Storage Manager logs `cooked_ice_spider_egg_from_campfire_cooking` as added twice.

## Overlay

The same jars, with their modIds and sources, are in
[overlay.json](../tools/overlay.json), which `gto carry` reads to copy them into a new
build. A mod added or removed here changes there too. Candidates from Cosmic Frontiers
are sorted by risk in [candidates.md](./candidates.md), and the trial steps are in
[updating.md](./updating.md#a-mod-trial).
