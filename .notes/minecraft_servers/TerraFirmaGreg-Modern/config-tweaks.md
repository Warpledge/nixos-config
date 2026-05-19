# Config Tweaks — TerraFirmaGreg-Modern

Config file changes made to the base pack. Organized by file.

---

<!-- Template:
## `config/example.toml`

### Setting Name
- **Changed:** `key = old` → `key = new`
- **Why:** Reason
-->

## `config/zipline.json` *(created — did not exist on server)*

### Durability disabled
- **Changed:** `consumeDurability: false` (explicit — was already the hardcoded default)
- **Why:** Prevent zipline items from degrading with use.
- **Note:** `snapRadius` (auto-attach) = 2.0 blocks, `clickReach` (right-click attach) = 3.0 blocks.

---

## `config/connectiblechains.toml`

### Max chain range
- **Changed:** `maxChainRange = 32` → `128`
- **Why:** Default 32 blocks too short for zipline setups over long distances.

---

## `config/waystones-common.toml`

### Cooldowns
- **Changed:** `warpStoneCooldown = 30` → `10`, `inventoryButtonCooldown = 300` → `10`
- **Why:** Private server, no reason to gate teleportation heavily.

### XP cost disabled
- **Changed:** `maximumBaseXpCost = 3.0` → `0.0`, `dimensionalWarpXpCost = 3` → `0`
- **Why:** `maximumBaseXpCost = 0` disables all distance-based XP costs. Dimensional warp cost also zeroed. All multipliers were already 0.

---

## `defaultconfigs/ftbranks/ranks.snbt` + `Aevum/serverconfig/ftbranks/ranks.snbt`

### Simplified to two ranks
- **Changed:** Removed `member`, `vip`, `moderator` ranks and all `command.*: false` denials from `novice`
- **Why:** Server is private (2 players). The `novice` rank's explicit command denials were blocking op-level players from using commands like `/chunky` even with `command: true` in the admin rank. FTB Ranks wildcard doesn't reliably override explicit node denials from always-active ranks.
- **Result:** `novice` (everyone) has no command restrictions and generous chunk limits. `admin` (ops) gets `command: true` with nothing blocking it.
- **Note:** Both files must be kept in sync — server overwrites `Aevum/serverconfig/` on shutdown, `defaultconfigs/` is the persistent source of truth for new worlds.

## `config/DistantHorizons.toml`

### Noise intensity
- **Changed:** `noiseIntensity = "0.05"` → `"5.0"`
- **Why:** Default reset by DH update; restored prior value for better LOD texture detail.

### Distant generator mode
- **Changed:** `distantGeneratorMode = "FEATURES"` → `"INTERNAL_SERVER"`
- **Why:** Most compatible mode — generates structures correctly via the local server.

### Ignored cave blocks
- **Changed:** `ignoredRenderCaveBlockCsv = ""` → full list: `minecraft:glow_lichen,minecraft:rail,minecraft:water,minecraft:lava,minecraft:bubble_column,minecraft:cave_vines_plant,minecraft:vine,minecraft:cave_vines,minecraft:short_grass,minecraft:tall_grass,minecraft:small_dripleaf,minecraft:big_dripleaf,minecraft:big_dripleaf_stem,minecraft:sculk_vein`
- **Why:** Restored prior list after DH update reset the config. Prevents these blocks from rendering underground in LODs.

### Adaptive transfer speed
- **Changed:** `enableAdaptiveTransferSpeed = false` → `true`
- **Why:** Restored prior value; auto-adjusts transfer rate to minimize connection lag.

### Overdraw prevention
- **Note:** v3 config had `"0.0"` (v3's auto). v4 changed auto to `"-1.0"` — kept at `-1.0` (v4 auto).

---

## `defaultconfigs/ftbessentials-server.snbt`

### Teleport commands enabled with warmup
- **Changed:** Enabled `/home`, `/back`, `/tpa`, `/spawn`, `/warp` (all were `enabled: false`)
- **Warmup:** 3 seconds (must stand still or teleport cancels)
- **Cooldown:** 10 seconds on all commands
- **Max homes:** 3
- **Note:** This is the persistent config — the server copies it to `Aevum/serverconfig/ftbessentials.snbt` on world load. Edit here, not in `serverconfig/`.
