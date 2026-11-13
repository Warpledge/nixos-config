# GTO 0.6.0 World Rules

Every rule in `config/gtocore-rules.txt` as shipped in 0.6.0-dev27, read from the
client instance's file on 2026-11-12. How rules lock into a world and which this world
got are in [../difficulty-rules.md](../difficulty-rules.md); this is the reference.

All 102 rules are marked adjustable, and under `preset = custom` a rule left commented
out takes the Normal value. "= preset" means the rule follows the base preset's name
(easy, normal or expert) and is Normal under Custom. The last column is the value the
client's file sets, blank where it's commented out. Every change needs a game restart
and only reaches worlds created afterwards (GTOCore-Main `docs/world-rules.md`).

## Rules that reach other mods

Going by the names, these are the ones to keep in mind when adding a mod; how far each
reaches into a new mod's content hasn't been tested.

- `recipes.mod_integration` sets the difficulty of GTO's recipes for the mods it
  integrates. A new mod's recipes aren't in that set.
- `gtm.remove_vanilla_block_recipes`, `gtm.hard_wood`, `gtm.hard_iron`,
  `gtm.hard_redstone`, `gtm.hard_glass`, `gtm.hard_dye`, `gtm.nerf_paper` and
  `gtm.nerf_wood_crafting` change vanilla recipes, so a new mod's recipe that makes
  planks, glass, paper or iron parts the vanilla way can bypass them.
- `resources.loot` sets loot difficulty; `survival.mob_enhancement` the mob health
  and damage boost ([mixins.md](./mixins.md#entities-and-mobs)).
- `survival.ultimine_limit` caps FTB Ultimine.

## All rules

The values are easy / normal / expert from each rule's comment in the file.

### Recipes

| Rule | Name | Easy / Normal / Expert | Allowed | Client file |
| --- | --- | --- | --- | --- |
| `recipes.tier` | Recipe Difficulty | = preset | easy, normal, expert | **expert** |
| `recipes.mod_integration` | Mod Recipe Difficulty | = preset | easy, normal, expert | **expert** |
| `recipes.ore_processing` | Ore Processing Difficulty | = preset | easy, normal, expert | **expert** |
| `recipes.duration_multiplier` | Recipe Duration Multiplier | 1.0 / 1.0 / 1.0 | 0.001 ~ 1000 |  |
| `recipes.circuit_assembly_line_amount` | Circuit Assembly Line Component Amount | 3 / 3 / 4 | 1 ~ 64 |  |

### Resources & World

| Rule | Name | Easy / Normal / Expert | Allowed | Client file |
| --- | --- | --- | --- | --- |
| `resources.fluid` | Fluid Resource Difficulty | = preset | easy, normal, expert | **expert** |
| `resources.loot` | Loot Difficulty | = preset | easy, normal, expert |  |
| `gtm.rubber_tree_chance` | Rubber Tree Spawn Chance | 1.5 / 1.0 / 0.5 | 0 ~ 10 |  |
| `gtm.bedrock_ore_distance` | Bedrock Ore Vein Distance | 1 / 2 / 3 | 1 ~ 64 |  |
| `gtm.infinite_bedrock_resources` | Infinite Bedrock Resources | true / false / false | true, false |  |

### Steam Age

| Rule | Name | Easy / Normal / Expert | Allowed | Client file |
| --- | --- | --- | --- | --- |
| `steam.multiblock_duration` | Steam Multiblock Duration Multiplier | 1.2 / 1.5 / 1.6 | 0.01 ~ 100 |  |
| `steam.multiblock_parallels` | Steam Multiblock Max Parallels | 16 / 8 / 8 | 1 ~ 1024 |  |
| `steam.large_multiblock_duration` | Large Steam Multiblock Duration Multiplier | 1.0 / 1.2 / 1.5 | 0.01 ~ 100 |  |
| `steam.large_multiblock_parallels` | Large Steam Multiblock Max Parallels | 64 / 32 / 32 | 1 ~ 1024 |  |
| `steam.circuit_assembler_parallels` | Large Steam Circuit Assembler Max Parallels | 8 / 4 / 4 | 1 ~ 1024 |  |
| `steam.circuit_assembler_duration` | Large Steam Circuit Assembler Multiply Mode Duration | 2 / 4 / 6 | 1 ~ 100 |  |
| `steam.circuit_assembler_steam_cost` | Large Steam Circuit Assembler Multiply Mode Steam Cost | 2 / 4 / 6 | 1 ~ 100 |  |
| `steam.circuit_assembler_output` | Large Steam Circuit Assembler Multiply Mode Output | 4 / 2 / 2 | 1 ~ 100 |  |
| `steam.circuit_assembler_engraving` | Large Steam Circuit Assembler Engraving Amount | 8 / 16 / 32 | 1 ~ 1024 |  |
| `steam.solar_boiler_rate` | Large Solar Boiler Steam per Tube | 20 / 15 / 10 | 1 ~ 10000 |  |
| `steam.storage_tank_capacity` | Large Steam Storage Tank Capacity | 12960000000 / 8640000000 / 6480000000 | 1 ~ 21474836470 |  |
| `gtm.boiler_output` | Boiler Factor | 4 / 2 / 1 | 1 ~ 64 |  |

### Power & Energy

| Rule | Name | Easy / Normal / Expert | Allowed | Client file |
| --- | --- | --- | --- | --- |
| `power.generator_array_multiplier` | Generator Array Multiply | 2.0 / 1.3 / 1.3 | 0 ~ 100 |  |
| `power.generator_array_loss` | Generator Array Wireless Loss | 4 / 5 / 8 | 0 ~ 9 |  |
| `power.generator_array_limit` | Generator Array Internal Generator Limit | 16 / 4 / 4 | 1 ~ 64 |  |
| `power.lightning_rod_break_chance` | Lightning Rod Break Probability | 0.2 / 0.3 / 0.4 | 0 ~ 1 |  |
| `power.wind_mill_amperage` | Wind Turbine Output Amperage | 2 / 1 / 1 | 1 ~ 64 |  |
| `power.fuel_cell` | Flow Fuel Cell Mechanics | = preset | easy, normal, expert |  |
| `power.mega_turbine_regulator` | Mega Turbine High-Speed Regulator | false / false / true | true, false |  |
| `power.mega_turbine_high_speed_output` | Mega Turbine High Speed Mode Output Multiplier | 4.0 / 3.0 / 2.5 | 0 ~ 100 |  |
| `power.mega_turbine_high_speed_rotor_damage` | Mega Turbine High Speed Mode Rotor Damage Multiplier | 4 / 10 / 12 | 1 ~ 1000 |  |
| `power.mega_turbine_high_speed_fault` | Mega Turbine High Speed Mode Machine Fault Multiplier | 4.0 / 8.0 / 10.0 | 0 ~ 1000 |  |
| `power.magic_generator_amperage` | Magic Generator Output Amperage | 8 / 4 / 2 | 1 ~ 64 |  |
| `power.fuel_efficiency_offset` | Fuel Generator Efficiency Offset (%) | 15 / 0 / -15 | -100 ~ 100 |  |
| `power.bio_stimulation_duration` | Bio Stimulation Duration (ticks) | 120 / 240 / 360 | 1 ~ 72000 |  |
| `power.wireless_energy_unit` | Wireless Energy Tower Unit Difficulty | = preset | easy, normal, expert |  |
| `gtm.generate_energy_no_match` | Generators Burn Fuel When Full | false / false / true | true, false |  |

### Machines

| Rule | Name | Easy / Normal / Expert | Allowed | Client file |
| --- | --- | --- | --- | --- |
| `machines.fluid_pipe_throughput` | Fluid Pipe Throughput Multiplier | 3 / 2 / 1 | 1 ~ 64 |  |
| `machines.maintenance_wear` | Damage Rate | 1 / 2 / 3 | 0 ~ 100 |  |
| `machines.maintenance_random_failures` | Maintenance Failures | false / true / true | true, false |  |
| `machines.configurable_maintenance_max` | Load Regulating Auto Maintenance Duration Multiplier Maximum | 1.3 / 1.2 / 1.1 | 0.01 ~ 100 |  |
| `machines.configurable_maintenance_min` | Load Regulating Auto Maintenance Duration Multiplier Minimum | 0.7 / 0.8 / 0.9 | 0.01 ~ 100 |  |
| `machines.muffler` | Muffler Mechanics | = preset | easy, normal, expert |  |
| `machines.power_loss_shutdown` | Shut Down on Power Loss | false / false / true | true, false |  |
| `machines.parallel_hatch_bonus` | Parallel Hatch Tier Bonus | 1 / 0 / 0 | 0 ~ 5 |  |
| `machines.processing_plant_parallel` | Processing Plant Parallels per Tier | 4 / 2 / 2 | 1 ~ 1024 |  |
| `machines.time_twister_energy` | Time Twister Energy Multiplier | 4 / 8 / 16 | 1 ~ 1024 |  |
| `machines.wireless_charger_amount` | Field Generator Required Amount | 1 / 16 / 64 | 1 ~ 64 |  |

### ME Network

| Rule | Name | Easy / Normal / Expert | Allowed | Client file |
| --- | --- | --- | --- | --- |
| `me.simple_pattern_buffer_slots` | ME Simple Pattern Buffer Slots | 9 / 0 / 0 | 0 ~ 64 |  |
| `me.muffler_amplifier_max` | ME Muffler Hatch Amplifier Maximum | 4 / 16 / 64 | 1 ~ 64 |  |
| `me.muffler_amplifier_min` | ME Muffler Hatch Amplifier Minimum | 1 / 4 / 16 | 0 ~ 64 |  |
| `gtm.me_hatch_energy` | ME Hatch Energy Usage | 32.0 / 64.0 / 96.0 | 0 ~ 100000 |  |

### Research & Space

| Rule | Name | Easy / Normal / Expert | Allowed | Client file |
| --- | --- | --- | --- | --- |
| `research.scan_duration` | Scan Duration (ticks) | 200 / 400 / 600 | 1 ~ 72000 |  |
| `research.repeated_scan_penalty` | Repeated Scan Factor | 0.25 / 0.0625 / 0.015625 | 0 ~ 1 |  |
| `research.tech_tree` | Tech Tree Difficulty | = preset | easy, normal, expert |  |
| `research.energy_data_warmup` | Energy Data Hatch Warm-up (ticks) | 600 / 900 / 1200 | 0 ~ 720000 |  |
| `research.space_elevator_computation` | Space Elevator Link Computation Factor | 1.5 / 3.0 / 4.5 | 0 ~ 1000 |  |
| `research.space_data_module_works` | Space Elevator Engineering Data Workload | 50 / 50 / 75 | 1 ~ 100000 |  |

### Survival & Misc

| Rule | Name | Easy / Normal / Expert | Allowed | Client file |
| --- | --- | --- | --- | --- |
| `survival.quest_subsidy` | Quest Subsidy | = preset | easy, normal, expert |  |
| `survival.mob_enhancement` | Mob Enhancement | false / true / true | true, false |  |
| `survival.regen_food_threshold` | Extra Regeneration Food Threshold | 5 / 15 / 15 | 0 ~ 20 |  |
| `survival.regen_factor` | Extra Regeneration Strength | 3 / 2 / 1 | 1 ~ 100 |  |
| `survival.ultimine_limit` | Ultimine Limit | 64 / 32 / 16 | 1 ~ 4096 |  |
| `survival.virtual_coin_cost` | Virtual Coin Base Workload | 250 / 250 / 1000 | 1 ~ 1000000000000 |  |

### GTM Recipes

| Rule | Name | Easy / Normal / Expert | Allowed | Client file |
| --- | --- | --- | --- | --- |
| `gtm.disable_manual_compression` | Disable Manual Compression | false / true / true | true, false |  |
| `gtm.harder_rods` | Harder Rods | false / false / true | true, false | **true** |
| `gtm.harder_bricks` | Harder Bricks | false / false / true | true, false | **true** |
| `gtm.nerf_wood_crafting` | Nerf Wood Crafting | false / true / true | true, false |  |
| `gtm.hard_wood` | Hard Wood Recipes | false / true / true | true, false |  |
| `gtm.hard_iron` | Hard Iron Recipes | false / true / true | true, false |  |
| `gtm.hard_redstone` | Hard Redstone Recipes | false / true / true | true, false |  |
| `gtm.hard_tool_armor` | Hard Tool and Armor Recipes | false / true / true | true, false |  |
| `gtm.hard_misc` | Hard Misc Recipes | false / true / true | true, false |  |
| `gtm.hard_glass` | Hard Glass Recipes | false / true / true | true, false |  |
| `gtm.nerf_paper` | Nerf Paper Crafting | false / true / true | true, false |  |
| `gtm.hard_advanced_iron` | Hard Advanced Iron Recipes | false / true / true | true, false |  |
| `gtm.hard_dye` | Hard Dye Recipes | false / true / true | true, false |  |
| `gtm.harder_charcoal` | Harder Charcoal | false / true / true | true, false |  |
| `gtm.flint_and_steel_requires_steel` | Flint and Steel Requires Steel | false / true / true | true, false |  |
| `gtm.remove_vanilla_block_recipes` | Remove Vanilla Block Recipes | false / true / true | true, false |  |
| `gtm.remove_vanilla_tnt` | Remove Vanilla TNT Recipe | false / true / true | true, false |  |
| `gtm.casings_per_craft` | Casings per Craft | 2 / 1 / 1 | 1 ~ 3 |  |
| `gtm.harder_circuits` | Harder Circuit Recipes | false / true / true | true, false |  |
| `gtm.hard_multiblock_controllers` | Hard Multiblock Controller Recipes | false / false / true | true, false | **true** |

### GTM Machines & Tools

| Rule | Name | Easy / Normal / Expert | Allowed | Client file |
| --- | --- | --- | --- | --- |
| `gtm.enchanted_tools` | Enchanted Tools | true / false / false | true, false |  |
| `gtm.recipe_progress_low_energy` | Reset Progress on Low Energy | false / false / true | true, false |  |
| `gtm.require_gt_tools` | Require GT Tools | false / true / true | true, false |  |
| `gtm.weather_explosions` | Weather and Terrain Explosions | false / false / true | true, false |  |
| `gtm.explosion_damages_terrain` | Explosions Damage Terrain | false / true / true | true, false | **false** |
| `gtm.harmless_active_transformers` | Harmless Active Transformers | true / false / false | true, false |  |
| `gtm.cleanroom` | Enable Cleanroom | false / true / true | true, false |  |
| `gtm.clean_multiblocks` | Multiblocks Ignore Cleanroom | true / false / false | true, false |  |
| `gtm.maintenance` | Enable Maintenance | false / true / true | true, false |  |
| `gtm.dual_chamber_mode` | Dual Chamber Pressurization Mode | 1 / 1 / 3 | 1 ~ 3 |  |
| `gtm.tiered_casings` | Tiered Casings | false / true / true | true, false |  |
| `gtm.ordered_assembly_line_items` | Ordered Assembly Line Items | false / true / true | true, false |  |
| `gtm.ordered_assembly_line_fluids` | Ordered Assembly Line Fluids | false / false / true | true, false | **true** |
| `gtm.electric_tool_energy` | Electric Tool Energy Use (%) | 100 / 200 / 300 | 0 ~ 100000 |  |
| `gtm.prospector_energy` | Prospector Energy Use (%) | 100 / 200 / 300 | 0 ~ 100000 |  |
| `gtm.electric_tool_damage_chance` | Electric Tool Damage Chance (%) | 10 / 20 / 40 | 0 ~ 100 | **0** |
| `gtm.disable_hazards` | Disable Material Hazards | false / false / false | true, false |  |

### Special Challenges

| Rule | Name | Easy / Normal / Expert | Allowed | Client file |
| --- | --- | --- | --- | --- |
| `research.no_space_challenge` | No Space Challenge | false / false / false | true, false |  |

## Sources

- `config/gtocore-rules.txt` in the dev27 client instance, 2026-11-12, tabulated by a
  one-off parse of its comments
- GTOCore-Main `0.6.0` `docs/world-rules.md`
