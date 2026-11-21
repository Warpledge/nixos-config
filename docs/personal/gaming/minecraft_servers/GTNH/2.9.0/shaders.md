# GTNH 2.9.0 Shaders

Two setups are installed side by side: [Eclipse with ChromaPatch](#eclipse-with-chromapatch)
is the active one, and [NeonTech](#neontech) is the one to switch back to.

## Eclipse with ChromaPatch

KuramA's and OBS07's setup, from KuramA's install post dated 2026-11-05: an edit of the
Eclipse shader with coloured lighting, plus LabPBR packs for GTNH's neon blocks. The edit
can't be redistributed, so the ChromaPatch mod builds it locally from the Eclipse zip.

### Versions

Installed 2026-11-06; ChromaPatch 1.0.3 and Eclipse `e89e6c6` replaced 1.0.2 and
`3c18afc` on 2026-11-15. It needs GTNH 2.9.0 stable on Java 25 or newer; the instance runs
Java 25.0.4.1 and Angelica 2.2.46.

| Part | Version | File |
| --- | --- | --- |
| ChromaPatch | 1.0.3 | `mods/chromapatch-1.0.3-forge1710-1.7.10.jar` |
| Eclipse source | `e89e6c6` (2026-10-16) | `shaderpacks/Eclipse-Shader-e89e6c6.zip` |
| Patched pack | Eclipse GTNH patch 1.0.3 | `shaderpacks/Eclipse-Shader KuraEdit [OBS07-Chroma Patch].zip` |
| KuramA's config | 2026-11-05 | the patched pack's name plus `.txt` |

Avoid ChromaPatch 1.0.1 on GTNH: its changelog says most lamps gave no light until 1.0.2.

Eclipse is pinned to the commit ChromaPatch's patch profile names as its base (`base=` in
`data-forge1710/chromapatch/eclipse_gtnh.chroma` since 1.0.3, which gave the 1.7.10 jar its
own GTNH patch). 1.0.3 also turned the OBS07 fog, godrays, dust and lamp beams off by
default, raised the moonlight and lowered the fog; Warpledge Edit's settings pin the 1.0.2
values (see [Settings](#settings)). The `gtnh-mod-updates` skill reports new commits to
Eclipse and to the Kura packs against the pins in
[mod-sources.json](./mod-sources.json); change a `pin` when you move to that commit.

### Install

Close the game first: it rewrites `options.txt` on exit.

1. Download the Forge 1.7.10 jar from
   <https://github.com/Summxx/ChromaPatch/releases> into `mods/`. Check it against the
   release's `SHA256SUMS`. It accepts any remote version, so a server without it still lets
   you join.
2. Download Eclipse into `shaderpacks/` without unzipping it. The pinned commit is
   <https://github.com/Merlin1809/Eclipse-Shader/archive/e89e6c6eda248ae946480bd131db1b2a0a0f5c9e.zip>.
3. Copy these from <https://github.com/KuramA-777/GTNH-2.9.X-Shader-Edits-and-PBR-Packs>,
   which has no releases, so take them from `main`:
   - `KuraNeonGTNH`, `KuraReflectionsGTNH`, `KuraBetterCoilsGTNH` and `KuraNeonExtrasGTNH`
     zips into `resourcepacks/`, still zipped
   - `Eclipse-Shader KuraEdit [OBS07-Chroma Patch].zip.txt` into `shaderpacks/`, keeping
     that exact name, so the pack finds its settings
4. Build the patched pack by starting the game, or without it, as below. Either way it
   reports the match count, and a failed patch writes a `.log` listing the failed parts.

   ```bash
   java -cp mods/chromapatch-1.0.3-forge1710-1.7.10.jar obs07.chroma.Patcher
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

### Warpledge Edit

Since 2026-11-07 there are two copies of the patched pack in `shaderpacks/`:

- `Eclipse-Shader KuraEdit [OBS07-Chroma Patch].zip` is ChromaPatch's output with
  KuramA's settings file, downloaded fresh from the pinned commit and unedited. It's the
  reference; don't change settings on it.
- `Eclipse-Shader Warpledge Edit.zip` is the one in use: the same pack with the edits
  below and its own settings.

GregTech Odyssey runs the same edits on ChromaPatch's 1.20.1 build
([its shaders.md](../../GregTech-Odyssey/0.6.0/shaders.md)).

#### The edits

Eclipse is "All rights reserved", so the repo keeps no copy or diff of its files, only
[eclipse-warpledge-edit/build.py](./eclipse-warpledge-edit/build.py), which finds each
spot by a short anchor and adds the lines below. The full diffs are local, in
`.minecraft/eclipse-tuning/`.

1. **False lights in the distance** (`dimensions/all_solid.fsh`; confirmed in game on
   2026-11-07 with Mipmap Levels at 4). labPBR glow maps mark "no glow" with alpha 255,
   and the Kura packs also use 0. Mipmaps average those with glowing texels, and Eclipse
   reads anything under 254.5/255 as glow, so distant walls and edges lit up as strip
   lights that don't exist, flickered as the averaging shifted, and showed up again as
   shimmering, jagged reflections. The edit samples the glow map again at full size
   (`textureLod(specular, ..., 0.0)`) and only lets a texel glow where both agree, as
   Complementary's `customEmission.glsl` does. Official Eclipse (`3c18afc` and `e89e6c6`)
   has the same bug, so KuraEdit shows it too.
2. **Distant Horizons shimmer** (`dimensions/composite6.fsh`; not tested on its own). On
   LOD pixels the anti-aliasing keeps 90% of the last frame, skips Eclipse's
   `difference / history` boost (which drops history on dark, high-contrast detail) and
   keeps the full 3x3 colour range, much as Complementary's TAA treats LODs.
3. **Mod Support menu** (`shaders.properties`). ChromaPatch adds an `[Atmosphere]` row to
   the main shader menu; the edit drops the blank row under it so Misc Settings and Mod
   Support fit. Whether that row was really cut off is unconfirmed.
4. **GTCEu bordered lamps** (`block.properties`; since 2026-11-15, for GTO). ChromaPatch's
   1.20.1 list gives only the borderless GTCEu lamps their colour; the edit adds each
   `gtceu:<colour>_lamp` beside its borderless one. GTNH ignores those ids.
5. **Glowing beehives** (`block.properties`; since 2026-11-17). Forestry 4.11.40 gives
   `Forestry:beehives` vanilla light 12 in code (`BlockBeehives`), so Eclipse lit them
   like lamps; their Neon Horizons maps have no glow. The edit adds them to `block.1`,
   which ChromaPatch uses for Ztones Lave as a solid block without light. If the ground
   around a hive still lights up, that's 1.0.3's `OBS07_VANILLA_LIGHT_FALLBACK`
   (Atmosphere page), which brings back vanilla light the shader's own lighting misses.

Tried and dropped on 2026-11-07: steadier anti-aliasing on distant real chunks (no
change; the false lights were the cause), and Mipmap Levels 0 (only a test).

#### Rebuilding it

ChromaPatch never rebuilds Warpledge Edit, so after a ChromaPatch or Eclipse update:

1. Close the game and launch it once so ChromaPatch rebuilds KuraEdit, then close it again.
2. Move the old `Eclipse-Shader Warpledge Edit.zip` out of `shaderpacks/`, keeping its
   `.txt`.
3. From `.minecraft`, run the script on the KuraEdit pack:

   ```bash
   python3 -I /etc/nixos-config/docs/personal/gaming/minecraft_servers/GTNH/2.9.0/eclipse-warpledge-edit/build.py "shaderpacks/Eclipse-Shader KuraEdit [OBS07-Chroma Patch].zip"
   ```

   It stops without writing anything if an anchor no longer matches, which means Eclipse
   changed there and the edit needs redoing by hand from the description above.
4. If the `.txt` is lost, copy
   [eclipse-warpledge-edit/settings.txt](./eclipse-warpledge-edit/settings.txt) to
   `shaderpacks/` as `Eclipse-Shader Warpledge Edit.zip.txt`.

On 2026-11-07 the script's output from KuraEdit matched the hand-edited pack file for
file. On 2026-11-15 all three anchors still matched ChromaPatch 1.0.3 on `e89e6c6`; the
1.0.2 build is in `backups/replaced-mods/2026-11-15/`. On 2026-11-17 the beehive edit's
anchor matched too, and the other three files came out identical to the 2026-11-15 build.

#### Settings

[eclipse-warpledge-edit/settings.txt](./eclipse-warpledge-edit/settings.txt) is the copy
from 2026-11-10 15:50. Most values follow KuraEdit where they help GTNH (emission mode,
curve, coloured light saturation, minimum light, sharpening off); clouds, fog, water and
weather stay on Eclipse's defaults. Dated copies, KuramA's file as it was used before and
the local diffs are in `.minecraft/eclipse-tuning/`.

The file only keeps values that differ from the pack's defaults, so a ChromaPatch update
that changes a default changes the look. On 2026-11-15 the file gained 1.0.2's values for
the options 1.0.3 changed: `OBS07_LIGHT_FOG` 1.0, `OBS07_LIGHT_FOG_DAY` 0.1,
`OBS07_FOG_DRIFT` on, `OBS07_GODRAYS` 0.6, `OBS07_DUST` 1.0, `OBS07_LAMP_BEAM` 5.0,
`TOD_Fog_mult` 1.0 and `moon_illuminance` 600. `LPV_SIZE` was already set to 8.

#### KuramA's settings file

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
  doesn't name this combination, so try removing it if a block looks wrong. Without it,
  Ztones Lave stops reflecting: only Neon Horizons has `_s` maps for most variants,
  `KuraReflectionsGTNH` only for (8) and (12) (off 2026-11-06 to 2026-11-17).

Also in `resourcepacks/` since 2026-11-06, not enabled when added:
`Modernity-2.9.x-fa35a3d` (Modernity-GTNH weekly 2026-10-26),
`Modernity-f1-3.10.3.1` (AstroTibs; the wiki lists it for 2.8.X only),
`Zedtech-GTNH-1.8.0` and `GTNH Polished Textures v2.9.0-RC-2`.

KuramA's README warns of visual bugs on blocks that are both reflective and emissive, and
calls the packs a work in progress.

`DarkReimagined_290.3.zip` is the dark GUI pack. `DarkTrashSlot/` (2026-11-18, folder
pack) sits above it and recolours TrashSlot 1.0.31's
`assets/trashslot/textures/gui/slot.png` and trash-can icon to its slot palette, because
the dark pack ships no `assets/trashslot` and the mod's sheet is vanilla grey. It is a
separate folder, so a Dark Reimagined update leaves it in place. Since 2026-11-21 Trash Slot
is gone (Omni Tweaks 0.3.0 draws its own dark slot card), so `DarkTrashSlot/` does nothing
and can be removed.

### Updating

- **ChromaPatch:** replace the jar in `mods/`. The patched pack is rebuilt on launch when
  the Eclipse zip or the patch changes.
- **Eclipse:** add the new zip to `shaderpacks/` and restart; the newest zip is used. A
  version too far from the target writes no pack, only a `.log`.
- **Warpledge Edit:** rebuild it after either update, as in
  [Rebuilding it](#rebuilding-it).

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
