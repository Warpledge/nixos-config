# GTNH 2.9.0 Shaders

Two setups are installed side by side: [Eclipse with ChromaPatch](#eclipse-with-chromapatch)
is the active one, and [NeonTech](#neontech) is the one to switch back to.

## Eclipse with ChromaPatch

KuramA's and OBS07's setup, from KuramA's install post dated 2026-11-05: an edit of the
Eclipse shader with coloured lighting, plus LabPBR packs for GTNH's neon blocks. The edit
can't be redistributed, so the ChromaPatch mod builds it locally from the Eclipse zip.

### Versions

Installed 2026-11-06. It needs GTNH 2.9.0 stable on Java 25 or newer; the instance runs
Java 25.0.4.1 and ships Angelica 2.2.43.

| Part | Version | File |
| --- | --- | --- |
| ChromaPatch | 1.0.2 | `mods/chromapatch-1.0.2-forge1710-1.7.10.jar` |
| Eclipse source | `3c18afc` (2026-09-16) | `shaderpacks/Eclipse-Shader-3c18afc.zip` |
| Patched pack | Eclipse patch 1.0.2 | `shaderpacks/Eclipse-Shader KuraEdit [OBS07-Chroma Patch].zip` |
| KuramA's config | 2026-11-05 | the patched pack's name plus `.txt` |

Avoid ChromaPatch 1.0.1 on GTNH: its changelog says most lamps gave no light until 1.0.2.

Eclipse is pinned because `3c18afc` is the commit ChromaPatch targets, and all 19 patched
files match it. The `Unstable` head on 2026-11-06 (`e89e6c6`) also applied, with 14 of 19
files matching and no fuzzy hunks, but wasn't installed. The `gtnh-mod-updates` skill reports
new commits to Eclipse and to the Kura packs against the pins in
[mod-sources.json](./mod-sources.json); change a `pin` when you move to that commit.

### Install

Close the game first: it rewrites `options.txt` on exit.

1. Download the Forge 1.7.10 jar from
   <https://github.com/Summxx/ChromaPatch/releases> into `mods/`. Check it against the
   release's `SHA256SUMS`. It accepts any remote version, so a server without it still lets
   you join.
2. Download Eclipse into `shaderpacks/` without unzipping it. The pinned commit is
   <https://github.com/Merlin1809/Eclipse-Shader/archive/3c18afcfd89c3bbc4ddf1cf3ea9867731ecd4cc7.zip>.
3. Copy these from <https://github.com/KuramA-777/GTNH-2.9.X-Shader-Edits-and-PBR-Packs>,
   which has no releases, so take them from `main`:
   - `KuraNeonGTNH`, `KuraReflectionsGTNH`, `KuraBetterCoilsGTNH` and `KuraNeonExtrasGTNH`
     zips into `resourcepacks/`, still zipped
   - `Eclipse-Shader KuraEdit [OBS07-Chroma Patch].zip.txt` into `shaderpacks/`, keeping
     that exact name, so the pack finds its settings
4. Build the patched pack by starting the game, or without it, as below. Either way it
   reports the match count, and a failed patch writes a `.log` listing the failed parts.

   ```bash
   java -cp mods/chromapatch-1.0.2-forge1710-1.7.10.jar obs07.chroma.Patcher
   ```

5. Select the patched pack under Video Settings, Shader Packs. The same setting is
   `shaderPack=` in `config/shaders.properties`.
6. Enable the packs, with this order from the top of the in-game list:
   `KuraNeonGTNH`, `KuraReflectionsGTNH`, `KuraBetterCoilsGTNH`, `KuraNeonExtrasGTNH`,
   `Neon.Horizons.v1.2`, `ModernHDFont`, `Shadow.UI.v5.47`, `GTNH-Faithful-x32`.
   `resourcePacks:` in `options.txt` holds the same list bottom first.

The first launch shows a ChromaPatch welcome page with the patch result, and asks whether
to allow its version check (`updates=ask|on|off` in `config/chromapatch.properties`). The
mod never downloads code.

### Settings

Since 2026-11-07 there are two copies of the patched pack:

- `Eclipse-Shader KuraEdit [OBS07-Chroma Patch].zip` has KuramA's file, downloaded fresh
  from the pinned commit and unedited.
- `Eclipse-Shader Warpledge Edit.zip` is a plain copy that starts on the pack's defaults.
  ChromaPatch doesn't rebuild it, so copy the pack again after a patch or Eclipse update,
  then redo its two edits:
  - `shaders.properties` drops the blank row under `[Atmosphere]` in the main `screen`, to
    bring back the Misc Settings and Mod Support row. Whether the row was cut off is
    unconfirmed.
  - `dimensions/composite6.fsh` has `.minecraft/eclipse-tuning/eclipse-lod-taa.patch`, to
    calm Distant Horizons shimmer. LOD pixels keep 90% of the last frame, skip the
    anti-ghosting ratio and keep the full 3x3 colour range, as Complementary's TAA does for
    LODs. Untested in game as of 2026-11-07; the pack before it is
    `.minecraft/eclipse-tuning/Eclipse-Shader Warpledge Edit before LOD TAA.zip`.

Warpledge Edit's settings on 2026-11-07, also copied to
`.minecraft/eclipse-tuning/warpledge-edit-settings-2026-11-07-0210.txt`. To restore them,
copy that file to `shaderpacks/` as `Eclipse-Shader Warpledge Edit.zip.txt`:

```properties
AUTO_EXPOSURE=false
BLOOM_STRENGTH=0.75
DEFERRED_SSR_QUALITY=100
EMISSIVE_TYPE_SETTING=2
Emissive_Brightness=4.0
Emissive_Curve=1.0
FORWARD_SSR_QUALITY=100
HANDHELD_LIGHT_RANGE=20
HANDHELD_LIGHT_REFLECTIONS=75
Haze_amount=0.6
LPV_NORMAL_STRENGTH=70
LPV_NOSHADOW_HACK=true
LPV_SATURATION=70
LPV_SIZE=8
LPV_TINT_SATURATION=110
LPV_VL_FOG_ILLUMINATION=false
LPV_VL_FOG_ILLUMINATION_BRIGHTNESS=0
LPV_VL_FOG_ILLUMINATION_HANDHELD_WATER=false
NORMAL_MAP_MULT=0.5
POM_DEPTH=0.15
QUARTER_RES_SSR=false
RAIN_MODE=0
SHARPENING=0
STARS_AMOUNT=1.75
STARS_BRIGHTNESS=1.5
TORCH_AMOUNT=1.3
TORCH_B=0.57
TORCH_G=0.75
VL_RENDER_SCALE=1.0
VL_SAMPLES=4
shadowDistance=192.0
```

The older settings, with local changes on top of KuramA's, are in
`.minecraft/eclipse-tuning/kuramA-settings-as-used-2026-11-07.txt`. The rest of this
section describes KuramA's file.

KuramA recommends the `KuraBalanced` profile for FPS and compatibility in GTNH. Their
config file matches it, checked against the patched `shaders.properties` on 2026-11-06,
with two exceptions:

- The file leaves out `indirect_effect`, so it falls back to `SSAO_FILTERED` where the
  profile sets `VANILLA_AO`. This instance's copy leaves it that way.
- The file adds `LPV_NOSHADOW_HACK=true`, which the profile doesn't set.

The profile leaves the OBS07 fog, dust and lamp beam effects off; they're on the Atmosphere
page of the shader options.

### Resource pack choices

KuramA's load order lists Modernity-GTNH under their packs. This instance keeps its
Faithful x32 base instead, so:

- `KuraBetterCoilsGTNH` is a Modernity edit and replaces the GregTech coil textures, in
  Modernity's style, on top of Faithful.
- `KuraNeonExtrasGTNH` swaps Chisel terracotta and Valentine textures rather than adding
  maps. KuramA's README says to install "3-4 zip files" without naming the optional one.
- `Neon.Horizons.v1.2` stays below the Kura packs because it covers far more blocks.
  `KuraNeonGTNH` replaces 837 of its 871 files where they overlap. KuramA's README
  doesn't name this combination, so try removing it if a block looks wrong.

Also in `resourcepacks/` since 2026-11-06, not enabled when added:
`Modernity-2.9.x-fa35a3d` (Modernity-GTNH weekly 2026-10-26),
`Modernity-f1-3.10.3.1` (AstroTibs; the wiki lists it for 2.8.X only),
`Zedtech-GTNH-1.8.0` and `GTNH Polished Textures v2.9.0-RC-2`.

KuramA's README warns of visual bugs on blocks that are both reflective and emissive, and
calls the packs a work in progress.

### Updating

- **ChromaPatch:** replace the jar in `mods/`. The patched pack is rebuilt on launch when
  the Eclipse zip or the patch changes.
- **Eclipse:** add the new zip to `shaderpacks/` and restart; the newest zip is used. A
  version too far from the target writes no pack, only a `.log`.

### Switching back

Set `shaderPack=ComplementaryUnbound_r5.8.1 + EuphoriaPatches_1.9.3` and drop the four
Kura packs, in game or in the two files from the install steps. ChromaPatch can stay in
`mods/`.

## NeonTech

NeonTech is S4mpsa's Euphoria Patches configuration for GTNH 2.9: neon emissives and
LabPBR reflections, paired with the Neon Horizons resource pack that supplies specular
and emissive maps for GTNH blocks. It replaces the 2.8.4 setup entirely; the
hand-edited `block.properties` and `terrainIPBR.glsl` from that pack do not carry over.

### Versions

The guide (last updated 2026-07-01) was tested with:

- GTNH 2.9.x
- Angelica 2.1.32 (the pack ships 2.2.43)
- Complementary Unbound 5.8.1
- Euphoria Patches 1.9.3

The config works on newer releases, but its values then have to be copied across by
hand. Complementary Reimagined 5.7 is not compatible with 2.9; the GTNH wiki gives
5.6.1 for 2.8.x and 5.8.1 or newer for 2.9.x.

### Install

1. Complementary Unbound from <https://www.complementary.dev/shaders/> into
   `shaderpacks/`.
2. Euphoria Patches for Forge 1.7.10 into `mods/`; it detects Unbound and writes a
   patched variant into `shaderpacks/` on first launch.
3. Neon Horizons v1.2 (`Neon.Horizons.v1.2.zip`) from
   <https://github.com/S4mpsa/NeonHorizons/releases> into `resourcepacks/`.
4. The NeonTech config zip (`NeonTech Shader v1.1.zip`), unzipped into `shaderpacks/`.
   It holds a single settings file, `ComplementaryUnbound_r5.8.1 + EuphoriaPatches_1.9.3.txt`,
   which must carry the patched pack's exact name.
5. Enable Neon Horizons under Resource Packs, and the patched Unbound pack under Video
   Settings, Shader Packs.

The settings file names the patched pack, so install the tested pair. With newer
versions the file has to be renamed and its values copied by hand.

### Settings

- Coloured lighting: Euphoria Patches → Popular → Colored Lighting → `Screen-space`.
- Emission strength: Materials → labPBR/seuspbr Materials → Custom Emission Intensity.
- Anti-aliasing (2026-11-04): Temporal Filtering on, Temporal Smoothing High, Temporal
  Jitter Low. With filtering off, Distant Horizons terrain shimmers badly; Full jitter
  stops that but makes edges vibrate while standing still.
- Distant Horizons jitter patch (2026-11-04): keeps Full jitter on distant terrain only.
  It adds `TAAJitterLod` to `lib/antialiasing/jitter.glsl`, the same function without the
  `TAA_JITTER` scaling, and calls it for both `TAAJitter` uses in
  `program/dh_terrain.glsl`. It lives in the generated patched folder, so redo it if
  Euphoria regenerates that folder. The patch file and originals are in the instance's
  `.minecraft/eclipse-tuning/`.

### Files kept

Its files stay in place while Eclipse is active: `ComplementaryUnbound_r5.8.1.zip`, the
patched folder and its `.txt` in `shaderpacks/`, `Neon.Horizons.v1.2.zip`, and the Euphoria
Patcher jar. The patches from the earlier Eclipse and Photon experiments are in
`.minecraft/eclipse-tuning/`.

### Extra mods

- **Distant Horizons** (see [mods.md](./mods.md)): enable Aggressive Chunk Loading under
  Video Settings → Performance to stop transparent chunks.
- **Better Foliage** was tried at 1.2.4 and removed. `separateAo = false` did fix the
  black foliage, but the mod was too buggy under 2.9, so that key is back at its default
  `true`. If it is reinstalled, set it in the generated patched folder's
  `shaders/shaders.properties`; the source zip is hash-checked by Euphoria.

### Known issues

- Botania's mana pool can cast shadows that follow the player. If that happens, set
  `B:shaders.enabled=false` in `config/Botania.cfg`; it is on by default on 2.9.
- The 2.8.4 pack's manual block material edits were written for Complementary
  Reimagined 5.7.1 and Euphoria 1.8.6. Neon Horizons supersedes them.

## Sources

- [S4mpsa/NeonHorizons](https://github.com/S4mpsa/NeonHorizons)
- [Summxx/ChromaPatch](https://github.com/Summxx/ChromaPatch)
- [KuramA-777/GTNH-2.9.X-Shader-Edits-and-PBR-Packs](https://github.com/KuramA-777/GTNH-2.9.X-Shader-Edits-and-PBR-Packs)
- [Merlin1809/Eclipse-Shader](https://github.com/Merlin1809/Eclipse-Shader)
- [GTNH wiki: Shader](https://wiki.gtnewhorizons.com/wiki/Shader)
- [Angelica 2.x changelog](https://changelog.gtnh.ogricanx.ch/2.8.4_to_2.9.0/chapters/angelica-2-x.html)
