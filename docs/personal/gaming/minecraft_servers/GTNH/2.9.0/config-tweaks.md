# GTNH 2.9.0 Config Tweaks (QoL / Difficulty)

Paths are relative to `.minecraft`. Defaults below were read from the 2.9.0 instance on
2026-11-01, not carried over from the 2.8.4 notes. Files for hand-added mods do not
exist until those mods are installed.

## HUD

### InGameInfoXML: `config/InGameInfoXML/InGameInfo.xml`

2.9.0 ships InGameInfoXML 2.9.8 with its own default `InGameInfo.xml`, so the custom
layout has to be copied over it again. The layout and what it removes and adds are
described in [the 2.8.4 note](../2.8.4/config-tweaks.md#hud). Copy the file from the
2.8.4 instance, then check that the Thaumcraft and Blood Magic sections still resolve
against 2.9.

## GregTech

### Pollution: `config/GregTech/Pollution.cfg`

- `B:"Activate Pollution"=false` (2.9 default: `true`)

### World Generation: `config/GregTech/WorldGeneration.cfg`

Both defaults are `true`, set to `false`:

- `B:generateUndergroundDirtGen=false`
- `B:generateUndergroundGravelGen=false`

### Machine Explosions: `config/GregTech/GregTech.cfg`

All seven default to `true`, set to `false`:

- `B:machineExplosions`
- `B:machineFireExplosions`
- `B:machineFlammable`
- `B:machineNonWrenchExplosions`
- `B:machineRainExplosions`
- `B:machineThunderExplosions`
- `B:machineWireFire`

### Client: `config/GregTech/Client.cfg`

- `B:wailaAverageNS=true` (default: `false`). GT's own config wins over NH-Utilities'
  mixin, so it has to be set here.

## Mobs & Difficulty

### Special Mobs: `config/SpecialMobs.cfg`

Same keys and defaults as 2.8.4. Each appears once per mob section; the section headings
are the ones named in [the 2.8.4 list](../2.8.4/config-tweaks.md#mobs--difficulty).

Disabled variants, each default `1` set to `0`:

- creeper: `dirt`, `gravel`, `gravity`, `fire`, `lightning`
- skeleton: `fire`
- spider: `poison`
- zombie: `fire`, `plague`
- pigzombie: `plague`

Also `B:enderman_griefing=false` (default: `true`).

### Infernal Mobs: `config/InfernalMobs.cfg`

All default to `true`, set to `false`: `MM_Gravity`, `MM_Storm`, `MM_Wither`,
`MM_Blastoff`, `MM_Ghastly`, `MM_Webber`, `MM_Choke`, `MM_Vengeance`, `MM_Darkness`,
`MM_Exhaust`, `MM_Fiery`, `MM_Poisonous`, `MM_Quicksand`.

Modifier counts, defaults in brackets:

- `I:maxInfernoModifiers=8` [15]
- `I:minInfernoModifiers=5` [8]
- `I:maxUltraModifiers=6` [10]
- `I:minUltraModifiers=3` [5]

### Anger Mod: `config/angermod.cfg`

The file moved out of `config/GTNewHorizons/` and the flat keys are gone. 2.9 uses
sections:

- `kamikaze` → `B:enabled=false`, or keep it on with `I:chance=0` [10]. The section also
  has `B:doTerrainDamage=false` by default.
- `friendly-animal-revenge` → `B:enabled=false` [true]

## Thaumcraft

### Thaumcraft: `config/Thaumcraft.cfg`

- `B:wuss_mode=true` (default: `false`). Warp still accumulates; its side effects stop.

## Food & Survival

### Hunger Overhaul: `config/HungerOverhaul/HungerOverhaul.cfg`

- `S:hungerLossRatePercentage=25` (2.9 default: `100`, not the `133.33` in the 2.8.4 note)
- `S:foodHungerDivider=2.0` is already the default, nothing to change
- `B:useHOFoodValues=false` [true]
- Low-stat debuffs, all `true` by default, set to `false`: `B:addLowHealthNausea`,
  `B:addLowHealthSlowness`, `B:addLowHungerNausea`, `B:addLowHungerSlowness`

2.9 adds options that 2.8.4 did not have, all default `true`: `B:addLowHealthWeakness`,
  `B:addLowHungerWeakness`, `B:addLowHealthMiningSlowdown`,
  `B:addLowHungerMiningSlowdown`, plus `B:modifyRegenRateOnLowHealth`. Decide these
  before the first fight; they were never part of the old setup.

### Spice of Life: `config/SpiceOfLife.cfg`

- `B:food.modifier.enabled=true` is already the default, nothing to change

## Gameplay QoL

- **LootGames**: `config/lootgames/games/game_of_light.cfg` → `I:weight=0` [1]
- **StructureLib**: `config/structurelib.cfg` → `I:autoPlaceBudget=200` [25],
  `I:autoPlaceInterval=50` [300]
- **EnderStorage**: `config/EnderStorage.cfg` → `item.storage-size=2` [1]
- **Iguana Tinker Tweaks**: `config/IguanaTinkerTweaks/main.cfg` → `B:easyToolRepair=true` [false]
- **AE2**: `config/AppliedEnergistics2/AppliedEnergistics2.cfg` →
  `I:craftAmtButton2=64` [10], `I:craftAmtButton3=256` [100], `I:craftAmtButton4=1024` [1000]
- **Find-It**: `config/findit.cfg` → `S:SearchRadius=48` [16]
- **Bogosorter**: `config/bogosorter.cfg` → `I:dropoffRadius=24` [4]
- **Adventure Backpacks**: `config/adventurebackpack.cfg` → in the `status` section,
  `B:"Enable Overlay"=false` [true]. Leave the `tanks` section alone; that is the worn
  backpack overlay, not the potion HUD.

## Bees

### Gendustry: `config/gendustry/overrides/tuning.cfg`

Keys and defaults are unchanged from 2.8.4. Halve each value:

| Machine | Key | Set | Default |
| --- | --- | --- | --- |
| Mutatron | `DegradeChanceNatural` | 15 | 30 |
| Mutatron | `DeathChanceArtificial` | 40 | 80 |
| MutatronAdv | `DegradeChanceNatural` | 5 | 10 |
| MutatronAdv | `DeathChanceArtificial` | 25 | 50 |
| Imprinter | `DeathChanceNatural` | 10 | 20 |
| Imprinter | `DeathChanceArtificial` | 20 | 40 |

## Server Utilities

The config lives at `.minecraft/serverutilities/serverutilities.cfg`, not under
`config/`. The client keeps its own copy for singleplayer and LAN worlds, and the server
build needs the same edits; `server/ranks.txt` is server-side only. Values are in
[server.md](./server.md#serverutilities).

## Added Mod Configs

These three files appear once the mod is installed. Start from the 2.8.4 values, then
check the new version's file for added keys.

- **GTNL**: `config/GTNotLeisure/GTNotLeisure.cfg` → `B:enableStickItem=false` [true]
- **GTNHRates**: `config/gtnhrates.cfg` → the table in
  [2.8.4 mods.md](../2.8.4/mods.md#gtnhrates--rates--qol-overhaul-replaces-gtnh-cutcorners). Keep
  `enableNEIBookmarksContents=false` [true]: the bookmark NPE was never confirmed fixed.
- **EZNuclear**: `config/EZNuclear.cfg` → `B:DEExplosion=false`, `B:IC2Explosion=false` [true]
- **NH-Utilities**: `config/NHUtilities/NHUtilities.cfg` → the table in
  [2.8.4 mods.md](../2.8.4/mods.md#nh-utilities--qol-utilities).
