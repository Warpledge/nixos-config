# GTNH 2.9.0 Config Tweaks (QoL / Difficulty)

Paths are relative to `.minecraft`. Defaults below were read from the 2.9.0 instance on
2026-11-01, not carried over from the 2.8.4 notes. Files for hand-added mods do not
exist until those mods are installed.

The list is complete for what was actually edited: hashing the 2.8.4 instance's
`config/` against the pack's own 2.8.4 tree found 69 differing files out of 8,497, and
the rest were mod-version noise. Apply them in small groups and launch between groups;
do not copy the whole 2.8.4 `config/` folder.

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

## Undocumented edits found in the 2.8.4 instance

These were applied by hand in 2.8.4 but never written down. Found by diffing the
instance's `config/` against the pack's own 2.8.4 tree; every key below still exists in
2.9.0 with the old default.

- **Waila**: `config/Waila.cfg` → `I:waila.cfg.alpha=0` [80], `B:waila.cfg.liquid=false`
  [true], `I:waila.cfg.scale=79` [100], `I:waila.cfg.posx=4999` [10000],
  `I:waila.cfg.posy=0` [10000]. Transparent background, smaller and moved from the top
  right.
- **Botania**: `config/Botania.cfg` → `D:flowerParticles.frequency=0.0` [0.75],
  `D:worldgen.flower.tallChance=0.0` [0.05]. Particle and worldgen cost off. The
  `B:shaders.enabled=false` from 2.8.4 was a workaround for the old renderer and is left
  at its default on 2.9; turn it off only if Botania's effects misbehave under Celeritas.
- **Forestry**: `config/forestry/common.cfg` → `B:disable.butterfly=true` [false].
- **BetterQuesting**: `config/betterquesting.cfg` → `S:Theme=betterquesting:shadow_ui_1`
  [light], `B:"View mode"=true` [false]. `B:"Lock tray"=true` is already 2.9's default.
- **Default Server List**: `config/defaultserverlist.cfg` → `B:useURL=false` [true].
- **InGameInfoXML**: `config/InGameInfoXML.cfg` → `S:topleft=2 22` [2 50], which moves
  the custom HUD up to match the layout.

The rest of the hash differences were mod-version noise: new keys added by updates
during 2.8.4's life, configs rewritten by the game, and BetterQuesting's own quest-line
files.

## Added Mod Configs

These files appear once the mod is installed. Start from the 2.8.4 values, then
check the new version's file for added keys.

- **GTNL**: 0.2.7 splits its config through GTNHLib into
  `config/GTNotLeisure/{general,item,machine,recipe,re_avaritia,client}.cfg`, so the old
  single `GTNotLeisure.cfg` is not there. The stick setting is `enableStickItem=false`
  [true] in `item.cfg`. The Integrated Ore Factory option from 0.2.4 no longer exists.
- **GTNHRates**: `config/gtnhrates.cfg` → the table in
  [2.8.4 mods.md](../2.8.4/mods.md#gtnhrates--rates--qol-overhaul-replaces-gtnh-cutcorners). Keep
  `enableNEIBookmarksContents=false` [true]: the bookmark NPE was never confirmed fixed.
  `ic2CropsYield` now multiplies CropsNH drops; keep it at `4.0`.
- **EZNuclear**: `config/EZNuclear.cfg` → `B:DEExplosion=false`, `B:IC2Explosion=false` [true]
- **NH-Utilities**: `config/NHUtilities/NHUtilities.cfg` → the table in
  [2.8.4 mods.md](../2.8.4/mods.md#nh-utilities--qol-utilities).
- **YesSteveModel Unofficial**: `config/ysmu.cfg`, left at the values the mod writes on
  first launch. It also creates `config/ysmu/`: `custom/` for added models, `builtin/`
  for the ones unpacked from the jar (`default`, `misc`, `wine_fox`), plus `auth/`,
  `cache/` and `export/`. Both sides need the folder: the server keeps its models in
  `custom/` and syncs them to each player who joins (`/ysm sync` resyncs, `/ysm reload`
  rebuilds the cache, OP only), and a client model can be uploaded up to
  `MaxModelUploadMb=64`. `debug { * }` stays off for normal play.

  A model dropped into `custom/` is picked up by `/ysmclient load` without a restart;
  that is the command behind the log line `Local model load complete: registered=24,
  skipped=0, failed=0` (first launch, 2026-11-02). Five warnings name `lance` animations
  of the builtin `default` model as unreachable on 1.7.10; that content ships in the jar
  and is harmless.

  The model GUI is **Alt+Y**: `PlayerModelScreenKey` checks `KEY_LMENU` (56) or
  `KEY_RMENU` (184) itself, and Controls only lists the Y part, so Y alone does nothing.
  `general { DisclaimerShow=true }` puts a disclaimer screen in front of the GUI the
  first time. Alt+P opens the extra player render config, Z the animation roulette and L
  its lock; those three have no modifier. In that config screen, drag the green square to
  move the HUD preview, the blue square to scale it, right-drag to rotate, Alt+R to reset;
  the values land in `extra_player_render` in `ysmu.cfg`.

  Models come from
  [Elaina69/Yes-Steve-Model-Repo](https://github.com/Elaina69/Yes-Steve-Model-Repo)
  (state 2026-08-18: 906 `.ysm` files and 208 zips of the older folder format). The
  scanner walks `custom/` recursively, so the repo's franchise folders stay and each zip
  is unpacked to `<Franchise>/<zip name>/`. The full set is too much for the client:
  969 models need more than 12G at world load (it froze at 670/900 with 12G and went
  through with 18G). 117 of the `.ysm` are unreadable on 1.9 (`Failed to load OpenYSM
  binary model`), 23 were byte-identical copies, and 5 collided with a zip folder of the
  same name, where the `.ysm` wins.

  The kept set is 86 models (70 `.ysm`, 16 folder models), the ones starred in the model
  GUI; the server's `custom/` mirrors it. Stars are stored in the player's NBT as
  `ysmu_StarModels`, a hex-encoded path under `config/ysmu/custom`, not in a config file.
  `/ysm reload` on the kept set takes seconds and 320-390 s on the full one, blocking the
  server while it runs. The index keeps only the entries a run re-recorded, so a start
  following a cached one rescans; at this size that is a few seconds.

## Balance edits (2026-11-03)

Applied to the client and server copies.

| Mod | File | Change |
| --- | --- | --- |
| 123Technology | `123Technology.cfg` | Overpowered integrated-factory recipes off, output multiplier 1.5 to 1.0, NHU egg-machine compat off. The file repeats each category under a pinyin and a Chinese name; both copies were changed. |
| GTIT | `gtit/gifts.json` | Starter gift `randomRewards` emptied and `randomCount` set to 0, so no rings at first login. The legacy `gift_config.json` was cleared too. Already-claimed gifts keep their snapshot. |
| GTNL | `GTNotLeisure/` | Vein Mining Pickaxe `maxAmount=1` and `maxRange=1`, so it no longer chains; `enableSomethingRecipe=false`; `enableVoidMinerTweak=false`; `enableSaturationHeal=false`. `enableRecipeOutputChance` stays on. |
| GTNHRates | `gtnhrates.cfg` | Every multiplier halved from the mod defaults: ores 2.0, coal 8.0, energy 2.0, tools 4.0, bees, crops, pump, resin and IC2 crops 2.0, sapling chance 1.0. `gtSimpleMinersEnergyDiscount` stays 1.0. |
| EZMiner | `EZMiner/EZMiner.cfg` | Chain limit 64 blocks at radius 8, block swap limit 64 at radius 8, the same 64-block `max_blocks` as FTB Ultimine (its `FTBUltimineServerConfig.java`). Tree felling stays at radius 64 and 16384 blocks for the tall GT++ trees. |
| GTSWN | `gtswn/gtswn_network.cfg` | `UplinkLossEU=0.1`, so wireless power uploads lose 10 percent against the 15 percent downlink. |
| GTSR | `gtsr/gtsr.cfg` | `singularityDestroyBlocks=false`, so worldgen singularities cannot eat builds. |

Left alone on purpose: Twist's Blood Hatch infinite drain, Waystones' free
teleports, 123Technology's Alien Fishery (a late-game goal), and the GTIT AE
trade presets (not selected).
