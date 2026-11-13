# Quark Blocks

A Forge 1.20.1 mod holding the Quark blocks that the Integrated structure mods build
with, for GregTech Odyssey, where Quark itself breaks EMI's recipe bake
([candidates.md](../../0.6.0/candidates.md#integrated-mods)). Its mod id is
`quarkblocks`, not `quark`: Supplementaries, Amendments and Create load Quark compat code
when a mod called `quark` is present, and that code needs Quark's classes.

## Building

```bash
python3 -I build.py <Quark jar> <mods folder> [--zeta <Zeta jar>]
```

`build.py` runs `gen.py`, then Gradle 8 with JDK 17 through `nix-shell`, and copies
`build/libs/quarkblocks-<version>.jar` into the mods folder. Then rerun
[libgate.py](../libgate.py), which renames the structures' Quark blocks to these.

To check the mod loads, `gradle runServer` in `nix-shell -p jdk17 gradle_8` starts a bare
Forge server with only this mod in `run/` (gitignored); with `enable-rcon` in its
`server.properties`, `setblock` and `execute if block` over RCON test block behaviour.

`gen.py` reads the Integrated mods' jars in the mods folder for every Quark id they name,
skips the two ids [quarkmap.py](../quarkmap.py) turns into vanilla blocks (current Quark
lacks them), and writes `src/generated/resources/`: `blocks.json` and Quark's
blockstates, models, textures (chest and sign faces too), names, block loot tables and
vanilla block tags, renamed to `quarkblocks:`.

## What's in it

- 515 blocks. Each block uses a vanilla class where Quark's shape is a vanilla one
  (slabs, stairs, walls, panes, fences, doors, leaves, clusters). Hedges, posts,
  vertical slabs, stools and leaf carpets are ports of Quark's classes: hedges join
  hedges, posts join chains, hanging lanterns and other posts, stools seat a player and
  grow tall under a block, and the cut copper vertical slabs weather, scrape and wax (all
  eight, so each stage exists). `PropsBlock` covers the rest (pipes, rods, potted plants)
  with the properties of Quark's current blockstate.
- Hedges, leaf carpets and myalite are tinted as in Quark: hedges and carpets copy their
  leaves' colour, myalite's hue drifts with position.
- Quark's storage keeps the structures' loot: wood and stone chests and trapped chests
  (`quarkblocks:variant_chest`, `variant_trapped_chest`), the deepslate and blackstone
  furnaces (the blackstone one burns with soul fire on soul sand or soil), the 640-item
  crate with its scrolling screen, and the blossom sign. The block entity ids are
  Quark's, so the templates' chest loot tables, furnace contents and crate `stacks`
  load as they are. The sign joins vanilla's sign block entity type by reflection, as
  Zeta does; `META-INF/accesstransformer.cfg` has the one access Quark's code needs.
- Block properties (sound, strength, map colour) are copied from a similar vanilla
  block. The copy list in `gen.py` avoids blocks whose light or other functions read
  their own properties, which these blocks don't have.
- Quark's machines the structures use work: the feeding trough (animals within 10 blocks
  walk to it, eat and sometimes breed; Quark lures them with mixins, this with a tick
  event), copper pipes (carry items, with the items and flared ends drawn), the ender
  watcher, the chute and the redstone randomizer. The crafter and tiny potato keep their
  look, and their block entity keeps the template's data and drops its items when broken.
  The iron rod is decorative.
- 28 of Quark's items, working: shards, music discs (loop in a jukebox), crab leg and
  shell, soul bead (points to a nether fortress), moss paste, forgotten hat, ancient
  fruit, parrot eggs, abacus, trowel, slime in a bucket, bottled cloud, seed pouch,
  pathfinder's quill, ancient tome, pickarang, torch arrow and the rune template. Runes
  apply on a smithing table and show in the tooltip, but the glint stays purple:
  colouring it needs Quark's render mixins. Older templates' coloured runes become the
  rune template (`quarkmap.OLD_ITEMS`). `items.json` lists them for the mod, as
  `blocks.json` does the blocks. The diamond heart is a plain item: in Quark it makes a
  stoneling, which isn't ported.
- Quark's entities under Quark's ids, so templates, spawners and the structures' spawn
  lists keep them: glass item frames, wraiths, forgotten, foxhounds, crabs and
  toretoises, with Quark's models, AI, sounds, loot and spawn eggs (`entities.json`
  lists their sounds). They come from structures only; Quark's own natural spawns are
  left out.
- Quark's recipes for the blocks and items here, minus any for a vanilla item (GT owns
  those) or naming something missing. Machines' and items' recipes take GT plates for
  vanilla metals and diamonds (`RECIPE_GREG` in `gen.py`), as `gregify.py` does for
  other mods' gear.
- The monster box, reimplemented with Quark's defaults: a player within 2.5 blocks wakes
  it, it smokes for 2 seconds, spawns 5 to 8 mobs from `misc/monster_box_spawns` and
  breaks; mobs it spawned drop `misc/monster_box` when a player kills them.

## Licence

Quark is by Vazkii and contributors, under
[CC BY-NC-SA 3.0](https://github.com/VazkiiMods/Quark/blob/master/LICENSE.md). This mod
adapts its blocks, models, textures, loot tables and code (the classes it ports name
their Quark original): blocks renamed from `quark:` to `quarkblocks:`, config values
fixed at Quark's defaults.
It is under the same licence, non-commercial, and not made or endorsed by Quark's
authors. Quark's files are copied in at build time and kept out of git
(`.gitignore`); only the code here is in the repo.
