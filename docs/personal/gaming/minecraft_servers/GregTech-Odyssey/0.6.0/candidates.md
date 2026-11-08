# GTO 0.6.0 Mod Candidates (from Cosmic Frontiers)

The 105 mods added by hand to the Cosmic Frontiers 0.8.0 pack in 2026-04, sorted by how
risky each would be in GTO 0.6.0-dev27. Checked 2026-11-07 against dev27's mod list and
each mod's newest 1.20.1 Forge build on Modrinth, including its required dependencies.
The recovered Cosmic Frontiers notes, with the config and KubeJS work done back then,
are in `~/Downloads/cosmic_frontiers_notes/`.

**Needs** lists only required mods that dev27 doesn't ship. "CurseForge only" means the
lookup found no 1.20.1 Forge build on Modrinth. Pick a batch, then trial it with
`gto stage` as described in [updating.md](./updating.md).

## Integrated mods (dropped 2026-11-07)

**Dropped after batch 2 broke EMI in staging.** Kept as a record of what was tried, so
a retry starts from what failed.

- With all of batch 2, EMI's recipe reload threw a NullPointerException inside gtolib
  (GTO's closed-source core, `EmiRecipes.bake`), so EMI showed no recipes and its search
  box stopped responding.
- With Quark, Zeta, IDAS, Integrated Stronghold, Integrated Dungeons Arise and Integrated
  Seven Seas disabled, the error went away but EMI's search returned nothing; its
  `EMI Search Bake` thread started and never logged finishing. The unmodified pack's
  search works, so the rest of batch 2 (Create, Supplementaries, Amendments, Moonlight,
  KubeJS, Rhino, Integrated API, Patches, Villages) breaks it too.
- Quark adds 1,602 recipes; the Integrated jars add one or none. The structures use 543
  Quark block types (about 350,000 placements), so Quark can't be dropped from under
  them.
- Integrated Stronghold's 61 templates hold 4,529 block entities (about 570 Create
  gearboxes, water wheels and shafts, about 500 banners) and 7,583 lava blocks; it
  dropped the frame rate from about 160 to 20 with shaders.
- Structures were far too dense on top of When Dungeons Arise, and none of the mods has a
  spacing setting; it would take a datapack overriding their `structure_set` files.
- Integrated Villages 1.3.2 lists a `swamp_village` it doesn't ship, which makes the
  whole `#minecraft:village` tag fail to load.

The best structure mods from the Cosmic Frontiers testing. All 11 have 1.20.1 Forge
builds (Modrinth, 2026-11-07). 8 of them build their structures from Create, Quark and
Supplementaries blocks, so those three come in as block libraries: their blocks stay
registered for the structures, while their machines and recipes are removed and hidden.
dev27 has no KubeJS, so batch 2 adds it for that; the Cosmic Frontiers
`gregification.md` has the recipe patterns. Create is listed as compatible with GTO on
the pack's site but has no integration.

| Batch | Mods | Needs from outside dev27 |
| --- | --- | --- |
| 1 | Integrated API 1.9.1, Integrated Patches 1.2.0 | none |
| 2 | IDAS 1.13.0, Integrated Villages 1.3.2, Integrated Stronghold 1.1.1, Integrated Dungeons Arise 2.1.3, Integrated Seven Seas 1.0.0 | Create, Quark, Zeta, Supplementaries, Amendments, Moonlight, KubeJS |
| 3 | Integrated Cataclysm 1.0.5, Integrated Mowzie's Mobs 1.3.2, Integrated Bosses of Mass Destruction 1.0.0, Integrated Simply Swords 1.3.1 | Each one's base mod: L_Ender's Cataclysm (Lionfish API), Mowzie's Mobs, Bosses of Mass Destruction (Cerbon's API), Simply Swords |

- Integrated Stronghold's last 1.20.1 build is from 2024-03, and Bosses of Mass
  Destruction's from 2024-01; the rest were updated in 2026.
- Integrated Dungeons Arise and Seven Seas don't list When Dungeons Arise or WDA: Seven
  Seas as required. The first trial launch shows whether they need them.
- Modrinth's dependency lists come from the authors and can be wrong: Integrated
  Villages lists none, but its jar's `mods.toml` makes Create and Supplementaries
  mandatory. Read each jar's `mods.toml` when it's added.
- Batch 1 passed in staging on 2026-11-07 (new world, DH generating, reload, `gto check`
  clean), but adds no structures by itself, so it went no further.
- Integrated Stronghold and YUNG's Better Strongholds both replace the stronghold: use
  one. dev27's End Remastered patches stronghold pieces too.

## Already in dev27

All The Leaks, AttributeFix, Embeddium, Model Gap Fix, Distant Horizons, Oh The Biomes
We've Gone, When Dungeons Arise, Explorer's Compass, Keep Stepping, Resourcify.

## Low risk: client-side or QoL

No recipes that skip GT tiers and no worldgen, so a failed trial can't touch the world.

**Added to main on 2026-11-07** (see [mods.md](./mods.md)): AmbientSounds, Presence
Footsteps, Sounds, Sound Physics Remastered, Cool Rain, Particular, EMF, ETF, Smooth
Swapping, Particle Core, Better Climbing, Connectible Chains, TrashSlot, the four
Macaw's mods, Enderman Overhaul and Creeper Overhaul, plus Zipline from the
gregification list. The Diagonal mods failed and moved to [Skip](#skip).

| Mod | Needs | Note |
| --- | --- | --- |
| Chunky | | Pre-generates chunks; pairs with Distant Horizons |
| Ksyxis | | Faster world loading |
| Entity Culling | | |
| SmoothBoot (Reloaded) | | CurseForge only |
| Chunk Sending | | Server side; CurseForge only |
| Rubidium Extra | | Embeddium add-on |
| AmbientSounds | | Biome ambience; CreativeCore ships in dev27 |
| SoL: Onirique | | Also biome ambience: pick it or AmbientSounds. CurseForge only |
| Presence Footsteps | | |
| Sounds | MRU, YACL | MRU is CurseForge only. Neither declares YACL, so Prism skips it; add it by hand |
| Sound Physics Remastered | | |
| TIMM | | |
| Cool Rain | | |
| Particular | | |
| Entity Model Features, Entity Texture Features | | EMF needs ETF |
| Smooth Swapping | | |
| Particle Core | Fzzy Config, Kotlin for Forge | dev27 ships Async Particles, which also changes particles: trial it alone |
| Better Climbing | | |
| Catalogue | | Mod list screen; not found on Modrinth by this lookup |
| Connectible Chains | | |
| Enchantment Descriptions | Bookshelf | |
| TrashSlot | | |
| Macaw's Bridges, Lights, Fences, Stairs | | Decoration; vanilla-material recipes |
| Guard Villagers | | |
| Enderman Overhaul, Creeper Overhaul | | Mob variants; their libraries ship in dev27 |

## Needs gregification

These add craftable items that would skip GT tiers. The Cosmic Frontiers `gregification.md`
has the KubeJS patterns and tier tables from the first time.

| Mod | Needs | Note |
| --- | --- | --- |
| Tom's Simple Storage | | Item networks that bypass AE2; gregified in Cosmic Frontiers |
| Simply Swords, Simply Swords Overhaul | Fzzy Config, Simply Tooltips | Gregified in Cosmic Frontiers, unique weapons included |
| Illager Invasion | | Imbuing table gregified in Cosmic Frontiers; also adds raids |
| Zipline | | Craftable traversal |
| Supplementaries | Moonlight | Many utility blocks, some of which shortcut automation |

## Worldgen

These only show up in chunks generated after they're added, so test each in a fresh test
world as well as in the staging copy. Two biome or structure mods can also fight over
the same spots.

| Mod | Needs | Note |
| --- | --- | --- |
| Biomes O' Plenty | GlitchCore | Shares TerraBlender with BWG; Cosmic Frontiers balanced the two in `biomesoplenty/biome_toggles.json` |
| Amplified Nether, Nether Remastered | | Nether terrain |
| YUNG's Better Desert Temples, Dungeons, Jungle Temples, Mineshafts, Nether Fortresses, Ocean Monuments, Witch Huts | YUNG's API | |
| YUNG's Better Strongholds | YUNG's API | dev27 ships End Remastered, which patches stronghold pieces (`StrongholdPiecesMixin`) and replaces the eyes: check that they work together |
| YUNG's Cave Biomes | YUNG's API | |
| When Dungeons Arise: Seven Seas | | Cosmic Frontiers ran the 1.19.2 jar; Modrinth has a 1.20.1 build |
| Luki's Grand Capitals, Luki's Woodland Mansions | | |
| Moog's Nether Structures, Moog's Soaring Structures | Moog's Structure Lib | |
| Structure Essentials | | Spacing control for when you add many structure mods; CurseForge only |
| Samurai Dynasty | | Adds 6 ores; Cosmic Frontiers suppressed all but Spirit Stone with biome-modifier overrides (`config-tweaks.md`). Its weapons need gregification too |
| Mowzie's Mobs | | Boss structures |
| L_Ender's Cataclysm | Lionfish API | Boss arenas and very strong gear: gregify the gear |
| Mowzie's Cataclysm, Simply Swords: Cataclysm, Cataclysm & BetterCombat Compat | | Compat for the mods above; add only with them. Integrated Cataclysm was [dropped](#integrated-mods-dropped-2026-11-07) |

## Gameplay changes

These change how combat and nights feel. They don't break the world, but play a few
sessions in staging before deciding.

| Mod | Needs | Note |
| --- | --- | --- |
| Better Combat | playerAnimator | Changes every melee attack; try it with GT tools, which are weapons too |
| Apothic Combat | Better Combat | Apotheosis ships in dev27 |
| Alex's Mobs, Alex's Mobs Interaction | Citadel | 80+ mobs and some craftable gear; Cosmic Frontiers tuned their spawns |
| Alex's Delight | Alex's Mobs | Farmer's Delight ships in dev27. The Modrinth match was unsure; check the source |
| L_Ender's Delight | L_Ender's Cataclysm | |
| Domestication Innovation | Citadel | |
| Majrusz's Enchantments | Majrusz Library | dev27's Apotheosis already reworks enchanting: check that they work together |
| Enhanced Celestials | Data Anchor | Blood moons raise spawns; CorgiLib ships in dev27 |

## Skip

| Mod | Why |
| --- | --- |
| Majrusz's Difficulty | GTO's own difficulty rules do this job |
| Inventory Profiles Next, libIPN | dev27 ships Inventory Tweaks; two sorters fight over the same keys |
| Smooth Chunk Save | Changes how chunks save, on a dev build that already warns of corrupted saves |
| Tinkers' Better Combat | Needs Tinkers' Construct, which GTO lacks |
| Aether Villages | Needs The Aether, which GTO lacks |
| Quark, Zeta | Too broad to trial in one go (worldgen, automation blocks, mob changes), and with batch 2 of [the Integrated mods](#integrated-mods-dropped-2026-11-07) it broke EMI's recipe reload inside gtolib |
| Cupboard | Only a library for the someaddons mods, none of which are on this list |
| Diagonal Walls, Windows, Fences | Their `diagonalblocks` 8.0.6 throws `target block tags not empty` on the second tag reload (staging, 2026-11-07): the first world loads, but EMI never gets its data, and leaving to the title and loading or creating any world crashes |

## Sources

- Modrinth API `v2/search` and `v2/project/<slug>/version` (Forge, 1.20.1), 2026-11-07
- dev27's `mods/` jars and their `META-INF/mods.toml`
- The Cosmic Frontiers notes from `Warpledge/nixos-config-old-private` (deleted 2026-04-26)
