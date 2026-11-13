# GTO 0.6.0 Mod Candidates (from Cosmic Frontiers)

The 105 mods added by hand to the Cosmic Frontiers 0.8.0 pack in 2026-04, sorted by how
risky each would be in GTO 0.6.0-dev27. Checked 2026-11-07 against dev27's mod list and
each mod's newest 1.20.1 Forge build on Modrinth, including its required dependencies.
The recovered Cosmic Frontiers notes, with the config and KubeJS work done back then,
are in `~/Downloads/cosmic_frontiers_notes/`.

**Needs** lists only required mods that dev27 doesn't ship. "CurseForge only" means the
lookup found no 1.20.1 Forge build on Modrinth. Pick a batch, check it against
[internals/new-mod-checklist.md](./internals/new-mod-checklist.md), then trial it with
`gto stage` as described in [updating.md](./updating.md).

## Integrated mods

**Batches 1 and 2 are in main since 2026-11-12, without Quark** (minus Integrated
Stronghold); [mods.md](./mods.md#integrated-structures-2026-11-12) has what went in and
how. Batch 3 went in on 2026-11-12 too. The first try (2026-11-07) was dropped when EMI
broke; what the retry found, layer by layer in staging:

- **Quark breaks EMI on its own.** gtolib replaces EMI's recipe index with native code,
  which passes a null to `ArrayList.addAll`. Quark 4.0-462 with Zeta 1.0-31 does it
  even with all ten categories off, Zeta's creative tab appends forced and its hiding
  off. Retried on 2026-11-13 with [emiguard](../tools/emiguard/README.md): no recipe EMI
  hands the index is malformed (no null lists, no stacks changing once indexed, no
  unregistered categories). Zeta alone loads; Quark without Supplementaries (whose
  Quark compat loads with it) and the Integrated mods still fails. The
  one structural change Quark makes is that GT's 19 furnaces drop out of
  `minecraft:smelting`'s workstations (GT adds them in
  `GTRecipeEMICategory.registerWorkStations` only for a furnace category marked visible),
  so the cause is in GTO's own handling of GT's furnace category with `quark` loaded,
  out of reach without GTO's source. Alex's Mobs fails with the same trace
  ([Skip](#skip)), for another reason.
- KubeJS and Rhino weren't needed: Reliable Remover and Reliable Recipes do the bans as
  JSON. Create, Moonlight, Supplementaries and Amendments each passed alone.
- IDAS, Integrated Dungeons Arise and Seven Seas require Quark in `mods.toml` but have no
  code calling it, and their 703 templates place 509 Quark block types. Those blocks
  went into a jar of their own (`quarkblocks`), with the requirement patched out.
- Integrated Dungeons Arise reskins When Dungeons Arise at the same 381 template and 225
  data paths and doesn't require it, so which file loads is arbitrary. Mixed, the
  structures' spawners came out empty; the pack now carries all of IDA's data.
- Integrated Stronghold's 61 templates hold 4,529 block entities (about 570 Create
  gearboxes, water wheels and shafts, about 500 banners) and 7,583 lava blocks; it
  dropped the frame rate from about 160 to 20 with shaders, so it stayed out.
- Doubling the structures' spacing put the nearest Collectors Museum 16,000 blocks out;
  their own spacing stays. Overlap with other structure mods (a Keep Kayra mostly cut
  away by a neighbour) is what Structurify handles since 2026-11-12
  ([structure-spacing.md](./structure-spacing.md)).
- Integrated Villages 1.3.2 lists a `swamp_village` it doesn't ship, which makes the
  whole `#minecraft:village` tag fail to load; the pack's tag makes every entry optional.

The best structure mods from the Cosmic Frontiers testing. All 11 have 1.20.1 Forge
builds (Modrinth, 2026-11-07). 8 of them build their structures from Create, Quark and
Supplementaries blocks, so those three come in as block libraries: their blocks stay
registered for the structures, while their machines and recipes are removed and hidden.
Create is listed as compatible with GTO on the pack's site but has no integration.

| Batch | Mods | Needs from outside dev27 |
| --- | --- | --- |
| 1 (in main) | Integrated API 1.9.2, Integrated Patches 1.2.0 | none |
| 2 (in main, without Stronghold) | IDAS 1.13.0, Integrated Villages 1.3.2, Integrated Stronghold 1.1.1, Integrated Dungeons Arise 2.1.3, Integrated Seven Seas 1.0.0 | Create, Supplementaries, Amendments, Moonlight, Reliable Remover and Recipes, the quarkblocks jar in place of Quark |
| 3 (in main) | Integrated Cataclysm 1.0.5, Integrated Mowzie's Mobs 1.3.2, Integrated Bosses of Mass Destruction 1.0.0, Integrated Simply Swords 1.3.1 | Each one's base mod: L_Ender's Cataclysm (Lionfish API), Mowzie's Mobs, Bosses of Mass Destruction (Cerbon's API), Simply Swords |

- Integrated Stronghold's last 1.20.1 build is from 2024-03, and Bosses of Mass
  Destruction's from 2024-01; the rest were updated in 2026.
- Integrated Seven Seas runs without WDA: Seven Seas (2026-11-12).
- Modrinth's dependency lists come from the authors and can be wrong: Integrated
  Villages lists none, but its jar's `mods.toml` makes Create and Supplementaries
  mandatory. Read each jar's `mods.toml` when it's added.
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
mods failed, and the four Macaw's mods, AmbientSounds, Sounds, Particular and Particle
Core came out again; all are under
[Skip](#skip).

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
| Particular | | **Added again 2026-11-12** with Leaves Be Gone and Better Advancements (removed the same day: GTO loads no advancements) ([mods.md](./mods.md#advancements-and-qol-2026-11-12)) |
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
| Tectonic, Terralith | Lithostitched | Added to main on 2026-11-08. Tectonic came out the same day for slow generation and went back in with FastChunkGen ([mods.md](./mods.md)). dev27's BWG is cut to 48 biomes (Cosmic Frontiers' 11 plus 37 more) in `config/biomeswevegone/world_generation.json`, and its three region weights go from 8 to 2: at 8 they outweighed the vanilla region (10, where Terralith's biomes live) and the world came out mostly BWG, and at 1 BWG was about 1% of visited chunks. Carry those files and `config/terrablender.toml` (`overworld_region_size` 4) to main. Terralith can't be removed from a world later |
| Luki's Grand Capitals, Luki's Woodland Mansions | | |
| Structure Essentials | | Spacing control; CurseForge only. Not needed while Structurify does the job ([structure-spacing.md](./structure-spacing.md)) |
| Mowzie's Mobs | | **Added 2026-11-12** with Integrated Mowzie's Mobs and Mowzie's Cataclysm; nothing gregified, its gear needs boss drops |
| L_Ender's Cataclysm | Lionfish API | **Added 2026-11-12** with Integrated Cataclysm; its gear needs boss drops, so only the vanilla-metal recipes were gregified ([mods.md](./mods.md#recipe-overrides)) |
| Cataclysm & BetterCombat Compat | | Compat for the mods above; add only with them. Mowzie's Cataclysm went in with Mowzie's Mobs. Simply Swords: Cataclysm is in [Skip](#skip) |

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
| Quark, Zeta | Breaks EMI's recipe bake inside gtolib even with every Quark category off (staging, 2026-11-11; retried with emiguard 2026-11-13, cause inside GTO's code, see [Integrated mods](#integrated-mods)); [the Integrated mods](#integrated-mods) get its blocks from the quarkblocks jar instead |
| Cupboard | Only a library for the someaddons mods, none of which are on this list |
| Simply Swords: Cataclysm 1.0.1 | Its Forge 1.20.1 builds (1.0.1, 2025-12) target Simply Swords 1.56.0 and call its `ConfigDefaultValues`, which 1.70.0's new config system removed; registration fails and the game won't start (staging, 2026-11-12) |
| Simply Swords Overhaul | Its last builds (1.0.2 on Modrinth, 1.0.3 and 1.0.4 on GitHub, 2025) target Simply Swords 1.56.0; with 1.70.2 its `StormsEdgeSwordItem` mixin finds no target and the game won't start |
| Nether Remastered | Checks its own `nether_remastered:seal_of_the_underworld` advancement every player tick; GTO's AdvancementNoMore removes all advancements, so it crashes on joining a world (staging, 2026-11-07). AdvancementNoMore has been off since 2026-11-12, but it's still skipped: it cancels any travel to the Nether until its seal is used, which would also block GTO's Nether Reactor Core, and GTO already gates the Nether at HV. It adds no terrain or structures (checked 2026-11-12) |
| Moog's Nether Structures, Moog's Soaring Structures | Moog's Structure Lib 3.4.2's required `TagLoaderMixin` can't inject into `TagLoader`, which gtolib's own `TagLoaderMixin` (priority 2000) rewrites; the game crashes at world creation (staging, 2026-11-07). 3.1.2, the last without the mixin, runs MES fine ([mods.md](./mods.md#nether-and-end-2026-11-12)); these two weren't retried on it |
| YUNG's Better Strongholds | Replaces the stronghold eyes of ender lead to; dev27's End Remastered patches stronghold pieces for its own eyes and portal frames, which gate the End |
| Diagonal Walls, Windows, Fences | Their `diagonalblocks` 8.0.6 throws `target block tags not empty` on the second tag reload (staging, 2026-11-07): the first world loads, but EMI never gets its data, and leaving to the title and loading or creating any world crashes |
| Alex's Mobs 1.22.9, Citadel 2.6.3, Domestication Innovation 1.7.1, Alex's Mobs Interaction, Alex's Delight | With Alex's Mobs and Citadel on, EMI's reload fails every time with a `NullPointerException` in gtolib's recipe baking; with them off it loads (staging, 2026-11-08). **Back since 2026-11-12** as Alex's Mobs Continued with its brewing patched, plus Citadel, Domestication Innovation and Continued Delight ([mods.md](./mods.md#alexs-mobs-continued-2026-11-12)); Interaction wasn't retried |
| Celestisynth 1.3.4 | Dropped after a look in staging (2026-11-08). Its `RecipeManagerAccessor` mixin also clashes with ExtendedAE's, and its spellbook needs Iron's Spellbooks (in main since 2026-11-12; Celestisynth wasn't retried) |
| YUNG's Cave Biomes | Worldgen crashed on a chest or pod placed `facing=down` (in `MonsterRoomFeature` and Ars Nouveau trees); the other YUNG's structure mods load fine without it (staging, 2026-11-08) |
| Biomes O' Plenty | Shares 8 wood names with BWG, so GTO generates duplicate GT recipe ids (e.g. `gtceu:lathe/strip_willow_log`) and EMI fails to load (staging, 2026-11-07) |
| William Wythers' Overhauled Overworld | Doesn't work well with BWG's biomes (staging, 2026-11-07); Terralith kept instead |
| Lithosphere | Spammed rare biome trees through ordinary forests (staging, 2026-11-07); Terralith kept instead |
| Samurai Dynasty, AzureLib | 0.0.51 (the 1.20.1 build) has no biomes, only 10 yokai mobs, a shrine, a torii and gear. Gregifying its 130-odd recipes kept turning up empty tags in GTO (GT's parts are under `c:`, Forge's under `forge:`), so it was removed (staging, 2026-11-08) |
| Amplified Nether | Removed after the staging trial (2026-11-07). It also wrapped vanilla's nether ore features in an extra `count: 2` (quartz, gold, small debris veins) |
| Macaw's Bridges, Lights, Fences, Stairs | Added to main on 2026-11-07, removed again the same day |
| AmbientSounds | Added to main on 2026-11-07, removed on 2026-11-08 |
| Sounds, MRU, Particle Core | Added to main on 2026-11-07, removed on 2026-11-08 with Particular, which came back on 2026-11-12. YACL, added for Sounds and MRU, is still in |
| Structurify 2.0.43, global flatness check | Added to main on 2026-11-08 with a global flatness check (structures skip steep ground), removed the same day for a reason not recorded. Its in-game screen didn't save. **Back since 2026-11-12** without the flatness check ([structure-spacing.md](./structure-spacing.md)) |
| spark 1.10.53 | Added to main on 2026-11-12 and removed the same day: leaving a world and loading another in the same session crashes the client, because dev27's FastEvents keeps calling spark's permission listener after spark unregisters it (`NullPointerException` in `ForgeServerSparkPlugin.onPermissionGather`, staging) |
| From the Fog Reimagined's mods | Its horror mods (stalkers, horror structures and biomes, ambience) were looked at on 2026-11-12 and none are wanted |
| Chunky | Distant Horizons 3.3.3 calls into Chunky while a new world's spawn chunks generate, before Chunky has started (on `ServerStartingEvent`), so creating a world crashes (staging, 2026-11-07). DH's `chunkGeneratorMode = "INTERNAL_SERVER"` with `SURFACE_THEN_CHUNKS` saves the chunks it generates, which does the pregen instead |

## Sources

- Modrinth API `v2/search` and `v2/project/<slug>/version` (Forge, 1.20.1), 2026-11-07
- dev27's `mods/` jars and their `META-INF/mods.toml`
- The Cosmic Frontiers notes from `Warpledge/nixos-config-old-private` (deleted 2026-04-26)
