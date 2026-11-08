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
| `AmbientSounds_FORGE_v6.3.11_mc1.20.1.jar` | AmbientSounds | Expands ambient sounds |
| `Presence Footsteps [FORGE] 1.0.0.jar` | Presence Footsteps | Footstep sounds by surface (Forge port) |
| `Sounds-2.2.1+1.20.1+forge.jar` | Sounds | New sound effects and reworked vanilla ones |
| `sound-physics-remastered-forge-1.20.1-1.5.1.jar` | Sound Physics Remastered | Sound attenuation, reverb and absorption through blocks |
| `coolrain-1.20.1-Forge-1.0.3.jar` | Cool Rain Reforged | Rain visuals |
| `particular-1.20.1-Forge-1.5.7.jar` | Particular Reforged | Ambient effects such as falling leaves, fireflies and waterfall spray |
| `particle_core-0.3.3+1.20.1+forge.jar` | Particle Core | Particle culling and rendering optimization |
| `entity_model_features-3.3.12-1.20.1-forge.jar` | Entity Model Features | Custom entity model (CEM) resource pack support |
| `entity_texture_features-7.2.7-1.20.1-forge.jar` | Entity Texture Features | Resource-pack entity texture features; EMF needs it |
| `smoothswapping-0.9.3.2-1.20.1-forge.jar` | Smooth Swapping | Animates items moving in inventories |
| `better_climbing-forge-3.jar` | Better Climbing | Climbing improvements |
| `connectiblechains-forge-1.20.1-2.2.5.jar` | Reconnectible Chains | Decorative chains between fences |
| `zipline-forge-1.20.1-1.3.0.jar` | Ziplines: Rezipped! | Ziplines |
| `trashslot-forge-1.20.1-15.1.5.jar` | TrashSlot | Trash slot in the inventory screen |
| `creeperoverhaul-3.0.2-forge.jar` | Creeper Overhaul | Biome-specific creepers |
| `endermanoverhaul-forge-1.20.1-1.0.4.jar` | Enderman Overhaul | Biome-specific endermen |
| `fzzy_config-0.7.7+1.20.1+forge.jar` | Fzzy Config | Library for Particle Core |
| `mru-1.0.41+1.20.1-forge.jar` | MRU | Library for Sounds; CurseForge only, installed through Prism |
| `yet_another_config_lib_v3-3.6.6+1.20.1-forge.jar` | YACL | Library; Sounds and MRU call it but don't declare it, so Prism doesn't pull it in |

Kotlin for Forge, which Particle Core and Fzzy Config need, already ships in dev27.

**Configs:** Cosmic Frontiers only changed Particular, to `fallingLeaves = true` and a
falling-leaf `spawnChance` of 60; 1.5.7's defaults already match. Sounds ships
Minecraft 1.21 `c:` tags (mace, breeze rod), which log `Couldn't load tag` errors on
1.20.1 and are harmless. EMF, ETF, Presence Footsteps and Particle Core crashed a
dedicated server in Cosmic Frontiers, so a GTO server would need them client-only.

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
other dropped mods are in [candidates.md](./candidates.md#skip).

| Jar | Mod | What it does |
| --- | --- | --- |
| `Terralith_1.20.x_v2.5.4.jar` | Terralith | Replaces vanilla's overworld biomes with about 100 of its own. Can't be removed from a world later |
| `tectonic-3.0.17-forge-1.20.1.jar` | Tectonic | Reshapes overworld terrain: continents, mountain ranges, rivers |
| `lithostitched-forge-1.20.1-1.4.11.jar` | Lithostitched | Worldgen library Tectonic requires |
| `structurify-forge-2.0.43+mc1.20.1.jar` | Structurify | Structure spacing and placement checks; uses dev27's YACL |
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
| `config/tectonic.json` | Defaults plus `ultrasmooth`, `elevation_boost` 0.2, `min_y`/`max_y` -128/544, `ocean_offset` -0.5, `continents_scale` 0.3, `ridge_scale` 0.3, `flat_terrain_skew` -0.1 | Smoother, taller terrain with rare oceans. Above -0.45, deep oceans and their monuments stop spawning. GT ores below -64 are unchecked |
| `config/terrablender.toml` | `overworld_region_size` 4 | Smaller biome-mod regions, so they swap more often |
| `config/biomeswevegone/world_generation.json` | 11 of dev27's BWG biomes on, as in Cosmic Frontiers; region weights 8 to 1 | At 8, BWG's 3 regions outweighed the vanilla region (10, where Terralith's biomes live) and the world was mostly BWG |
| `config/structurify.json` | Global flatness check (`AUTO`, max height difference 21), `prevent_structure_overlap` | Structures skip steep ground. Written by hand: the in-game screen didn't save on 2026-11-07 |
| `config/bettermineshafts-forge-1_20.toml` | `Enable Ore Deposits` false | Its deposits are vanilla ores outside GT's veins |
| `config/DistantHorizons.toml` | `chunkGeneratorMode` `INTERNAL_SERVER`, `generatorPlan` `SURFACE_THEN_CHUNKS` | DH saves real chunks as it pregenerates, as on the GTNH server. Its "C2ME missing" warning is expected; C2ME's unofficial Forge port isn't safe with GT and these worldgen mods |

## Overlay

The same jars, with their modIds and sources, are in
[overlay.json](../tools/overlay.json), which `gto carry` reads to copy them into a new
build. A mod added or removed here changes there too. Candidates from Cosmic Frontiers
are sorted by risk in [candidates.md](./candidates.md), and the trial steps are in
[updating.md](./updating.md#a-mod-trial).
