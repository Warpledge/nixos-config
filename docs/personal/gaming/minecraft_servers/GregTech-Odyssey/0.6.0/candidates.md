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
Swapping, Particle Core, Better Climbing, Connectible Chains, TrashSlot, Enderman
Overhaul and Creeper Overhaul, plus Zipline from the gregification list. The Diagonal
mods failed and the four Macaw's mods came out again; both are under [Skip](#skip).

| Mod | Needs | Note |
| --- | --- | --- |
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
| Guard Villagers | | |
| Enderman Overhaul, Creeper Overhaul | | Mob variants; their libraries ship in dev27 |

## Needs gregification

These add craftable items that would skip GT tiers. The Cosmic Frontiers `gregification.md`
has the KubeJS patterns and tier tables from the first time.

| Mod | Needs | Note |
| --- | --- | --- |
| Tom's Simple Storage | | **Added 2026-11-07**, with Tom's Performant Storage and GT recipes ([mods.md](./mods.md#recipe-overrides)) |
| Simply Swords, Simply Swords Overhaul | Fzzy Config, Simply Tooltips | **Simply Swords added 2026-11-07** with GT recipes; Overhaul is in [Skip](#skip). Gregified in Cosmic Frontiers, unique weapons included |
| Illager Invasion | | **Added 2026-11-07**, imbuing table gregified. Also adds raids |
| Zipline | | Craftable traversal |
| Supplementaries | Moonlight | Many utility blocks, some of which shortcut automation |

## Worldgen

These only show up in chunks generated after they're added, so test each in a fresh test
world as well as in the staging copy. Two biome or structure mods can also fight over
the same spots.

| Mod | Needs | Note |
| --- | --- | --- |
| When Dungeons Arise: Seven Seas | | Cosmic Frontiers ran the 1.19.2 jar; Modrinth has a 1.20.1 build |
| Tectonic, Terralith | Lithostitched | In staging. `config/tectonic.json` is on trial: defaults plus `ultrasmooth`, `elevation_boost` 0.2, `min_y`/`max_y` -128/544, `ocean_offset` -0.5 (rare oceans; above -0.45 deep oceans and so monuments stop spawning), `continents_scale` 0.3, `ridge_scale` 0.3, `flat_terrain_skew` -0.1 (2026-11-08). Check GT ores below -64. dev27's BWG is cut to Cosmic Frontiers' 11 biomes in `config/biomeswevegone/world_generation.json`, and its three region weights go from 8 to 2: at 8 they outweighed the vanilla region (10, where Terralith's biomes live) and the world came out mostly BWG, and at 1 BWG was about 1% of visited chunks. Carry those files and `config/terrablender.toml` (`overworld_region_size` 4) to main. Terralith can't be removed from a world later |
| Structurify 2.0.43 | YACL (in dev27) | In staging. Retried for its global flatness check, so structures skip steep ground. Its in-game screen didn't save on 2026-11-07, so `config/structurify.json` is written by hand: global namespace `enable_flatness_check`, mode `AUTO`, max height difference 21, plus `prevent_structure_overlap` (2026-11-08) |
| Luki's Grand Capitals, Luki's Woodland Mansions | | |
| Structure Essentials | | Spacing control for when you add many structure mods; CurseForge only |
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
| L_Ender's Delight | L_Ender's Cataclysm | |
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
| Simply Swords Overhaul | Its last builds (1.0.2 on Modrinth, 1.0.3 and 1.0.4 on GitHub, 2025) target Simply Swords 1.56.0; with 1.70.2 its `StormsEdgeSwordItem` mixin finds no target and the game won't start |
| Nether Remastered | Checks its own `nether_remastered:seal_of_the_underworld` advancement every player tick; GTO's AdvancementNoMore removes all advancements, so it crashes on joining a world (staging, 2026-11-07). Kept AdvancementNoMore, which GTO ships for performance |
| Moog's Nether Structures, Moog's Soaring Structures | Moog's Structure Lib 3.4.2's required `TagLoaderMixin` can't inject into `TagLoader`, which gtolib's own `TagLoaderMixin` (priority 2000) rewrites; the game crashes at world creation (staging, 2026-11-07). An older library might avoid it; untested |
| YUNG's Better Strongholds | Replaces the stronghold eyes of ender lead to; dev27's End Remastered patches stronghold pieces for its own eyes and portal frames, which gate the End |
| Diagonal Walls, Windows, Fences | Their `diagonalblocks` 8.0.6 throws `target block tags not empty` on the second tag reload (staging, 2026-11-07): the first world loads, but EMI never gets its data, and leaving to the title and loading or creating any world crashes |
| Alex's Mobs 1.22.9, Citadel 2.6.3, Domestication Innovation 1.7.1, Alex's Mobs Interaction, Alex's Delight | With Alex's Mobs and Citadel on, EMI's reload fails every time with a `NullPointerException` in gtolib's recipe baking; with them off it loads (staging, 2026-11-08). Domestication Innovation, Interaction and Delight only make sense with Alex's Mobs |
| Celestisynth 1.3.4 | Dropped after a look in staging (2026-11-08). Its `RecipeManagerAccessor` mixin also clashes with ExtendedAE's, and its spellbook needs Iron's Spellbooks, which GTO lacks |
| YUNG's Cave Biomes | Worldgen crashed on a chest or pod placed `facing=down` (in `MonsterRoomFeature` and Ars Nouveau trees); the other YUNG's structure mods load fine without it (staging, 2026-11-08) |
| Biomes O' Plenty | Shares 8 wood names with BWG, so GTO generates duplicate GT recipe ids (e.g. `gtceu:lathe/strip_willow_log`) and EMI fails to load (staging, 2026-11-07) |
| William Wythers' Overhauled Overworld | Doesn't work well with BWG's biomes (staging, 2026-11-07); Tectonic and Terralith kept instead |
| Lithosphere | Spammed rare biome trees through ordinary forests (staging, 2026-11-07); Tectonic and Terralith kept instead |
| Samurai Dynasty, AzureLib | 0.0.51 (the 1.20.1 build) has no biomes, only 10 yokai mobs, a shrine, a torii and gear. Gregifying its 130-odd recipes kept turning up empty tags in GTO (GT's parts are under `c:`, Forge's under `forge:`), so it was removed (staging, 2026-11-08) |
| Amplified Nether | Removed after the staging trial (2026-11-07). It also wrapped vanilla's nether ore features in an extra `count: 2` (quartz, gold, small debris veins) |
| Macaw's Bridges, Lights, Fences, Stairs | Added to main on 2026-11-07, removed again the same day |
| Chunky | Distant Horizons 3.3.3 calls into Chunky while a new world's spawn chunks generate, before Chunky has started (on `ServerStartingEvent`), so creating a world crashes (staging, 2026-11-07). DH's `chunkGeneratorMode = "INTERNAL_SERVER"` with `SURFACE_THEN_CHUNKS` saves the chunks it generates, which does the pregen instead |

## Sources

- Modrinth API `v2/search` and `v2/project/<slug>/version` (Forge, 1.20.1), 2026-11-07
- dev27's `mods/` jars and their `META-INF/mods.toml`
- The Cosmic Frontiers notes from `Warpledge/nixos-config-old-private` (deleted 2026-04-26)
