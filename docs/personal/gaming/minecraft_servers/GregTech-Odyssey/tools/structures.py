#!/usr/bin/env python3
"""List the pack's structure sets and structures, and write Structurify's config.

Usage:
    python3 -I <this file> sets <instance>         every structure set and its spread
    python3 -I <this file> structures <instance>   every structure and its terrain fit
    python3 -I <this file> write <instance>        config/structurify.json (Prism closed)

An instance is a folder name under Prism's instances/ or a path, as for gto.py. The
scan reads the mods' jars, then the Open Loader packs (the Integrated reskins win
there), so it shows each set as the game loads it, before Structurify. `write` builds
the whole config from the tables below; rerun it after adding or updating a structure
mod, then test in staging. Structurify's in-game screen didn't save (2026-11-08), so
the tables here are the source. 0.6.0/structure-spacing.md explains the choices.
"""

import argparse
import json
import re
import sys
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gto  # noqa: E402

#-- Tables

# Sets thinned by hand: (spacing, separation) in chunks. These win over the tiers.
SPREAD = {
    "ae2:meteorite": (55, 14),
    "dungeoncrawl:dungeons": (55, 21),
    # Vanilla's bastions: Incendium (16/8) and Jaden's (27/4) both override the set
    "minecraft:nether_complexes": (27, 4),
    # Nullscape already thins End cities from vanilla's 20/11; the tier would add 3x
    "minecraft:end_cities": (26, 18),
}
# Tiers for every other set by its own spacing: (below this spacing, factor). Rarity
# goes with spacing squared, so x1.73 is 3x rarer and x1.41 2x. 40 and up stay.
TIERS = [(30, 3 ** 0.5), (40, 2 ** 0.5)]
# Sets that keep their own spread: terrain decor (BWG, Terralith rubble and
# underground rooms, Jaden's Nether fossils, MES pillars and spikes), small
# dungeons, mineshafts, way signs, the Nether fortress
# (blaze rods), and Ad Astra's planets (prefix).
KEEP = {
    "biomeswevegone:dripstone_arches", "biomeswevegone:lush_arch",
    "biomeswevegone:red_rock_arches", "biomeswevegone:sharpened_rocks",
    "biomeswevegone:rugged_fossils", "biomeswevegone:ironwood_gour_plateau",
    "biomeswevegone:large_cold_lake",
    "terralith:rubble", "terralith:underground", "terralith:underground_dungeon",
    "betterdungeons:small_dungeons", "betterdungeons:small_nether_dungeons",
    "bettermineshafts:mineshafts", "supplementaries:way_signs",
    "legendary_monsters:warped_fungussus_nest", "betterfortresses:fortress",
    "netherexp:mega_fossils", "mes:ruined_pillar", "mes:enderpin_spikes",
}
KEEP_PREFIX = ("ad_astra:",)
# Small or common structures left out of overlap prevention so they never cancel a
# large or rare one: everything in the decor sets above plus these vanilla ones. The
# stronghold is here so Eyes of Ender always resolve.
NO_OVERLAP_SETS = KEEP - {"betterfortresses:fortress"}
NO_OVERLAP = [
    "minecraft:mineshaft", "minecraft:mineshaft_mesa", "minecraft:stronghold",
    "minecraft:buried_treasure", "minecraft:nether_fossil",
] + [f"minecraft:ruined_portal{s}" for s in
     ("", "_desert", "_jungle", "_swamp", "_mountain", "_ocean", "_nether")]
# Mods whose structures never generate. Maid Spell's loot and mobs name Iron's Spells
# items, which the pack lacks, so its dungeons would be empty.
DISABLED_NAMESPACES = ["touhou_little_maid_spell"]

#-- Scan

SET_RX = re.compile(r"data/([^/]+)/worldgen/structure_set/(.+)\.json$")
STRUCT_RX = re.compile(r"data/([^/]+)/worldgen/structure/(.+)\.json$")


def scan(mc, rx):
    """{id: (json, source)} for every file rx matches; Open Loader packs win."""
    found = {}

    def add(name, raw, src):
        m = rx.search(name)
        if not m:
            return
        # Minecraft's lenient reader takes raw tabs and // comment lines.
        text = re.sub(r"^\s*//.*$", "", raw.decode(), flags=re.M)
        try:
            found[f"{m[1]}:{m[2]}"] = (json.loads(text, strict=False), src)
        except ValueError:
            pass

    for jar in sorted((mc / "mods").glob("*.jar")):
        try:
            z = zipfile.ZipFile(jar)
        except zipfile.BadZipFile:
            continue
        for n in z.namelist():
            add(n, z.read(n) if rx.search(n) else b"", jar.name)
    ol = mc / "config" / "openloader" / "data"
    for p in sorted(ol.rglob("*.json")) if ol.is_dir() else []:
        add(str(p), p.read_bytes(), "openloader:" + p.relative_to(ol).parts[0])
    return found


def sets(mc):
    out = []
    for k, (d, src) in sorted(scan(mc, SET_RX).items()):
        pl = d.get("placement", {})
        out.append({
            "set": k, "src": src, "type": pl.get("type", "?").split(":")[-1],
            "spacing": pl.get("spacing"), "separation": pl.get("separation"),
            "frequency": pl.get("frequency"),
            "structures": [s.get("structure") if isinstance(s, dict) else s
                           for s in d.get("structures", [])],
        })
    return out

#-- Config


def spread(s):
    """(spacing, separation) Structurify should set for one set, or None to keep it."""
    k, sp, se = s["set"], s["spacing"], s["separation"]
    if k in SPREAD:
        return SPREAD[k]
    if k in KEEP or k.startswith(KEEP_PREFIX) or not sp or s["type"] == "concentric_rings":
        return None
    for below, f in TIERS:
        if sp < below:
            new = round(sp * f)
            return new, min(round(se * f), new - 1)
    return None


def config(all_sets):
    by = {s["set"]: s for s in all_sets}
    missing = [k for k in list(SPREAD) + sorted(NO_OVERLAP_SETS) if k not in by]
    if missing:
        sys.exit(f"not in the pack any more, update the tables: {', '.join(missing)}")
    no_overlap = set(NO_OVERLAP)
    for k in NO_OVERLAP_SETS:
        no_overlap.update(by[k]["structures"])
    spreads = [(s["set"], r) for s in all_sets
               if s["set"].split(":")[0] not in DISABLED_NAMESPACES and (r := spread(s))]
    return {
        "general": {"prevent_structure_overlap": True, "overlap_padding": 0},
        "structure_namespaces": [{"name": n, "is_disabled": True}
                                 for n in DISABLED_NAMESPACES],
        "structures": [{"name": n, "exclude_from_overlap_prevention": True}
                       for n in sorted(no_overlap)],
        "structure_sets": [{"name": k, "override_global_spacing_and_separation_modifier": True,
                            "spacing": sp, "separation": se} for k, (sp, se) in spreads],
        "structure_template_pools": [],
    }

#-- Commands


def cmd_sets(mc):
    for s in sets(mc):
        new = spread(s)
        to = f"-> {new[0]}/{new[1]}" if new else ""
        print(f'{s["set"][:52]:52} {s["type"][:14]:14} {s["spacing"]}/{s["separation"]} '
              f'{to:10} n={len(s["structures"]):<3} [{s["src"][:30]}]')


def cmd_structures(mc):
    for k, (d, src) in sorted(scan(mc, STRUCT_RX).items()):
        b = d.get("biomes")
        b = b if isinstance(b, str) else ",".join(b) if isinstance(b, list) else "?"
        adapt = d.get("terrain_adaptation", "none")
        # No terrain adaptation on a surface structure is what can leave it floating;
        # Integrated API types check terrain height themselves.
        flag = ("  <- no terrain fit" if adapt == "none" and d.get("step") == "surface_structures"
                and not d.get("type", "").startswith("integrated_api:") else "")
        print(f'{k[:50]:50} {d.get("type", "").split(":")[-1][:18]:18} '
              f'{d.get("step", "")[:22]:22} {adapt[:10]:10} {b[:50]}{flag}')


def cmd_write(mc):
    cfg = config(sets(mc))
    out = mc / "config" / "structurify.json"
    out.write_text(json.dumps(cfg, indent=2) + "\n")
    print(f"wrote {out}: {len(cfg['structure_sets'])} sets respaced, "
          f"{len(cfg['structures'])} structures out of overlap prevention")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("command", choices=["sets", "structures", "write"])
    ap.add_argument("instance")
    a = ap.parse_args()
    mc = gto.game_dir(gto.instance(a.instance))
    {"sets": cmd_sets, "structures": cmd_structures, "write": cmd_write}[a.command](mc)


if __name__ == "__main__":
    main()
