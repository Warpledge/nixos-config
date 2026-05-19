# Shaders — TerraFirmaGreg-Modern

---

## Eclipse Shader (Unstable)

**Location:** `~/.local/share/PrismLauncher/instances/TerraFirmaGreg-Modern/minecraft/shaderpacks/Eclipse-Shader-Unstable/`

Load as the **extracted folder**, not the zip — the zip cannot be edited and Iris will use whichever is selected in shader settings.

Reload shaders in-game: `F3+R`

---

### TFC Water Block IDs (block.properties fix)

**File:** `shaders/block.properties`, line `block.8=`

TFC 1.20.1 reorganized all fluid blocks under the `fluid/` sub-namespace. The shader shipped with outdated IDs from an older TFC version, so TFC water received no shader water effects.

**Corrected `block.8` entry:**
```
block.8=minecraft:water minecraft:flowing_water tfc:fluid/river_water tfc:fluid/spring_water tfc:fluid/salt_water tfc:fluid/limewater tfc:fluid/brine tfc:fluid/olive_oil_water
```

Old (wrong) TFC entries that were removed:
- `tfc:river_water`, `tfc:spring_water`, `tfc:salt_water`, `tfc:limewater`
- `tfc:flowing_spring_water`, `tfc:flowing_salt_water`, `tfc:flowing_limewater`

These were valid in TFC for MC 1.18 and earlier. In TFC 1.20.1 (3.x), all fluid blockstates live at `assets/tfc/blockstates/fluid/*.json`, making the block IDs `tfc:fluid/*`.

---

### Settings

Saved in `Eclipse-Shader-Unstable.zip.txt` (Iris persists shader settings here even when using the folder):

| Setting | Value |
|---|---|
| `AURORA_LOCATION` | 2 |
| `BLOOM_STRENGTH` | 0.5 |
| `RAIN_MODE` | 0 |
| `RENDER_ENTITY_SHADOWS` | false |
| `RESOURCEPACK_SKY` | 2 |
| `shadowDistance` | 160.0 |
| `shadowMapResolution` | 2048 |
