# GTNH 2.9.0 Config Tweaks (QoL / Difficulty)

Paths are relative to `.minecraft`. Defaults below were read from the 2.9.0 instance on
2026-11-01. Files for hand-added mods do not exist until those mods are installed.

The list is complete for what was actually edited: hashing the 2.8.4 instance's
`config/` against the pack's own 2.8.4 tree found 69 differing files out of 8,497, and
the rest were mod-version noise. Apply them in small groups and launch between groups.

## HUD

### InGameInfoXML: `config/InGameInfoXML/InGameInfo.xml`

2.9.0 ships InGameInfoXML 2.9.8 with its own default `InGameInfo.xml`, and the custom
layout replaces it. This instance holds the only copy now that the 2.8.4 instance is
gone; check that its Thaumcraft and Blood Magic sections still resolve against 2.9.

- **Removed:** dimension and chunks line, temperature, light levels, entity count, chunk
  coordinates, storm countdown, FPS, facing direction, X/Y/Z
- **Top left:** username with ping icon; year, day and time; biome and humidity; moon
  phase as a fraction; biome-aware weather; chunk center, slime chunk and GT ore chunk
  indicators; Thaumcraft warp (total plus perm, sticky and temp) and Blood Magic LP, both
  color coded; up to 3 nearby players with distance
- **Middle left:** equipped item and armor durability, color coded by condition
- **Bottom right:** active potion effects with timers, up to 9 slots

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

Same keys and defaults as 2.8.4. Each appears once per mob section, so edit the one in
the named section.

Variant weights are all the pack default. Every special variant was set to `0` from
2026-11-01 to 2026-11-10 and restored together; the file now matches the default except
one switch.

`B:enderman_griefing=false` [true]: endermen never pick up or place blocks. The mod reads
this switch, so it applies even if `mobGriefing` is on.

With `mobGriefing` off none of the restored variants leaves blocks behind:

- `creeper_rates` `fire` passes the gamerule as the explosion's block-damage flag and
  `dirt` and `gravel` call their block-scattering helpers only when it is on.
- `creeper_rates` `lightning` spawns a 3x3 grid of lightning bolts and ignores the
  gamerule. `doFireTick` stops the fires; the damage and the charged creepers do not.
- `creeper_rates` `gravity` pulls entities in and explodes at power 5 instead of 3.
- `zombie_rates` and `pigzombie_rates` `plague` add 1.3x speed and one random debuff per
  hit, from slowness, nausea, blindness, hunger, weakness and poison.

### Infernal Mobs: `config/InfernalMobs.cfg`

Modifier counts, health factor, rarities and the `mm_*` values are the pack defaults.

Kept off, each default `true`:

- `MM_Blastoff`, `MM_Gravity`, `MM_Choke`, `MM_Darkness`: fling you into the air, drag
  you around, drain your air through armor or blind you
- `MM_Exhaust`: adds hunger exhaustion, working against the Hunger Overhaul change above
- `MM_Poisonous`, `MM_Vengeance`: vengeance reflects half your damage with no cap

Back on (turned off 2026-11-01, restored 2026-11-10): `MM_Storm`, `MM_Ghastly`,
`MM_Webber`, `MM_Fiery`, `MM_Quicksand`, `MM_Wither`. None of them can break a block
under the world's gamerules:

- `MM_Webber` returns before placing a cobweb unless `mobGriefing` is on, so it does
  nothing with mob griefing off.
- `MM_Ghastly`'s fireball passes `mobGriefing` as the explosion's block-damage flag, so
  it leaves no crater. It still hits for ghast fireball damage and knocks you about.
- `MM_Storm` places no fire with `doFireTick` off, and lightning damage and the 8 s of
  burning are unaffected by it. It can also charge creepers, whose explosion does no
  block damage either. With `doFireTick` on it sets fires that spread across wood and
  grass, but fire destroys no blocks, only dropped items.

The laptop's server copy of this file must match the client's, since the server decides
which modifiers a mob gets.

### Anger Mod: `config/angermod.cfg`

The file moved out of `config/GTNewHorizons/` and the flat keys are gone. 2.9 uses
sections:

- `kamikaze` → `B:enabled=false`, or keep it on with `I:chance=0` [10]. The section also
  has `B:doTerrainDamage=false` by default.
- `friendly-animal-revenge` → `B:enabled=false` [true]

## Thaumcraft

### Thaumcraft: `config/Thaumcraft.cfg`

- `B:wuss_mode=true` (default: `false`). Warp still accumulates; its side effects stop.
- `I:biome_taint_spread=0` [200]: no taint when a block updates. Existing tainted land
  stays, and the wiki warns the option may not stop every spread path.

## Food & Survival

### Hunger Overhaul: `config/HungerOverhaul/HungerOverhaul.cfg`

- `S:hungerLossRatePercentage=25` (2.9 default: `100`)
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
- **BetterQuesting**: `config/betterquesting.cfg` → `S:Theme=betterquesting:shadow_ui_2`
  [light], `B:"View mode"=true` [false]. `B:"Lock tray"=true` is already 2.9's default.
- **Default Server List**: `config/defaultserverlist.cfg` → `B:useURL=false` [true].
- **InGameInfoXML**: `config/InGameInfoXML.cfg` → `S:topleft=2 22` [2 50], which moves
  the custom HUD up to match the layout.

The rest of the hash differences were mod-version noise: new keys added by updates
during 2.8.4's life, configs rewritten by the game, and BetterQuesting's own quest-line
files.

## Added Mod Configs

These files appear once the mod is installed. Check a new version's file for added keys.

- **GTNHRates**: `config/gtnhrates.cfg` → the multipliers are in
  [Balance edits](#balance-edits-2026-11-03). Keep `enableNEIBookmarksContents=false`
  [true]: the bookmark NPE was never confirmed fixed. `ic2CropsYield` now multiplies
  CropsNH drops.
- **EZNuclear**: `config/EZNuclear.cfg` → `B:DEExplosion=false`, `B:IC2Explosion=false` [true]
- **BetterSprinting**: `config/BetterSprinting.cfg` → sprinting in all directions needs
  `B:enableAllDirs=true` in both copies, the client's `client` section [true] and the
  server's `server` section [false]; a server left at `false` overrides the client.
- **Effortless Building Gadgets**: `config/effortless.cfg` → `B:consumesEnergy=false`
  [true] on both sides. The config isn't synced, so a side left at `true` still checks power.
- **NH-Utilities**: `config/NHUtilities/NHUtilities.cfg` →
  `accelerateGregTechMachineDiscount=0.25` [0.8], so GT machines get 25% of the
  acceleration effect, and `enableNumberMultiplierTexture=true` [false]. Left at their
  defaults: `enableTimeAcceleratorBoost=false` (keeps the maximum at 128x),
  `enableSimpleTimeVialRecipe=false`, `limitOneTimeVial=true`,
  `enableAlwaysDisplayRecipeOwner=true`. `enableTimeVial` stays `true`: turning it off
  crashed on load in 1.6.4, and that hasn't been retested on 1.7.0.
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
| GTNHRates | `gtnhrates.cfg` | Every multiplier halved from the mod defaults: ores 2.0, coal 8.0, energy 2.0, tools 4.0, bees, crops, pump, resin and IC2 crops 2.0, sapling chance 1.0. `gtSimpleMinersEnergyDiscount` stays 1.0. |
| EZMiner | `EZMiner/EZMiner_Server.cfg` | Server limits: chain 64 blocks at radius 8, block swap 64 at radius 8 (the same 64-block `max_blocks` as FTB Ultimine), tree felling 8 blocks and 256 blocks, preview 64 blocks. `addExhaustion=0.0` removes the hunger cost. Client preferences live in `config/EZMiner/EZMiner.cfg`. |
| GTMB | `gtmb-stargate-rules.cfg` | `enabled=true`: blueprint demolition cannot mine ores, cut/paste cannot move or overwrite ores, and decoration vouchers are off. |
| GTSWN | `gtswn/gtswn_network.cfg` | `UplinkLossEU=0.1`, so wireless power uploads lose 10 percent against the 15 percent downlink. |
| GTSWN | `gtswn/gtswn.cfg` | `deviceTeleportXPCost=0`, so device info terminal teleports are free like the Waystones. |
| GTSR | `gtsr/gtsr.cfg` | `singularityDestroyBlocks=true` is back at the default. It was off while singularities were common; at 168x168 chunks they are rare enough to leave their block eating alone. Client only so far, like the frequency below. |
| GTSR | `gtsr/gtsr.cfg` | `singularitySpawnFrequency=168` [48], so a Spacetime Singularity Altar averages one per 168x168 chunks instead of 48x48, about 3.5 times rarer. New chunks only; `shatteredSingularityMultiplier` still makes the Shattered dimension 8 times denser than that. Client only so far: the laptop's server copy needs the same value before a world is generated. |

Left alone on purpose: Twist's Blood Hatch infinite drain, Waystones' free
teleports, and 123Technology's Alien Fishery (a late-game goal).
