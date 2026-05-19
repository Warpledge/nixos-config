# Shaders — Euphoria Patches

Active shader: `ComplementaryReimagined_r5.7.1 + EuphoriaPatches_1.8.6` (extracted folder in `shaderpacks/`)

Euphoria Patches computes emissives automatically via iPBR+ (texture color analysis). For explicit per-block material overrides (reflectivity, metalness, emissive strength), two files need editing:

---

## File 1 — Block ID Registration

**IMPORTANT:** Edit ONLY the root file — the fragment files do NOT take effect until auto-merged:
- **Root (what Angelica reads):** `shaderpacks/ComplementaryReimagined_r5.7.1 + EuphoriaPatches_1.8.6/shaders/block.properties`
- Fragment (do not edit): `shaders/blockProperties/1.7.10/block.properties`

The root file has multiple sections merged from different MC versions. The 1.7.10-specific section is near the end of the file. Always edit the matching entry in that section.

Maps block names to shader material IDs. Format:
```
block.XXXXX = modid:blockname modid:blockname2 \
\
anothermod:blockname
```

### Key Material IDs (from terrainIPBR.glsl)

- `block.10104` — Polished Andesite: moderate reflection `pow2(color.g)` — GT machines, CarpentersBlocks, ForgeMicroblock catch-all
- `block.10264` — Iron block: strong reflection `pow2(pow2(color.r))` + Fresnel — GT casings, chisel metal, Railcraft
- `block.10248` — Netherite block: very high reflection `min1(pow2(color.r * 2.0))` — Ztones laveBlock, iszmBlock
- `block.21XXX` — Modded light sources: `emission = pow2(luminance) * 5.0` (texture-brightness-based, no light level dependency)
  - `block.21000` — White: GT casings5, chisel:hexPlating, greenscreen, ForgeMicroblock:microblock, ForgeMultipart:block
  - `block.21004` — Red: ExtraUtilities color_blockRedstone, BiomesOPlenty hell_blood
  - `block.21008` — Yellow: BiomesOPlenty honey
  - `block.21012` — Green: BiomesOPlenty poison
- `block.31XXX` — Translucents with colored light tinting
- `block.20000` — Disables Parallax Occlusion Mapping — `ArchitectureCraft:shape`

**Bloom setting:** In-game only — Options → Video Settings → Shaders → Camera Settings → `BLOOM_STRENGTH` slider. Not a file setting.

**Emission formula** (terrainIPBR.glsl, block.21XXX range):
```glsl
noSmoothLighting = true; noDirectionalShading = true;
float lum = GetLuminance(color.rgb);
emission = pow2(lum) * 5.0;  // Only bright textures glow; dark blocks unaffected
```

Block names come from WAILA (hover over block in-game), format is `modid:blockname`. Use `modid:blockname:0,1,2` for specific metadata variants.
- ForgeMicroblock shapes (Post, Strip, Cover, etc.) all share `ForgeMicroblock:microblock` — no per-shape override needed
- Ztones laveBlock microblocks: glowing white because laveBlock is bright + ForgeMicroblock in block.21000

**Cross-reference:** ComplimentaryNeon's `block.properties` (inside `ComplementaryNeon.zip`) has GTNH block IDs already mapped with comments — use it as a reference for which blocks to add and what reflection tier they should be.

### Currently Added Blocks

**Reflections:**
- `Ztones:tile.laveBlock:0` through `:15`, `Ztones:tile.bittBlock:0` through `:14` → `block.10260` (custom fixed smoothness: 0.75 regardless of texture color — needed because netherite formula uses color.r which gives near-zero for non-red color variants)
- `Ztones:tile.iszmBlock`, `gregtech:gt.blockmachines:8` (cable covers) → `block.10248` (netherite, very high reflection)
- `Ztones:tile.agonBlock` → `block.10104` (medium reflection)
- `Ztones:tile.korpBlock`, `TwilightForest:tile.CastleBrick` → `block.10432` (terracotta/low reflection)
- `Ztones:tile.glaxx`, `bartworks:BW_GlasBlocks` → `block.32008` (plain glass — all metadata variants, multi-color blocks)
- `gregtech:gt.blockcasings`, `gt.blockcasings3`, `gt.blockcasings5`, `gt.blockreinforced` → `block.10264` (iron block)
- `gregtech:gt.blockmachines`, `gt.blockcasings4`, `tectech:gt.blockcasingsTT` → `block.10264` (iron block; `:8` metadata cable covers override to `block.10248` earlier in file)
- GT fluid pipes → `block.10264` (iron block, Fresnel + luminance): `gregtech:gt.blockmachines:5101-5103` (wood, 3 sizes), `:5110-5319` (21 metal materials × 10 IDs each: 5 single-fluid + 5 multi-fluid), `:5589` (special/long-distance). NEID metadata — vanilla block meta nibble can't hold these; NEID extends it and Angelica reads it.
- `miscutils:miscutils.blockcasings`, `gtplusplus.blockcasings.2/3` → `block.10264`
- `IC2:blockMachine`, `blockMachine2`, `blockMachine3`, `blockElectric`, `blockGenerator` → `block.10264` (IC2 machines, energy storage, generators)
- `EnderIO:blockMachineBase`, `blockConduitBundle`, `blockCapacitorBank` → `block.10264`
- `chisel:hexPlating`, `laboratoryblock`, `factoryblock`, `tyrian`, `technical` → `block.10264`
- `IC2:blockDoorAlloy`, `Railcraft:machine.beta` → `block.10264`
- `catwalks:catwalk_unlit`, `catwalks:support_column` → `block.10264`
- `ForgeMicroblock:microblock`, `ForgeMultipart:block` → `block.10104` (medium reflection)
- `MagicBees:hive`, `Forestry:beehives`, `Forestry:apiary`, `Forestry:bee_chest`, `extrabees:hive`, `magicbees:hive2` → `block.10104` (suppress auto-emissive — bright textures trigger iPBR+ detection without explicit assignment)
  - Note: these blocks have hardcoded `getLightValue()` in source, so they still appear as blown-out white dots in Distant Horizons LOD terrain (DH reads vanilla light values directly, not block.properties). No fix available without mod source changes.

**Emissives:**
- `gregtech:gt.blockcasings5`, `chisel:hexPlating`, `ExtraUtilities:greenscreen` → `block.21000` (white)
- `ForgeMicroblock:microblock`, `ForgeMultipart:block` → `block.21000` (white, texture-brightness gated)
- `gregtech:gt.blockores` → `block.10024` (auto-glow ores)
- `EnderIO:blockPaintedGlowstone` → `block.10412` (glowstone tier)
- `ExtraUtilities:color_blockRedstone`, `BiomesOPlenty:hell_blood` → `block.21004` (red)
- `BiomesOPlenty:honey` → `block.21008` (yellow)
- `BiomesOPlenty:poison` → `block.21012` (green)

---

## File 2 — Material Properties

**Path:** `shaderpacks/ComplementaryReimagined_r5.7.1 + EuphoriaPatches_1.8.6/shaders/lib/materials/materialHandling/terrainIPBR.glsl`

Defines what each material ID does. Uses a binary search tree on `mat` value. Add entries matching the IDs registered in block.properties. Key variables:
- `smoothnessG` / `smoothnessD` — reflection smoothness (0.0–1.0)
- `highlightMult` — specular highlight intensity
- `emission` — emissive strength (0.0–1.0+)
- `materialMask` — material type mask

Example entry pattern (look at existing iron block / netherite entries in the file for reference):
```glsl
if (mat == 1XXXX) {
    smoothnessG = 0.8;
    smoothnessD = 0.8;
    highlightMult = 3.0;
}
```
