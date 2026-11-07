# GTO 0.6.0 Difficulty Rules

The goal is Expert recipes without Expert's penalties: no rain or terrain explosions, no
progress lost when power runs low, and no shutdown when power runs out.

## How rules work

Rules live in `config/gtocore-rules.txt`. The preset and any changed rules are written
into a world when it's created and locked there; editing the file later changes new
worlds only. Under `preset = custom`, any rule left commented out takes the **Normal**
value. Each rule's comment in the file lists its easy, normal and expert values.

Only a world created on 0.6 with the Custom preset can mix rules like this. A 0.5.6 world
migrated to 0.6 keeps the Normal preset for good. In 0.5.6 the difficulty was a single
setting, `gamePlay.difficulty` in `config/gtocore.yaml`.

`New Worldaa` was created at 15:54 on 2026-11-07, five minutes after the rules file was
saved. To confirm what a world got, open the in-game View Rules screen.

## Rules set in the file

| Rule | Name | Value | Normal |
| --- | --- | --- | --- |
| `recipes.tier` | Recipe Difficulty | expert | normal |
| `recipes.mod_integration` | Mod Recipe Difficulty | expert | normal |
| `recipes.ore_processing` | Ore Processing Difficulty | expert | normal |
| `recipes.circuit_assembly_line_amount` | Circuit Assembly Line Component Amount | 4 | 3 |
| `resources.fluid` | Fluid Resource Difficulty | expert | normal |
| `resources.loot` | Loot Difficulty | expert | normal |
| `gtm.rubber_tree_chance` | Rubber Tree Spawn Chance | 0.5 | 1.0 |
| `gtm.bedrock_ore_distance` | Bedrock Ore Vein Distance | 3 | 2 |
| `gtm.harder_rods` | Harder Rods | true | false |
| `gtm.harder_bricks` | Harder Bricks | true | false |
| `gtm.hard_multiblock_controllers` | Hard Multiblock Controller Recipes | true | false |
| `gtm.require_gt_tools` | Require GT Tools | false | true |
| `gtm.explosion_damages_terrain` | Explosions Damage Terrain | false | true |
| `gtm.harmless_active_transformers` | Harmless Active Transformers | true | false |
| `gtm.electric_tool_damage_chance` | Electric Tool Damage Chance (%) | 0 | 20 |

## Penalties left at Normal

These are off because they're commented out, and Normal turns them off. Expert turns
them on.

| Rule | Normal |
| --- | --- |
| `gtm.weather_explosions` | false |
| `gtm.recipe_progress_low_energy` | false |
| `machines.power_loss_shutdown` | false |
| `gtm.harder_circuits` | true (wanted on, and Normal has it) |

All `power.*` rules stay at Normal (decided 2026-11-07). Changing one now needs a new
world.

No rule clearly covers AE2's recipes; View Rules may show more than the file does.

## Sources

- The rule comments in `config/gtocore-rules.txt` from dev27
- [Rules guide](https://gtodyssey.com/articles/en/cdc6dab6-7923-5774-993d-1e7e9d02c305)
