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
| `overlap_padding` | `general` | `1` chunk (`OVERLAP_PADDING`, 0 until 2026-11-15) |
| `exclude_from_overlap_prevention` | an entry in `structures` | `true` for the small ones below |
| `override_global_spacing_and_separation_modifier`, `spacing`, `separation` | an entry in `structure_sets` | the new spread |

Not used: the global spacing modifier, biome checks, and the flatness check (see
[Floating structures](#floating-structures)).

## Spacing

Spacing is the average distance in chunks between structures of one set, separation
the minimum. Rarity goes with spacing squared, so spacing x1.41 is 2x rarer and x1.73
is 3x. Since 2026-11-15 `structures.py` picks each set's rarity from `RARITY`, by set
id and then by mod, and falls back to tiers by its own spacing for any set not
listed. Separation keeps the same ratio:

| Group (`RARITY`) | Change | Spread (2026-11-15) |
| --- | --- | --- |
| Bosses and progression: Mowzie's, BOMD, Cataclysm, Legendary Monsters, Dungeons Arise major, IDAS rare | own spread | Mowzie's 25/8, BOMD Lich Tower and Gauntlet 32/16, Cataclysm desert structures 30/20, Dungeons Arise major 40/30 |
| Villages: Integrated Villages, BWG, Terralith rare | 5x rarer (x2.24) | Integrated Villages 26 to 58, BWG villages 34 to 76, Terralith rare villages 46 to 103 |
| YUNG's desert and jungle temples and witch huts | own spread | desert temples 30/20, jungle temples 24/8, witch huts 30/8. They replace vanilla structures locked to one biome, which are far apart already, and the temples hold End Remastered's Old and Rogue eyes, needed for the End at LuV |
| Filler: IDAS common and small, Dungeons Arise minor, Apotheosis towers, Illager Invasion's firecaller and sorcerer huts, Terralith regular | 6x rarer (x2.45) | sorcerer hut 18 to 44, IDAS common 21 to 51, Apotheosis towers 26 to 64, Terralith regular 27 to 66, Dungeons Arise minor 30 to 73, firecaller hut 42 to 103 |

| Unlisted, own spacing | Change | Examples |
| --- | --- | --- |
| under 30 | 6x rarer (x2.45) | MES's End structures 25 to 61, Youkai's Hakurei Shrine 24 to 59 |
| 30 to 39 | 3x rarer (x1.73) | Ars Nouveau's wilden den 36 to 62, Incendium greater 30 to 52 |
| 40 and up | unchanged | ocean monuments (50), airship villages (115), Born in Chaos (60 to 200) |

The groups replaced plain tiers, which also made the boss structures 3x to 6x rarer
(a Mowzie's set at 61) and left the firecaller hut alone.

On 2026-11-15 the tiers went from 3x and 2x to 6x and 3x, after a desert showed about
15 structures in view: a desert can hold about 20 sets (IDAS camps, markets and ruins,
Terralith outposts, Dungeons Arise, Cataclysm, villages), each on its own grid. A
9x/6x/3x trial the same day was far too sparse (a cottage 2,020 blocks out, a Mowzie's
monastery 30,705), since a set with many structures or narrow biomes is already far
apart for any one structure. The unchanged Cataclysm cursed pyramid (desert only,
80/50) was 16,938 blocks out in that world, so desert-only structures are far anyway.
`/locate` a whole set where one exists (`integrated_villages:village_here`) rather
than one building of it.

Set by hand, ahead of the tiers: AE2 meteorites 32 to 78 (6x rarer) and Dungeon Crawl 32
to 78 (6x), both seen far too often. Two vanilla sets are pinned so a mod's file can't
change them: bastions (`minecraft:nether_complexes`) at vanilla's 27/4, since Incendium
overrides the set at 16/8 (Jaden's, removed 2026-11-15, set 27/4 too), and End
cities at Nullscape's 26/18, already sparser than vanilla's 20/11.

Kept as they are: terrain decor (BWG arches, rocks, fossils, gour plateaus and cold
lakes, Terralith rubble and underground rooms, MES pillars and
spikes), YUNG's small dungeons and mineshafts, way signs, the warped fungussus nest,
the Nether fortress (blaze rods), and Ad Astra's planets. 42 sets were respaced on
2026-11-12, 63 after the Nether and End batch the same day, 79 with the 6x and 3x
tiers on 2026-11-15, and 49 with the `RARITY` groups the same day.

The spreads also reach other mods' placement types: on 2026-11-12 `/locate` put the
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
2. Check the new sets against the tiers, and put the mod or its sets in `RARITY`'s
   groups: boss and progression structures at 1, villages at 5, filler at 6. A very
   common one may need a hand value in `SPREAD`.
3. Add its small pieces (rocks, ruins, signs) to `KEEP` so they aren't respaced, which
   also leaves them out of overlap prevention. A mod whose structures shouldn't
   generate at all, such as one whose loot names a mod the pack lacks (Maid Spell's,
   built for Iron's Spells), goes in `DISABLED_NAMESPACES` (Structurify's
   `is_disabled` on its namespace).
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
