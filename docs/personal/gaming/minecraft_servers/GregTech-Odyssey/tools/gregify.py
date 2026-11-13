#!/usr/bin/env python3
"""Write the GT overrides for Tom's Simple Storage, Simply Swords, Illager Invasion,
Terralith and, when their jars are there, L_Ender's Cataclysm, Integrated Simply
Swords and Iron's Spells into the datapack beside this folder.

Usage:
    python3 -I <this file> <mods folder>

Reads each mod's own recipes from its jar in <mods folder>, keeps every pattern, swaps
the ingredients by the tables below and writes the result to
datapack/warpledge-gto/data/<ns>/recipes/<id>.json, the same path as in the jar, so the
datapack replaces the mod's recipe. Rerun after updating one of these mods. A recipe
not matched by a rule is left to the mod. 0.6.0/mods.md explains the choices.

It also writes Ad Astra's entity tags that let modded mobs live in the airless Nether
and End (AIRLESS_*), and for Iron's Spells its mithril ore off, two loot tables fixed
for 1.20.1 and a Reliable Remover rule in ../reliable/ hiding its own mithril.
"""

import json
import re
import sys
import zipfile
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "datapack" / "warpledge-gto"
REMOVER = Path(__file__).resolve().parent.parent / "reliable" / "reliable_remover"
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

# Cataclysm's gear needs boss drops; only these use plain vanilla metals. The first six
# are the ones Integrated Cataclysm turns into Create recipes the bans remove, so they're
# written even unchanged, to put Cataclysm's crafting recipe back.
CATACLYSM = {k: v for k, v in SWORDS.items() if k[0] == "item"}
CATACLYSM_RESTORE = [
    "mech_eye", "mechanical_fusion_anvil", "the_incinerator", "meat_shredder",
    "laser_gatling", "wither_assault_shoulder_weapon",
]
CATACLYSM_GREG = ["storm_eye", "desert_eye", "cursed_eye", "belt_of_beginner",
                  "netherite_effigy"]

# Integrated Simply Swords: only its silver weapons load in GTO, from GT's silver.
INTEGRATED_SWORDS = {
    ("item", "minecraft:stick"): tag("c:rods/iron"),
    ("tag", "forge:ingots/silver"): tag("c:plates/silver"),
}

# Iron's Spells: vanilla metals become GT plates, and its mithril is GTOCore's MV
# Mithril. Its own ore, raw mithril and ingot are off (IRONS_REMOVE), so scrap only
# comes from GTO's ingot or salvage. Netherite, chains, nuggets and amethyst stay.
IRONS = {
    **CATACLYSM,
    ("item", "minecraft:copper_ingot"): tag("c:plates/copper"),
    ("tag", "forge:ingots/iron"): tag("c:plates/iron"),
    ("tag", "forge:ingots/gold"): tag("c:plates/gold"),
    ("tag", "forge:ingots/copper"): tag("c:plates/copper"),
    ("tag", "forge:gems/diamond"): tag("c:plates/diamond"),
    ("tag", "forge:ingots/mithril"): tag("c:ingots/mithril"),
    ("item", "irons_spellbooks:mithril_ingot"): tag("c:ingots/mithril"),
}
IRONS_TYPES = {"minecraft:crafting_shaped", "minecraft:crafting_shapeless",
               "minecraft:smithing_transform", "minecraft:blasting"}
IRONS_OFF = ["mithril_ingot_from_scrap", "mithril_scrap_from_ore"]
IRONS_REMOVE = ["mithril_ore", "deepslate_mithril_ore", "raw_mithril", "mithril_ingot"]

# Terralith re-adds vanilla's cheap redstone recipes from any stone, which GT replaces
# (removeVanillaBlockRecipes in gtceu.yaml); a false condition makes Forge skip them.
TERRALITH_OFF = ["piston_alt", "dispenser_alt", "observer_alt", "dropper_alt", "lever_alt"]
DISABLED = {"type": "minecraft:crafting_shaped", "conditions": [{"type": "forge:false"}]}

#-- Airless dimensions

# GTO runs the Nether and End through Ad Astra with no oxygen (hot and cold), so a mob
# missing from these tags dies there in seconds. GTO lists vanilla's Nether and End
# mobs only; every entity of these mods (from their lang keys) and vanilla's hostiles
# are added, each optional so a missing id can't break the tag.
AIRLESS_JARS = [
    "L_Enders_Cataclysm-*.jar", "Jadens-Nether-Expansion-*.jar",
    "legendarymonsters-*.jar", "endermanoverhaul-*.jar", "born_in_chaos_*.jar",
    "BOMD-*.jar", "mowziesmobs-*.jar",
]
AIRLESS_VANILLA = [
    "zombie", "husk", "drowned", "zombie_villager", "skeleton", "stray", "creeper",
    "spider", "cave_spider", "witch", "slime", "silverfish", "endermite", "phantom",
    "vex", "vindicator", "evoker", "pillager", "illusioner", "ravager", "guardian",
    "elder_guardian", "shulker", "enderman", "wither_skeleton", "piglin",
    "piglin_brute", "hoglin", "zoglin", "ghast", "blaze", "magma_cube", "strider",
    "zombified_piglin", "warden",
]
AIRLESS_TAGS = ["lives_without_oxygen", "can_survive_extreme_heat",
                "can_survive_extreme_cold"]



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
    # Cooking and smithing recipes name their inputs one by one.
    for field in ("ingredient", "base", "addition", "template"):
        if field in recipe:
            recipe[field] = swap(recipe[field], table)
    return recipe


def imbuing_table(recipe):
    """Two copper plates on top and two LV circuits below replace the copper blocks."""
    recipe = json.loads(json.dumps(recipe))
    recipe["key"]["#"] = tag("c:plates/copper")
    recipe["key"]["C"] = LV_CIRCUIT
    recipe["pattern"] = ["#P#", "OSO", "CEC"]
    return recipe


def snbt_string(text):
    return "'" + text.replace("\\", "\\\\").replace("'", "\\'") + "'"


def loot_120(node, title):
    """Iron's ships two loot tables in 1.21 syntax: a table reference by "value" and
    set_written_book_pages. Rewrites them the 1.20.1 way (pages as JSON strings)."""
    if isinstance(node, list):
        return [loot_120(n, title) for n in node]
    if not isinstance(node, dict):
        return node
    node = {k: loot_120(v, title) for k, v in node.items()}
    if node.get("type") == "minecraft:loot_table" and "value" in node:
        node["name"] = node.pop("value")
    if node.get("function") == "minecraft:set_written_book_pages":
        pages = ",".join(snbt_string(json.dumps(p)) for p in node["pages"])
        node = {"function": "minecraft:set_nbt",
                "tag": f"{{title:{snbt_string(title)},author:'',pages:[{pages}]}}"}
    return node


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


def entities(jar):
    """Entity ids named by the jar's en_us lang keys (entity.<ns>.<name>)."""
    ids = set()
    with zipfile.ZipFile(jar) as z:
        for name in z.namelist():
            if re.match(r"assets/[^/]+/lang/en_us\.json$", name):
                for key in json.loads(z.read(name)):
                    m = re.match(r"entity\.([a-z0-9_]+)\.([a-z0-9_]+)$", key)
                    if m and m.group(1) != "minecraft":
                        ids.add(f"{m.group(1)}:{m.group(2)}")
    return ids


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

    if any(mods.glob("L_Enders_Cataclysm-*.jar")):
        cat = {rid: (path, r) for path, rid, r in
               recipes(find(mods, "L_Enders_Cataclysm-*.jar"), "cataclysm")}
        for rid in CATACLYSM_RESTORE + CATACLYSM_GREG:
            if rid not in cat:
                sys.exit(f"Cataclysm no longer has recipe {rid}; check CATACLYSM_*")
            path, r = cat[rid]
            new = rewrite(r, CATACLYSM)
            if new != r or rid in CATACLYSM_RESTORE:
                write(path, new, written)

    if any(mods.glob("integrated_simply_swords-*.jar")):
        jar = find(mods, "integrated_simply_swords-*.jar")
        for path, rid, r in recipes(jar, "integrated_simply_swords"):
            if rid.startswith("generic/silver/"):
                new = rewrite(r, INTEGRATED_SWORDS)
                if new != r:
                    write(path, new, written)

    if any(mods.glob("irons_spellbooks-*.jar")):
        jar = find(mods, "irons_spellbooks-*.jar")
        irons = {rid: (path, r) for path, rid, r in recipes(jar, "irons_spellbooks")}
        for rid in IRONS_OFF:
            if rid not in irons:
                sys.exit(f"Iron's no longer has recipe {rid}; check IRONS_OFF")
            write(irons[rid][0], DISABLED, written)
        for rid, (path, r) in irons.items():
            if rid not in IRONS_OFF and r.get("type") in IRONS_TYPES:
                new = rewrite(r, IRONS)
                if new != r:
                    write(path, new, written)
        with zipfile.ZipFile(jar) as z:
            names = set(z.namelist())
            ore = "data/irons_spellbooks/forge/biome_modifier/add_mithril_ore.json"
            loot = [f"data/irons_spellbooks/loot_tables/chests/{t}.json"
                    for t in ("citadel/citadel_tomes", "catacombs/crypt_loot")]
            for path in [ore] + loot:
                if path not in names:
                    sys.exit(f"{jar.name} no longer has {path}; check the Iron's paths")
            lang = json.loads(z.read("assets/irons_spellbooks/lang/en_us.json"))
            title = lang.get("lore.citadel_book.title", "Tome")
            write(ore, {"type": "forge:none"}, written)
            for path in loot:
                write(path, loot_120(json.loads(z.read(path)), title), written)
        REMOVER.mkdir(parents=True, exist_ok=True)
        (REMOVER / "irons_spellbooks.json").write_text(json.dumps([
            {"action": "remove",
             "items": [f"irons_spellbooks:{i}" for i in IRONS_REMOVE]},
        ], indent=2) + "\n")

    terralith = find(mods, "Terralith_*.jar")
    with zipfile.ZipFile(terralith) as z:
        names = set(z.namelist())
    for rid in TERRALITH_OFF:
        path = f"data/terralith/recipes/{rid}.json"
        if path not in names:
            sys.exit(f"{terralith.name} no longer has {path}; check TERRALITH_OFF")
        write(path, DISABLED, written)

    mobs = {f"minecraft:{m}" for m in AIRLESS_VANILLA}
    for pattern in AIRLESS_JARS:
        for jar in mods.glob(pattern):
            mobs |= entities(jar)
    values = [{"id": m, "required": False} for m in sorted(mobs)]
    for name in AIRLESS_TAGS:
        write(f"data/ad_astra/tags/entity_types/{name}.json",
              {"replace": False, "values": values}, written)

    (OUT / "pack.mcmeta").write_text(json.dumps(PACK, indent=2) + "\n")
    stale = sorted(
        str(p.relative_to(OUT)) for p in OUT.glob("data/**/*.json")
        if str(p.relative_to(OUT)) not in written
    )
    print(f"wrote {len(written)} overrides to {OUT}")
    for p in stale:
        print(f"stale, no longer generated: {p}")


if __name__ == "__main__":
    main()
