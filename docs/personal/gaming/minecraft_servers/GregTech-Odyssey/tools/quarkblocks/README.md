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
skips the ones [quarkmap.py](../quarkmap.py) turns into vanilla blocks (variant chests,
furnaces, crate, sign), and writes `src/generated/resources/`: `blocks.json` and Quark's
blockstates, models, textures, names, block loot tables and vanilla block tags, renamed
to `quarkblocks:`.

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
- Block properties (sound, strength, map colour) are copied from a similar vanilla
  block. The copy list in `gen.py` avoids blocks whose light or other functions read
  their own properties, which these blocks don't have.
- Quark's machines (crafter, chute, ender watcher, redstone randomizer, iron rod, pipe)
  keep their look and do nothing. No block has a recipe, so they only come from
  structures.
- The monster box, reimplemented with Quark's defaults: a player within 2.5 blocks wakes
  it, it smokes for 2 seconds, spawns 5 to 8 mobs from `misc/monster_box_spawns` and
  breaks; mobs it spawned drop `misc/monster_box` when a player kills them.

## Licence

Quark is by Vazkii and contributors, under
[CC BY-NC-SA 3.0](https://github.com/VazkiiMods/Quark/blob/master/LICENSE.md). This mod
adapts its blocks, models, textures, loot tables and the monster box's behaviour: blocks
renamed from `quark:` to `quarkblocks:`, machines kept for their look only, no recipes.
It is under the same licence, non-commercial, and not made or endorsed by Quark's
authors. Quark's files are copied in at build time and kept out of git
(`.gitignore`); only the code here is in the repo.
