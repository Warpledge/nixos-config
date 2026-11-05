# GTNH 2.9.0 Shaders: NeonTech

NeonTech is S4mpsa's Euphoria Patches configuration for GTNH 2.9: neon emissives and
LabPBR reflections, paired with the Neon Horizons resource pack that supplies specular
and emissive maps for GTNH blocks. It replaces the 2.8.4 setup entirely; the
hand-edited `block.properties` and `terrainIPBR.glsl` from that pack do not carry over.

## Versions

The guide (last updated 2026-07-01) was tested with:

- GTNH 2.9.x
- Angelica 2.1.32 (the pack ships 2.2.43)
- Complementary Unbound 5.8.1
- Euphoria Patches 1.9.3

The config works on newer releases, but its values then have to be copied across by
hand. Complementary Reimagined 5.7 is not compatible with 2.9; the GTNH wiki gives
5.6.1 for 2.8.x and 5.8.1 or newer for 2.9.x.

## Install

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

## Settings

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

## What's active

As of 2026-11-05, `config/shaders.properties` selects
`ComplementaryUnbound_r5.8.1 + EuphoriaPatches_1.9.3`, and the resource packs are
`Shadow.UI.v5.47.zip` and `Neon.Horizons.v1.2.zip`. Also in `shaderpacks/`, not selected:
`Eclipse-Shader-GTNH`, `Eclipse-GTNH-CompRef` and `photon_v1.4-gtnh`, with their source
zips. The patches behind those edits are in `.minecraft/eclipse-tuning/`.

## Extra mods

- **Distant Horizons** (see [mods.md](./mods.md)): enable Aggressive Chunk Loading under
  Video Settings → Performance to stop transparent chunks.
- **Better Foliage** was tried at 1.2.4 and removed. `separateAo = false` did fix the
  black foliage, but the mod was too buggy under 2.9, so that key is back at its default
  `true`. If it is reinstalled, set it in the generated patched folder's
  `shaders/shaders.properties`; the source zip is hash-checked by Euphoria.

## Known issues

- Botania's mana pool can cast shadows that follow the player. If that happens, set
  `B:shaders.enabled=false` in `config/Botania.cfg`; it is on by default on 2.9.
- The 2.8.4 pack's manual block material edits were written for Complementary
  Reimagined 5.7.1 and Euphoria 1.8.6. Neon Horizons supersedes them.

## Sources

- [S4mpsa/NeonHorizons](https://github.com/S4mpsa/NeonHorizons)
- [GTNH wiki: Shader](https://wiki.gtnewhorizons.com/wiki/Shader)
- [Angelica 2.x changelog](https://changelog.gtnh.ogricanx.ch/2.8.4_to_2.9.0/chapters/angelica-2-x.html)
