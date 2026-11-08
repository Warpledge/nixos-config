# GTO 0.6.0 Added Mods

The jars added by hand to dev27, on top of the pack's 157. Descriptions come from each
jar's `META-INF/mods.toml`.

## Before the staging setup

| Jar | Mod | What it does |
| --- | --- | --- |
| `DistantHorizons-3.3.3-1.20.1-fabric-forge.jar` | Distant Horizons | Renders simplified terrain past the normal view distance |
| `KeepStepping-Forge-1.20.1-1.0.0.jar` | Keep Stepping | Toggles smooth step-up, auto jump, or neither |
| `Resourcify (1.20.1-forge)-1.8.7.jar` | Resourcify | In-game browser for resource packs, data packs and shaders |
| `touhoulittlemaid-1.5.3-forge+mc1.20.1.jar` | Touhou Little Maid | Maid companions |
| `ysm-2.6.5-forge+mc1.20.1-release.jar` | Yes Steve Model | Replaces the player model (GeckoLib based) |

Distant Horizons, Touhou Little Maid and Yes Steve Model were also in the 0.5.6
instance at the same versions. dev27 ships Embeddium, Oculus and Xaero's maps itself.

## From Cosmic Frontiers (2026-11-07)

Passed a staging trial in a new world on 2026-11-07, then copied to main. The Diagonal
mods from the same batch crashed on tag reload and were dropped
([candidates.md](./candidates.md#skip)).

| Jar | Mod | What it does |
| --- | --- | --- |
| `AmbientSounds_FORGE_v6.3.11_mc1.20.1.jar` | AmbientSounds | Expands ambient sounds |
| `Presence Footsteps [FORGE] 1.0.0.jar` | Presence Footsteps | Footstep sounds by surface (Forge port) |
| `Sounds-2.2.1+1.20.1+forge.jar` | Sounds | New sound effects and reworked vanilla ones |
| `sound-physics-remastered-forge-1.20.1-1.5.1.jar` | Sound Physics Remastered | Sound attenuation, reverb and absorption through blocks |
| `coolrain-1.20.1-Forge-1.0.3.jar` | Cool Rain Reforged | Rain visuals |
| `particular-1.20.1-Forge-1.5.7.jar` | Particular Reforged | Ambient effects such as falling leaves, fireflies and waterfall spray |
| `particle_core-0.3.3+1.20.1+forge.jar` | Particle Core | Particle culling and rendering optimization |
| `entity_model_features-3.3.12-1.20.1-forge.jar` | Entity Model Features | Custom entity model (CEM) resource pack support |
| `entity_texture_features-7.2.7-1.20.1-forge.jar` | Entity Texture Features | Resource-pack entity texture features; EMF needs it |
| `smoothswapping-0.9.3.2-1.20.1-forge.jar` | Smooth Swapping | Animates items moving in inventories |
| `better_climbing-forge-3.jar` | Better Climbing | Climbing improvements |
| `connectiblechains-forge-1.20.1-2.2.5.jar` | Reconnectible Chains | Decorative chains between fences |
| `zipline-forge-1.20.1-1.3.0.jar` | Ziplines: Rezipped! | Ziplines |
| `mcw-bridges-3.1.2-mc1.20.1forge.jar` | Macaw's Bridges | Bridges |
| `mcw-lights-1.1.5-mc1.20.1forge.jar` | Macaw's Lights and Lamps | Lamps and lights |
| `mcw-mcwfences-1.2.1-mc1.20.1forge.jar` | Macaw's Fences and Walls | Fences, walls and gates |
| `mcw-mcwstairs-1.0.2-mc1.20.1forge.jar` | Macaw's Stairs | Stairs, handrails and balconies |
| `trashslot-forge-1.20.1-15.1.5.jar` | TrashSlot | Trash slot in the inventory screen |
| `creeperoverhaul-3.0.2-forge.jar` | Creeper Overhaul | Biome-specific creepers |
| `endermanoverhaul-forge-1.20.1-1.0.4.jar` | Enderman Overhaul | Biome-specific endermen |
| `fzzy_config-0.7.7+1.20.1+forge.jar` | Fzzy Config | Library for Particle Core |
| `mru-1.0.41+1.20.1-forge.jar` | MRU | Library for Sounds; CurseForge only, installed through Prism |
| `yet_another_config_lib_v3-3.6.6+1.20.1-forge.jar` | YACL | Library; Sounds and MRU call it but don't declare it, so Prism doesn't pull it in |

Kotlin for Forge, which Particle Core and Fzzy Config need, already ships in dev27.

**Configs:** Cosmic Frontiers only changed Particular, to `fallingLeaves = true` and a
falling-leaf `spawnChance` of 60; 1.5.7's defaults already match. Sounds ships
Minecraft 1.21 `c:` tags (mace, breeze rod), which log `Couldn't load tag` errors on
1.20.1 and are harmless. EMF, ETF, Presence Footsteps and Particle Core crashed a
dedicated server in Cosmic Frontiers, so a GTO server would need them client-only.

The shader pack is `Eclipse-Shader Warpledge Edit.zip` in `shaderpacks/`, a copy of the
one the GTNH notes' [build.py](../../GTNH/2.9.0/eclipse-warpledge-edit/build.py) makes,
with its own `.zip.txt` settings.

The same jars, with their modIds and sources, are in
[overlay.json](../tools/overlay.json), which `gto carry` reads to copy them into a new
build. A mod added or removed here changes there too. Candidates from Cosmic Frontiers
are sorted by risk in [candidates.md](./candidates.md), and the trial steps are in
[updating.md](./updating.md#a-mod-trial).
