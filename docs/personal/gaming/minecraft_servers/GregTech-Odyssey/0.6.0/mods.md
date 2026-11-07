# GTO 0.6.0 Added Mods

The jars added by hand to dev27, found by comparing the instance's `mods/` with the
pack's 157 jars on 2026-11-07. Descriptions come from each jar's `META-INF/mods.toml`.
All six declare `side = "BOTH"`.

| Jar | Mod | What it does |
| --- | --- | --- |
| `DistantHorizons-3.3.3-1.20.1-fabric-forge.jar` | Distant Horizons | Renders simplified terrain past the normal view distance |
| `KeepStepping-Forge-1.20.1-1.0.0.jar` | Keep Stepping | Toggles smooth step-up, auto jump, or neither |
| `Resourcify (1.20.1-forge)-1.8.7.jar` | Resourcify | In-game browser for resource packs, data packs and shaders |
| `touhoulittlemaid-1.5.3-forge+mc1.20.1.jar` | Touhou Little Maid | Maid companions |
| `maidmarriage-1.0.0-forge+mc1.20.1.jar` | Touhou Little Maid: Heart Pact | Romance and family add-on for Touhou Little Maid, which it requires |
| `ysm-2.6.5-forge+mc1.20.1-release.jar` | Yes Steve Model | Replaces the player model (GeckoLib based) |

Distant Horizons, Touhou Little Maid, Heart Pact and Yes Steve Model were also in the
0.5.6 instance at the same versions. dev27 ships Embeddium, Oculus and Xaero's maps
itself.

The shader pack is `Eclipse-Shader Warpledge Edit.zip` in `shaderpacks/`, a copy of the
one the GTNH notes' [build.py](../../GTNH/2.9.0/eclipse-warpledge-edit/build.py) makes,
with its own `.zip.txt` settings.

A new pack build is imported as a new instance, which doesn't bring these six along; copy
them over by hand (see [updating.md](./updating.md)).
