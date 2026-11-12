# Structure Spacing

With about 130 structure sets from 20-odd mods, structures overlapped, and a biome
could hold ten of them, because every set places on its own grid. Since 2026-11-12
Structurify 2.0.43 stops overlaps and thins the common sets while the rare ones keep
their spacing. A global rarity change was ruled out, since it would push the rare
Integrated structures further out too.

## How It's Set Up

[tools/structures.py](../tools/structures.py) writes `config/structurify.json` from its
tables; nothing is set in the game. Structurify's in-game screen didn't save on
2026-11-08, so the script is the source, and `overlay.json` carries the file to new
builds.

```bash
python3 -I tools/structures.py sets <instance>        # every set: spread now -> after
python3 -I tools/structures.py structures <instance>  # every structure: step, terrain fit
python3 -I tools/structures.py write <instance>       # rewrite the config (Prism closed)
```

Structurify reads the config at startup, so restart the game after a write. The keys
it uses, read from its serializers (2.0.43):

| Key | Where | Set to |
| --- | --- | --- |
| `prevent_structure_overlap` | `general` | `true` |
| `overlap_padding` | `general` | `0` chunks; raise to 1 if structures still touch |
| `exclude_from_overlap_prevention` | an entry in `structures` | `true` for the small ones below |
| `override_global_spacing_and_separation_modifier`, `spacing`, `separation` | an entry in `structure_sets` | the new spread |

Not used: the global spacing modifier, biome checks, and the flatness check (see
[Floating structures](#floating-structures)).

## Spacing

Spacing is the average distance in chunks between structures of one set, separation
the minimum. Rarity goes with spacing squared, so spacing x1.41 is 2x rarer and x1.73
is 3x. `structures.py` applies tiers by each set's own spacing, keeping separation in
the same ratio:

| Own spacing | Change | Examples (2026-11-12) |
| --- | --- | --- |
| under 30 | 3x rarer (x1.73) | Illager Invasion sorcerer hut 18 to 31, IDAS common 21 to 36, Mowzie's sets 25 to 43, Apotheosis towers 26 to 45, Integrated Villages 26 to 45, IDAS small 26 to 45, Terralith regular 27 to 47 |
| 30 to 39 | 2x rarer (x1.41) | YUNG's desert temples and witch huts 30 to 42, Dungeons Arise minor 30 to 42, BOMD Lich Tower and Gauntlet 32 to 45, BWG villages 34 to 48, Legendary Monsters' mossy temple 35 to 49 |
| 40 and up | unchanged | Dungeons Arise major (40), IDAS rare (45), Cataclysm's bosses (50 to 112), Collapsed Kingdom (110), airship villages (115), Born in Chaos (60 to 200) |

Set by hand, ahead of the tiers: AE2 meteorites 32 to 55 (3x rarer) and Dungeon Crawl 32
to 55 (3x), both seen far too often. Two vanilla sets are pinned so a mod's file can't
change them: bastions (`minecraft:nether_complexes`) at vanilla's 27/4, since Incendium
(16/8) and Jaden's (27/4) both override the set and load order would pick, and End
cities at Nullscape's 26/18, already sparser than vanilla's 20/11.

Kept as they are: terrain decor (BWG arches, rocks, fossils, gour plateaus and cold
lakes, Terralith rubble and underground rooms, Jaden's Nether fossils, MES pillars and
spikes), YUNG's small dungeons and mineshafts, way signs, the warped fungussus nest,
the Nether fortress (blaze rods), and Ad Astra's planets. 42 sets were respaced on
2026-11-12, 63 after the Nether and End batch the same day.

The tiers also reach other mods' placement types: on 2026-11-12 `/locate` put the
nearest tavern village (Integrated API placement) 2,027 blocks out in
staging, against about 1,000 before.

## Overlap

With overlap prevention on, the structure that generates second is dropped. A small
structure could then cancel a rare one, so these are left out of the check (48
structures on 2026-11-12): everything in the decor sets above, vanilla mineshafts,
buried treasure, ruined portals and Nether fossils, and the stronghold, so Eyes of Ender
always lead to one.

`/locate` reads the placement grid and doesn't run the overlap check, so a structure it
names can turn out to have been dropped when you get there.

## Adding a Structure Mod

1. Add the mod to staging, then run `structures.py sets` on it. Its sets show with
   their spread and the `->` the tiers give them; `structures` shows which of its
   structures have no terrain fit.
2. Check the new sets against the tiers: a mod with one big boss structure at spacing 30
   should probably keep it (add the set to `KEEP`), and a very common one may need a
   hand value in `SPREAD`.
3. Add its small pieces (rocks, ruins, signs) to `KEEP` so they aren't respaced, which
   also leaves them out of overlap prevention.
4. Run `structures.py write` on staging, restart, and test in chunks nobody has
   generated (`/tp @s 30000 200 30000`): `/locate` its structures and fly over a few.
5. Copy the jar to main, run `write` on main, and commit the tables with the mod.

## Things to Know

- Only chunks generated after a change are affected; the explored world keeps its
  structures, and one crossing the edge of explored land can come out cut.
- One set shares one spread: IDAS puts 29 buildings in `idas:idas_common`, so they
  can't be thinned one by one.
- An Integrated reskin replaces its base mod's set file; the scan shows the Open Loader
  pack as the source, and that's the file the game uses.
- `structures.py` exits naming any table entry that's gone from the pack, after a mod
  is removed or renames a set.

## Floating Structures

A flatness check (Structurify cancels a structure over uneven ground, water or
air) only helps structures with no terrain fit, and on 2026-11-12 nearly all land
structures had one (beard or bury) or were Integrated API types, which check terrain
height themselves. Most of the 31 without are meant to sit on water or in the air
(ships, the Heavenly airships, Acropolis, Terralith's spire, witch huts on stilts). A
global check was tried on 2026-11-08 and removed the same day.

The Legendary Monsters castle seen floating at spawn on 2026-11-12 was the Collapsed
Kingdom: its dungeon pieces are mostly saved air (about 27,000 blocks in the arena
piece), which carve out the ground under the castle as they place. A flatness check
wouldn't stop that.

## Sources

- Structurify's [Modrinth page](https://modrinth.com/mod/structurify), read 2026-11-12,
  and the 2.0.43 jar's serializers and language file for the key names
- Spreads from each mod's own `worldgen/structure_set` files, via `structures.py sets`
