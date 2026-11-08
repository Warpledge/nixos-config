#!/usr/bin/env python3
"""Write the GT recipe overrides for Tom's Simple Storage, Simply Swords and Illager
Invasion into the datapack beside this folder.

Usage:
    python3 -I <this file> <mods folder>

Reads each mod's own recipes from its jar in <mods folder>, keeps every pattern, swaps
the ingredients by the tables below and writes the result to
datapack/warpledge-gto/data/<ns>/recipes/<id>.json, the same path as in the jar, so the
datapack replaces the mod's recipe. Rerun after updating one of these mods. A recipe
not matched by a rule is left to the mod. 0.6.0/mods.md explains the choices.
"""

import json
import re
import sys
import zipfile
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "datapack" / "warpledge-gto"
PACK = {"pack": {"pack_format": 15, "description": "warpledge GTO recipe overrides"}}

VACUUM_TUBE = {"item": "gtceu:vacuum_tube"}
LV_CIRCUIT = {"item": "gtceu:basic_electronic_circuit"}


def tag(name):
    return {"tag": name}

#-- Swap tables

# Tom's Simple Storage at Steam/ULV: wrought iron replaces wood, vacuum tubes replace
# diamonds and glowstone.
TOMS = {
    ("tag", "minecraft:planks"): tag("c:plates/wrought_iron"),
    ("tag", "minecraft:trapdoors"): tag("c:plates/wrought_iron"),
    ("tag", "forge:rods/wooden"): tag("c:rods/wrought_iron"),
    ("tag", "forge:gems/diamond"): VACUUM_TUBE,
    ("item", "minecraft:diamond"): VACUUM_TUBE,
    ("item", "minecraft:glowstone"): VACUUM_TUBE,
}
# Recipes whose planks become bronze instead: the connectors and the wireless terminal.
TOMS_BRONZE = {"inventory_connector", "inventory_cable_connector", "wireless_terminal"}

# The advanced wireless terminal moves from a netherite smithing upgrade to an LV
# crafting recipe; its range is set in toms_storage-server.toml (see mods.md).
ADV_WIRELESS = {
    "type": "minecraft:crafting_shaped",
    "category": "misc",
    "key": {
        "E": {"item": "gtceu:lv_emitter"},
        "C": LV_CIRCUIT,
        "P": {"tag": "c:plates/steel"},
        "W": {"item": "toms_storage:ts.wireless_terminal"},
        "S": {"item": "gtceu:lv_sensor"},
    },
    "pattern": ["ECE", "PWP", "PSP"],
    "result": {"item": "toms_storage:ts.adv_wireless_terminal"},
}

SWORDS = {
    ("item", "minecraft:iron_ingot"): tag("c:plates/iron"),
    ("item", "minecraft:gold_ingot"): tag("c:plates/gold"),
    ("item", "minecraft:diamond"): tag("c:plates/diamond"),
    ("tag", "c:wood_sticks"): tag("c:rods/iron"),
}
# Iron, gold and diamond weapons; netherite and runic keep the mod's smithing recipes.
SWORDS_MATCH = re.compile(r"(iron|gold|diamond)_(?!melting)[a-z]+$|sword_on_a_stick$")

#-- Rewriting

def swap(ingredient, table):
    if isinstance(ingredient, list):
        return [swap(i, table) for i in ingredient]
    if not isinstance(ingredient, dict):
        return ingredient
    for kind in ("item", "tag"):
        new = table.get((kind, ingredient.get(kind)))
        if new:
            return dict(new)
    return ingredient


def rewrite(recipe, table):
    recipe = json.loads(json.dumps(recipe))
    if "key" in recipe:
        recipe["key"] = {k: swap(v, table) for k, v in recipe["key"].items()}
    if "ingredients" in recipe:
        recipe["ingredients"] = [swap(i, table) for i in recipe["ingredients"]]
    return recipe


def imbuing_table(recipe):
    """Two copper plates on top and two LV circuits below replace the copper blocks."""
    recipe = json.loads(json.dumps(recipe))
    recipe["key"]["#"] = tag("c:plates/copper")
    recipe["key"]["C"] = LV_CIRCUIT
    recipe["pattern"] = ["#P#", "OSO", "CEC"]
    return recipe


def recipes(jar, ns):
    with zipfile.ZipFile(jar) as z:
        for name in sorted(z.namelist()):
            m = re.match(rf"data/{ns}/recipes/(.+)\.json$", name)
            if m:
                yield name, m.group(1), json.loads(z.read(name))


def find(mods, pattern):
    hits = sorted(mods.glob(pattern))
    if len(hits) != 1:
        sys.exit(f"expected one {pattern} in {mods}, found {len(hits)}")
    return hits[0]


def write(path, recipe, written):
    dst = OUT / path
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_text(json.dumps(recipe, indent=2) + "\n")
    written.append(path)


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    mods = Path(sys.argv[1]).expanduser()
    written = []

    for path, rid, r in recipes(find(mods, "toms_storage-*.jar"), "toms_storage"):
        if rid == "adv_wireless_terminal":
            write(path, ADV_WIRELESS, written)
            continue
        table = dict(TOMS)
        if rid in TOMS_BRONZE:
            table[("tag", "minecraft:planks")] = tag("c:plates/bronze")
        new = rewrite(r, table)
        if new != r:
            write(path, new, written)

    for path, rid, r in recipes(find(mods, "simplyswords-*.jar"), "simplyswords"):
        if r.get("type") == "minecraft:crafting_shaped" and SWORDS_MATCH.match(rid):
            new = rewrite(r, SWORDS)
            if new != r:
                write(path, new, written)

    for path, rid, r in recipes(find(mods, "IllagerInvasion-*.jar"), "illagerinvasion"):
        if rid == "imbuing_table":
            write(path, imbuing_table(r), written)

    (OUT / "pack.mcmeta").write_text(json.dumps(PACK, indent=2) + "\n")
    stale = sorted(
        str(p.relative_to(OUT)) for p in OUT.glob("data/**/*.json")
        if str(p.relative_to(OUT)) not in written
    )
    print(f"wrote {len(written)} recipes to {OUT}")
    for p in stale:
        print(f"stale, no longer generated: {p}")


if __name__ == "__main__":
    main()
