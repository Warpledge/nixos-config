# Added Mods

Detailed write-ups for every manually added mod. For the server mod list, see [server.md](server.md).

---

## ModernKeyBinding — Modifier Key Support
- **Modrinth:** https://modrinth.com/mod/modernkeybinding
- Backports modifier keys (Ctrl+G, Alt+S, etc.) and key conflict context to 1.7.10
- Complementary to Controlling (already in base pack) — does not replace it
- HodgePodge disables its conflicting mixin automatically when this is present

---

## GT: Not Leisure (GTNL) `v0.2.4` — Endgame Content Expansion

- **Repo:** https://github.com/ABKQPO/GT-Not-Leisure
- **Jar:** `sciencenotleisure-0.2.4.jar`
- **Origin:** Chinese GTNH community mod — no English wiki, documentation and issues are in Chinese
- **Config:** `config/GTNotLeisure/GTNotLeisure.cfg`

**What it adds:**
- 217+ multiblocks spanning endgame power gen, ore processing, magic/tech integration, and automation
- **AssemblerMatrix** — AE2-integrated autocrafting multiblock. Built at LuV/IV tier. Regular CrafterCasings give 2048 parallel per casing (autocrafting jobs, not GT processing). SingularityCrafterCasings give INT.MAX parallel but require UIV-tier Infinity frames + SpaceTime fluid — properly gated
- **ReAvaritia** — bundled Avaritia content (Infinity gear, Neutron Collector, Extreme Anvil, Soul Farmland). Legitimate crafting path requires Infinity Ingots, neutronium, crystal matrix, etc.
- Magic/tech integration: Blood Magic, Thaumcraft, Botania, Twilight Forest automation multiblocks
- Power generation: Real Artificial Star (extreme EU/t, requires UEV/UIV fuel rods)

**Mixins on existing GTNH machines:**
- **Integrated Ore Factory** (`enableIntegratedOreFactoryChange=true`): Changes parallel to `65,536 × tier`, adds ExoticEnergy hatch support, and adds 6 ore processing modes including chemical bath. Throughput still gated by lubricant (1L/parallel) and distilled water (10L/parallel). This is a buff to a vanilla GTNH machine — disable with `B:enableIntegratedOreFactoryChange=false` if unwanted
- **Overpowered mixin folder** (misleading name): Just adds output chance bonus when overvolting machines (`(tier - baseTier) × 2.5%`). Minor QoL, not power creep

**Balance verdict:** Legitimate endgame expansion mod. Recipes follow normal GTNH tier gating — LuV/IV for mid-tier machines, UIV/Infinity materials for the highest-end content. Safe to run alongside vanilla GTNH progression.

**Known quirks:**
- Villager trades: all 5 vanilla villager types get trades for what appear to be Infinity Sword + full Infinity armor. Items are non-functional cardboard replicas via the GTNL Stick disguise system — cosmetic joke, not a real exploit. Disabled via `B:enableStickItem=false`
- `enableSomethingRecipe`: adds a Creative Maintenance Hatch recipe using HV materials — minor, not a concern

---

## EZNuclear `v1.0.7` — Nuclear Reactor Explosion Prevention
- **Repo:** https://github.com/czqwq/EZNuclear
- Intercepts nuclear reactor explosions and prevents them (configurable). Supports both Dragon and IC2-style reactors. Displays a message when an explosion is intercepted
- From the same author as EZMiner
- **Config:** `config/EZNuclear.cfg`
  - `B:DEExplosion=false` — Draconic Evolution reactor explosions disabled (default: `true`)
  - `B:IC2Explosion=false` — IC2 nuclear reactor explosions disabled (default: `true`)

---

## ElytraMining `v1.2.0` — Hammers & Falling Torches
- **Repo:** https://github.com/ElytraServers/ElytraMining
- Adds hammers that mine in flat or cubic areas (based on Thermal Foundation 1.12 hammers)
- Falling torches — torches drop like sand when their support block is broken
- No dependencies

---

## GTNHRates — Rates & QoL Overhaul *(replaces GTNH-CutCorners)*
- **Repo:** https://github.com/Sladki/GTNHRates
- GT machine energy/time discount, resource yield multipliers (crops, ores, bees, fluids), hammer prospecting improvements, singleblock miner stacking, NEI QoL — almost all values configurable on the fly
- **Config:** `config/gtnhrates.cfg`

| Setting | Value | Default | Note |
|---|---|---|---|
| `gtRecipesEnergyDiscount` | `4.0` | `4.0` | GT machine energy+time reduction |
| `gtOresDrops` | `4.0` | `4.0` | GT ore drop multiplier |
| `gtCoalOreDrops` | `16.0` | `16.0` | GT coal drop multiplier |
| `gtPumpOutput` | `4.0` | `4.0` | Underground fluid rig output |
| `gtToolsCraftingDurability` | `8.0` | `8.0` | GT tool crafting durability |
| `beesYield` | `4.0` | `4.0` | Forestry bee produce |
| `cropsYield` | `4.0` | `4.0` | Vanilla/Natura crop yields |
| `ic2CropsYield` | `4.0` | `4.0` | IC2 crop yields |
| `ic2RubberTreeResinYield` | `4.0` | `4.0` | Tree tap resin per extraction |
| `ic2RubberTreeSaplingsDropChanceMultiplier` | `2.0` | `2.0` | Rubber sapling drop chance multiplier |
| `gtSimpleMinersEnergyDiscount` | `1.0` | `1.0` | Singleblock miner energy only |
| `enableNEIBookmarksContents` | `false` | `true` | **DISABLED** — crashes on inventory open; adds bookmark namespace system that creates a null crafting group when bookmarking recipes with A, causing `BookmarkGridGenerator` NPE every render |

---

## Simple Storage (EZStorage) — Early-Game Storage Network
- **Repo:** https://github.com/LITW-Refined/EZStorage
- **Modrinth:** https://modrinth.com/mod/ezstorage
- Connect chests/drawers to a network block and access everything from one terminal — Tom's Storage equivalent for 1.7.10
- No channels or complex setup; scales with vanilla chests and Storage Drawers
- Pre-AE alternative — AE2 unlocks at EV tier (Titanium), Simple Storage bridges Steam Age through HV
- **Portable Storage Terminal range:** 16 blocks (hardcoded, not configurable)
- **Gregified recipes:** `scripts/simplestorage_gregified.zs` — all vanilla recipes replaced with GT materials

| Block | Recipe | Tier |
|---|---|---|
| Storage Core | 4x Stick (corners) + 4x Wood Plank (sides) + Flint | Pre-Steam |
| Storage Box (T1) | 4x Stick (corners) + 4x Wood Plank (sides) + Chest | Pre-Steam |
| Crafting Box | 4x Stick (corners) + 4x Wood Plank (sides) + Crafting Table | Pre-Steam |
| Condensed Storage Box (T2) | 4x Steel Plate (corners) + 4x Tin Cable (sides) + T1 Box | Steam Age |
| Hyper Storage Box (T3) | 4x Aluminium Plate (corners) + 4x Copper Cable (sides) + T2 Box | LV |
| Input Port (Inventory Proxy) | 4x Bronze Plate + 4x Steel Plate + Hopper | LV |
| Portable Storage Terminal | 2x Redstone Torch + 2x Glass Pane + 2x Tin Cable + 2x Iron Plate + Ender Pearl + Diamond | LV |

---

## EZMiner — Chain Mining & Blast Mining
- **Repo:** https://github.com/czqwq/EZMiner
- High-performance chain-mining mod for 1.7.10/GTNH. Two modes: **Chain Mode** (BFS flood-fill on connected same-type blocks) and **Blast Mode** (configurable radius with 5 sub-modes: All Blocks, Same Type, Tunnel, Ore Only, Logging)
- **HUD** shows active mode and live block count; **block outline preview** highlights targets through walls before mining begins
- Drops batch-collected at operation end (no mid-mining lag), durability checks, exhaustion cost per block, won't mine under player
- **VisualProspecting integration:** automatically records ore vein data to the VP map overlay when present
- **Controls:** Backtick = activate chain mining (hold or toggle), V = switch main mode, Scroll = cycle sub-modes
- **Config:** `config/EZMiner.cfg` — hot-reload via `/EZMiner reloadConfig`

| Setting | Default | Note |
|---|---|---|
| `bigRadius` | `8` | Max blast radius |
| `blockLimit` | `1024` | Max blocks per operation |
| `smallRadius` | `2` | Adjacency detection radius |
| `tunnelWidth` | `1` | Tunnel sub-mode width |
| `addExhaustion` | `0.025` | Hunger cost per block mined |
| `dropToPlayer` | `true` | Deliver drops directly to player inventory |
| `usePreview` | `true` | Show block outline preview |
| `chainActivationMode` | `0` | `0` = hold key, `1` = toggle |

- **Dependencies:** Forge 10.13.4.1614+ only — no Mixins required

---

## Twist-Stuff — BetterQuest Configs for Twist Space Technology
- **Repo:** https://github.com/AdityaVG13/Twist-Stuff
- Quest configs for the BetterQuest mod adding quest support for the Twist Space Technology mod
- Drop the quest data into the instance's BetterQuest config directory

---

## LagGoggles Legacy `v4.17.0` — In-World TileEntity Profiler
- **Repo:** https://github.com/FalsePattern/LagGogglesLegacy
- **Modrinth:** https://modrinth.com/mod/lglegacy
- Color-codes TileEntities and entities in-world by tick time consumption — point at any machine or block to see its lag contribution as a visual overlay
- Complements `spark` (which profiles globally); LagGoggles gives the per-block in-world view to pinpoint the culprit
- **Dependency:** `falsepatternlib-mc1.7.10-1.10.7.jar` (also required by other FalsePattern mods)

---

## Extreme Sound Muffler Legacy `v1.0.13`
- Client-side mod to selectively mute/adjust volume of any sound (0–100%)

---

## MineMenu `v1.7.10-1.2.0`
- Radial keybind menu — helps manage conflicting keybindings

---

## Spark `v1.10.35`
- Profiling and TPS/latency debugging tool
- Useful for diagnosing lag spikes
- See [performance.md](performance.md) for usage

---

## Distant Horizons Standalone
- **Repo:** https://github.com/DarkShadow44/DistantHorizonsStandalone
- 1.7.10 backport of Distant Horizons (LOD renderer) by DarkShadow44
- **Install:** Download Alpha 18 from releases, drop jar into `.minecraft/mods/`
- **Dependencies:** `lwjgl3ify` (v3.0.15+), `GTNHLib`, `UniMixins`
- **Angelica/shader compat:** Requires Angelica 2.1.12+, enable "Disable Terrain Fog" to prevent rendering issues
- **Known issues:** Memory grows over time (may crash), LOD updates occasionally fail (toggle render distance to fix), server-side unstable
- **Settings (desktop — 5800X3D + RX 9070 XT):**
  - LOD Chunk Render Distance: `128`
  - Quality Preset: `4. High`
  - CPU Load: `3. Balanced`
  - Enable Server Generation: `False`
  - Enable Cloud Rendering: `False`
  - Cave Culling: `True`
  - Distance Generator Mode: `6. Features`
  - No. of Threads: `4` (default 8 — leave headroom for GTNH)
  - Runtime % for Threads: `0.5` (default 1.0 — prevents DH competing with GT world gen)

---

## BoxPlusPlus — Production Line Encapsulator *(LuV-tier content)*
- **Repo:** https://github.com/RealSilverMoon/BoxPlusPlus
- Single GT multiblock that encapsulates entire multi-machine production lines internally — define up to 99 "processes" (each an NEI recipe from a real multiblock), set per-process parallelism, and the Box collapses them into one unified final recipe. Primary purpose: eliminate cross-machine logistics (pipes, AE2 item movement) for massive TPS savings in dense late-game bases
- **Structure:** Core + up to 3 concentric rings. Ring count scales capability:

| Rings | Max Parallel/Process | Max Processes | Overclocking |
|---|---|---|---|
| R=1 | 16 | 10 | None |
| R=2 | 128 | 50 | With loss |
| R=3 | 512 | 99 | Perfect |
| R=3 + Deep Blue Tree module | 2048 | 99 | Perfect |
| R=3 + Izumikun module | 32768 | 999 | Perfect |

- **14 modules** unlock support for specific machine types. Key modules:
  - Atomic Manipulator: Chemical Reactor, Mixer, Duplicator
  - Facility 3826: Assembler, Workbench, Precision Assembler
  - AMD Wafer Fab: 9-machine MultiMachine, PCB Factory, Circuit Assembly Line
  - Temperature Tower: Blast Furnace, Vacuum Freezer, Nano Forge, DTPF
  - Foxconn Factory: Assembly Line, Component Assembly Line, EIC
  - Focus Generator: Laser Hatches + wireless network, 1/10000x time reduction
- **Recipe tier:** Assembly Line, LuV materials (IV Field Generators, Data Orbs, Titanium casings, AE2 components, UUM)
- **Dependencies:** AE2-GTNH, GT++, TecTech (all in pack)
- **No quests** — NEI-discoverable, has built-in GUI wiki

---

## AE2Things — AE2 Storage & QoL Additions
- **Repo:** https://github.com/asdflj/AE2Things
- Adds DISK cells (no type limit — eliminates 63-type cap on ME drives), Infinity Cell (link mode to share item pool across cells/networks), backpack/wireless/dual-interface terminals, Thaumcraft infusion/thaumatorium interfaces, crafting completion notifications, fluid packet encoder
- **Dependencies:** AE2-GTNH only (already in pack)

---

## SharedProspecting `v2.0.4` — Team Prospecting Data Sync
- **Repo:** https://github.com/Lyfts/SharedProspecting
- Automatically syncs VisualProspecting ore data between ServerUtilities team members — no configuration needed, just install on client and server
- **Dependency:** GTNHLib v0.5.14+

---

## Programmable Hatches Mod — Multiblock Automation QoL *(install at MV/HV+)*
- **Repo:** https://github.com/reobf/Programmable-Hatches-Mod
- Programmable input hatches that handle circuit management automatically — eliminates manual circuit swapping on multiblocks. Also adds large buffer hatches and AE2 integration overlays
- No extra dependencies — all requirements are base GTNH pack mods
- Latest: `v0.1.3p55-beta` (targets 2.8.x)

---

## NH-Utilities — QoL Utilities
- **Repo:** https://github.com/Keriils/NH-Utilities
- Lunchbox Plus (54-slot), NEI voltage/recipe owner display, dolly debuff removal, chest cover stack limit removal, wireless hatch improvements, Time Vial machine acceleration
- **Quests:** Adds 2 quests to the BetterQuesting quest book on world load — one for a hammer, one for a lumber axe
- No extra dependencies beyond base GTNH pack
- Latest: `1.6.4`
- **Config:** `config/NHUtilities/NHUtilities.cfg`

| Setting | Value | Default | Note |
|---|---|---|---|
| `enableTimeVial` | `true` | `true` | Default — cannot disable: crashes on load (NHU 1.6.4 bug, recipe init doesn't check flag) |
| `enableTimeAcceleratorBoost` | `false` | `false` | Keeps max acceleration at 128x (not 256x) |
| `accelerateGregTechMachineDiscount` | `0.25` | `0.8` | GT machines only get 25% of acceleration effect |
| `enableNumberMultiplierTexture` | `true` | `false` | Shows multiplier number on vial texture |
| `enableSimpleTimeVialRecipe` | `false` | `false` | Eternity Vial alternate recipe disabled |
| `limitOneTimeVial` | `true` | `true` | Prevents stacking multiple vials on one machine |
| `enableGluttonyRingAndHungerRing` | `true` | `true` | Default |
| `enableAlwaysDisplayRecipeOwner` | `true` | `true` | Shows which mod added each recipe in NEI — useful with multiple addon mods installed |

---

## Twist Space Technology Mod
- **Repo:** https://github.com/Nxer/Twist-Space-Technology-Mod
- Unofficial community expansion focused on GTNH late-game content
- Latest: 0.7.15 (2025-03-19)
- **Install:** Drop jar into `.minecraft/mods/` — do not discuss in official GTNH forums
- **On update:** Reset `GregTech.lang` and `TwistSpaceTechnology.cfg` to avoid config conflicts

---

## 123Technology Mod — Late-Game Content Expansion
- **Jar:** `OTHTechnology.jar` (v1.0)
- Late-game tech tree expansion mod, installed alongside Twist Space Technology
- No configuration required

---

## BetterSprinting `v1.1.3` — Sprint Toggle & Speed Boost
- **Jar:** `BetterSprinting MC-1.7.10 v1.1.3.jar`
- Adds sprinting speed boost toggle and double-tap controls
- Allows sprinting while held, with configurable speed multiplier
- Server-side mod for consistent sprinting mechanics across clients

---

## deconfigintegration `v1.0.2` — Config GUI Integration
- **Jar:** `deconfigintegration-1.0.2.jar`
- Provides in-game configuration GUI for mods with custom configs
- Utility mod for server-side mod management and real-time config adjustments
- No additional dependencies required

---

## FPS Reducer `mc1.7.10-1.10.3` — Idle FPS Limiter
- **Jar:** `fpsreducer-mc1.7.10-1.10.3.jar`
- Reduces FPS when the game window is unfocused or the player is idle — lowers GPU/CPU usage while AFK or alt-tabbed
- Client-side mod — no server install needed
- Configurable idle timeout and minimum FPS targets

---

## Sound-Physics `v1.1.1` — Realistic Sound Propagation
- **Jar:** `sound-physics-1.1.1.jar`
- Adds realistic sound reverb, echo, and occlusion — sounds change based on environment (caves, buildings, outdoors)
- Client-side mod — no server install needed
- Works alongside Dynamic Surroundings for full ambient audio overhaul

---

## Dynamic Surroundings `v1.0.7.7` — Ambient Audio & Visual Effects
- **Jar:** `dynamicsurroundings-1.0.7.7.jar`
- Adds biome ambient sounds, weather effects, footstep sounds, aurora borealis, fireflies, waterfalls, and more
- Client-side mod — no server install needed
- **Config:** `config/dsurround/` — individual toggles for every effect category

---

## Trash Slot `v1.0.31` — Void Inventory Slot
- **Jar:** `trashslot-mc1.7.10-1.0.31.jar`
- Adds a trash/void slot to the inventory — items placed there are deleted
- Server-side mod for consistent inventory behavior
- Useful for automation networks to void excess items without storage clogging
