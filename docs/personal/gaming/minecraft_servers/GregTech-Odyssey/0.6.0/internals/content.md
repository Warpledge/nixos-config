# GTO's Own Content

What `gtocore-forge-1.20.1-26.11.1.jar` (0.6.0-dev27) adds, by category, read
2026-11-12. Most of it is registered in code, so the jar's `data/` holds little; counts
of registered things come from its English lang file. For the full lists, open EMI in
game or list the jar.

## Registered in code

| Category | Count | Where it comes from |
| --- | --- | --- |
| Lang entries | 12584 | `assets/gtocore/lang/en_us.json` |
| Blocks | 1883 `block.*` keys | GTM's registrate, through gtocore's `GTO*` data classes |
| Items | 1210 `item.*` keys | same |
| Materials | 1419 `material.*` keys | GTM material registry; GTO adds tag prefixes (54 `tagprefix.*` keys) |
| Block models and states | 2300 models, 461 blockstates, 3867 textures | `assets/gtocore/` |
| Recipes | no recipe JSON in the jar | generated in code at load, then run through gtolib's `RecipeManagerMixin` |
| Recipe types | `GTORecipeTypes` | shown as EMI categories; the GTM categories marked visible, plus GTO's ore processing, ore vein, bedrock ore and fluid, nanites, research, tech tree, satellite and Alfheim pages |

Ores and veins are GTM's vein system, with GTO's veins registered in code; EMI's ore
vein and bedrock ore pages list them. Vanilla ore blocks are removed from every ore
feature ([mixins.md](./mixins.md#world-and-chunk-ticking)).

## Data in the jar

| Kind | What's there |
| --- | --- |
| Dimensions | 21 under `gtocore:`: `barnarda_c`, `ceres`, `enceladus`, `ganymede`, `io`, `pluto`, `titan` and `solar_surface`, each with an `_orbit`, plus `ancient_world`, `saturn_ring`, `create`, `flat` and `void` |
| Biomes | 13: one per planet, `solar_surface_tartarite_biome`, `void`, and `ad_astra:orbit` |
| Worldgen | `meteorite`, `solar_surface_tartarite_blob` and two biome trees (configured and placed features); `asteroids` and `solar_surface_biomes` noises; `ad_astra:orbit` noise settings |
| Structures | `space_station.nbt` |
| Loot tables | Under `ad_astra:`, 10 planet globes and the GTO flag; under `gtocore:`, 4 laureril mana pool and source jar blocks. Dynamic loot and reward bags are added in code (`GTOLoots`) |
| Tags | 31 `gtceu:` and 18 `gtocore:` item tag files; vanilla block tags for mining tools, carver replaceables and wither immunity; Ad Astra entity tags `lives_without_oxygen` (24), `can_survive_extreme_heat` (21) and `can_survive_extreme_cold` (13). None use `replace: true` |
| Structure biome tags | `has_structure/igloo` adds `gtocore:enceladus_biome`, `has_structure/mineshaft` adds `gtocore:ancient_world_biome` |
| Curios | 2 slot and 2 entity files |
| Other mods' data | 2 Apotheosis enchanting recipes; Botania block tags |

Planet travel, gravity, oxygen and temperature go through gtolib's Ad Astra overwrites
([mixins.md](./mixins.md#ad-astra)). The Ad Astra mob tags here are GTO's; the
`warpledge-gto` datapack adds the Nether and End mobs to them
([../../datapack/](../../datapack/)).

## Quests and loot changes

The quest book is FTB Quests with GTO's mixins on commands, editing mode, quests and
item rewards; how far it goes is in [../quests.md](../quests.md). `GTOLoots.removal`
lists ExtendedAE's EMC and oversize interface and Farmer's Respite's kettle block loot
tables in a filter (where the filter is applied wasn't traced).

## Sources

- `unzip -l` of the dev27 gtocore jar and its `en_us.json`, 2026-11-12
- GTOCore-Main `0.6.0` `com/gtocore/common/data/GTOLoots.java` and
  `com/gtocore/integration/emi/GTEMIPlugin.java`
