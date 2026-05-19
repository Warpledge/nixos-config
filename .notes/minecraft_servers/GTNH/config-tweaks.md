# Config Tweaks (QoL / Difficulty)

## HUD

### InGameInfoXML — `config/InGameInfoXML/InGameInfo.xml`
Custom HUD layout replacing the GTNH default. Changes from original:

**Removed:** Dimension/chunks line, temperature (°F/°C/K), light levels, entity count, chunk coordinates, storm countdown timer, FPS display, facing direction, X/Y/Z coordinates

**Top Left:**
- Username (ping icon)
- Year/Day/Time (no "Minecraft" prefix)
- Biome + humidity (no temperature)
- Moon phase (fraction format 1/4–4/4)
- Weather — rain/snow/thunder, biome-aware, no countdown
- Chunk center indicator, slime chunk indicator, GT ore chunk indicator
- Magic section: Thaumcraft warp (total + perm/sticky/temp, color coded), Blood Magic LP (value + color-coded %)
- Nearby players list (up to 3 with distance)

**Middle Left:** Equipped item + armor durability (helmet/chest/legs/boots), color coded by condition

**Bottom Right:** Active potion effects with duration timers (up to 9 slots)

---

## GregTech

### Pollution — `config/GregTech/Pollution.cfg`
- `B:"Activate Pollution"=false` — Disables pollution entirely (default: `true`)

### GregTech World Generation — `config/GregTech/WorldGeneration.cfg`
All set to `false` (default: `true`):
- `B:generateUndergroundDirtGen=false` — Disables underground dirt vein generation
- `B:generateUndergroundGravelGen=false` — Disables underground gravel vein generation

### GregTech Machine Explosions — `config/GregTech/GregTech.cfg`
All set to `false` (default: `true`):
- `B:machineExplosions=false` — Master toggle for all machine explosions (overvoltage, etc.)
- `B:machineFireExplosions=false` — No explosion from adjacent fire
- `B:machineFlammable=false` — Machines can't catch fire
- `B:machineNonWrenchExplosions=false` — No explosion for unwrenching without a wrench
- `B:machineRainExplosions=false` — No explosion from rain exposure
- `B:machineThunderExplosions=false` — No explosion from thunderstorms
- `B:machineWireFire=false` — No wire burnout cascade on explosion

### GregTech Client — `config/GregTech/Client.cfg`
- `B:wailaAverageNS=true` — Shows average tick time (ns) per machine in WAILA tooltip (default: `false`). Note: NHUtilities mixin attempts to force this on but GT's config file overrides it — must be set here directly.

---

## Mobs & Difficulty

### Special Mobs — `config/SpecialMobs.cfg`
Disabled environment-griefing mob variants and enderman block manipulation:
- `I:dirt=0` — Dirt creeper disabled (explosion replaces terrain with dirt)
- `I:gravel=0` — Gravel creeper disabled (explosion replaces terrain with gravel)
- `I:gravity=0` — Gravity creeper disabled (pulls blocks/players)
- `I:fire=0` (creeper) — Fire creeper disabled (explosion leaves fire in the world)
- `I:lightning=0` (creeper) — Lightning creeper disabled (lightning strikes ignite blocks)
- `I:fire=0` (skeleton) — Fire skeleton disabled (shoots flaming arrows, sets player on fire)
- `I:poison=0` (spider) — Poison spider disabled (applies poison to player)
- `I:fire=0` (zombie) — Fire zombie disabled (burns player on contact)
- `I:plague=0` (zombie) — Plague zombie disabled (poison-like plague effect)
- `I:plague=0` (pigzombie) — Plague pigzombie disabled (poison-like plague effect)
- `B:enderman_griefing=false` — Endermen no longer pick up or place blocks

### Infernal Mobs — `config/InfernalMobs.cfg`
Disabled disruptive/annoying mob traits (default: `true` → changed to `false`):
- `B:"MM_Gravity enabled"=false` — Pulls player toward mobs
- `B:"MM_Storm enabled"=false` — Lightning strikes on hit
- `B:"MM_Wither enabled"=false` — Applies wither effect
- `B:"MM_Blastoff enabled"=false` — Launches player into the air
- `B:"MM_Ghastly enabled"=false` — Fires ghast fireballs, craters terrain and starts fires
- `B:"MM_Webber enabled"=false` — Places web blocks in the world around the player
- `B:"MM_Choke enabled"=false` — Reduces player max health, stacks badly with other modifiers
- `B:"MM_Vengeance enabled"=false` — Reflects damage back to the attacker (thorns-like)
- `B:"MM_Darkness enabled"=false` — Blindness with no counterplay
- `B:"MM_Exhaust enabled"=false` — Redundant hunger drain (Sapper also disabled)
- `B:"MM_Fiery enabled"=false` — Sets player on fire
- `B:"MM_Poisonous enabled"=false` — Poison effect
- `B:"MM_Quicksand enabled"=false` — Severe movement slow, unfair combo with Sprint mobs

Modifier count limits reduced (infernal mobs were stacking too many simultaneously):
- `I:maxInfernoModifiers=8` — was 15
- `I:minInfernoModifiers=5` — was 8
- `I:maxUltraModifiers=6` — was 10
- `I:minUltraModifiers=3` — was 5

### Anger Mod — `config/GTNewHorizons/angermod.cfg`
- `I:KamikazeChance=0` — Removes chance for mobs to explode on death (default: `10`). Note: valid range is 1–100 so set to `1` if `0` causes issues.
- `B:FriendlyMobRevenge=false` — Animals no longer attack you for eating their meat (default: `true`)

---

## Thaumcraft

### Thaumcraft — `config/Thaumcraft.cfg`
- `B:wuss_mode=true` — Disables warp side effects (fire auras, strange visions, flux flu, etc.) while still allowing warp to accumulate normally. Eldritch progression and forbidden research are unaffected.

---

## Food & Survival

### Hunger Overhaul — `config/HungerOverhaul/HungerOverhaul.cfg`
- `S:hungerLossRatePercentage=25` — Hunger drains at 25% of vanilla rate (vanilla: `100`, GTNH default: `133.33`)
- `S:foodHungerDivider=2.0` — Halves all food hunger values (steak 8→4, bread 5→2.5). GTNH default.
- `B:useHOFoodValues=false` — Disables HO manually overriding food values for supported mods (default: `true`)

Disabled low-health/hunger debuffs (under `low stats` section, default: `true` → `false`):
- `B:addLowHealthNausea=false` — No nausea when health is critically low
- `B:addLowHealthSlowness=false` — No slowness when health is low
- `B:addLowHungerNausea=false` — No nausea when hunger is critically low
- `B:addLowHungerSlowness=false` — No slowness when hunger is low

### Spice of Life — `config/SpiceOfLife.cfg`
- `B:food.modifier.enabled=true` — Diminishing returns active (default). Eating the same food repeatedly gives less hunger, incentivizing food variety.

---

## Gameplay QoL

### Server Utilities — `serverutilities/serverutilities.cfg`
Changed from defaults (under `world` section):
- `B:chunk_claiming=true` — enables chunk claiming UI (disabled by default in pack)

Enabled commands (under `commands` section, default `false` → `true`):
- `B:home=true` — `/home`, `/sethome`
- `B:warp=true` — `/warp`, `/setwarp`, `/delwarp` (good for two-player server shared waypoints)
- `B:rtp=true` — `/rtp` random teleport (1000–100000 blocks from spawn)
- `B:spawn=true` — `/spawn` teleport to world spawn
- `B:tpa=true` — `/tpa <player>` teleport request, `/tpaccept` to accept
- `B:back=true` — `/back` teleport to last death or teleport location

Ranks disabled (`B:enabled=false`) — not needed for solo/two-player, defaults to admin permissions.

### Server Utilities Ranks — `serverutilities/server/ranks.txt`
Applied to all three ranks (`player`, `vip`, `admin`). Original values noted for reversion:

| Setting | Changed | player orig | vip orig | admin orig |
|---|---|---|---|---|
| `claims.max_chunks` | `5000` | `100` | `500` | `1000` |
| `chunkloader.max_chunks` | `5000` | `50` | `100` | `1000` |
| `homes.max` | `3` | `1` | `1` | `1` |
| `homes.warmup` | `0s` | `5s` | `0s` | `0s` |
| `homes.cooldown` | `0s` | `5s` | `1s` | `0s` |
| `homes.cross_dim` | `true` | `false` | `false` | `false` |

All teleport commands set to instant with no cooldown for every rank (defaults vary per command):

| Setting | Value |
|---|---|
| `tpa.warmup` / `tpa.cooldown` | `0s` |
| `spawn.warmup` / `spawn.cooldown` | `0s` |
| `warp.warmup` / `warp.cooldown` | `0s` |
| `back.warmup` / `back.cooldown` | `0s` |
| `rtp.warmup` / `rtp.cooldown` | `0s` |

Also: `waystones.cfg` → `xpBaseCost=-1` disables XP cost for waystone teleports.

### LootGames — `config/lootgames/games/game_of_light.cfg`
- `I:weight=0` — Disables Game of Light from spawning (default: `1`). Minesweeper is the only active LootGames game.

### StructureLib — `config/structurelib.cfg`
Hologram auto-place settings (under `common > hologram`):
- `I:autoPlaceBudget=200` — Max blocks placed per auto-place round (default: `25`)
- `I:autoPlaceInterval=50` — Min interval between auto-place rounds in ms (default: `300`)

### EnderStorage — `config/EnderStorage.cfg`
- `item.storage-size=2` — 6x9 inventory size (default: `1` = 3x9)

### Iguana Tinker Tweaks — `config/IguanaTinkerTweaks/main.cfg`
- `B:easyToolRepair=true` — Allows repairing TC tools in any crafting grid without a Tool Station (default: `false`)

### Applied Energistics 2 — `config/AppliedEnergistics2/AppliedEnergistics2.cfg`
Crafting screen quick-amount buttons (under `client` section):
- `I:craftAmtButton1=1` — default
- `I:craftAmtButton2=64` — stack (default: `10`)
- `I:craftAmtButton3=256` — (default: `100`)
- `I:craftAmtButton4=1024` — (default: `1000`)

### Find-It — `config/findit.cfg`
- `S:SearchRadius=48` — Radius (in blocks) searched when using "Search For Item In Nearby Inventories" keybind (default: `16`)

### Bogosorter — `config/bogosorter.cfg`
- `I:dropoffRadius=24` — Radius (in blocks) scanned for drop-off target containers (default: `4`)

### Adventure Backpacks — `config/adventurebackpack.cfg`
- `B:"Enable Overlay"=false` — Disables the status effects overlay (graphics → status section, default: `true`)

---

## Bees

### Gendustry Bee Breeding — `config/gendustry/overrides/tuning.cfg`
Halved all death/degrade RNG from bee machines. Original values noted for reversion:

| Machine | Setting | Changed | Original |
|---|---|---|---|
| Mutatron | `DegradeChanceNatural` | `15` | `30` |
| Mutatron | `DeathChanceArtificial` | `40` | `80` |
| MutatronAdv | `DegradeChanceNatural` | `5` | `10` |
| MutatronAdv | `DeathChanceArtificial` | `25` | `50` |
| Imprinter | `DeathChanceNatural` | `10` | `20` |
| Imprinter | `DeathChanceArtificial` | `20` | `40` |

---

## Added Mod Configs

### GTNotLeisure (GTNL) — `config/GTNotLeisure/GTNotLeisure.cfg`
- `B:enableStickItem=false` — Disables the GTNL "Stick" fake item and its associated villager trades (default: `true`). When enabled, GTNL registers trades for all 5 vanilla villager types that appear to give Avaritia Infinity gear, but the items are non-functional cardboard replicas (GTNL Stick disguise system). Disabled to avoid confusing fake gear appearing in villager UIs — not a real progression exploit.

### GTNHRates — `config/gtnhrates.cfg`
See [mods.md](mods.md#gtnhrates) for full table.

### EZNuclear — `config/EZNuclear.cfg`
- `B:DEExplosion=false` — Draconic Evolution reactor explosions disabled (default: `true`)
- `B:IC2Explosion=false` — IC2 nuclear reactor explosions disabled (default: `true`)

### NH-Utilities — `config/NHUtilities/NHUtilities.cfg`
See [mods.md](mods.md#nh-utilities) for full table.
