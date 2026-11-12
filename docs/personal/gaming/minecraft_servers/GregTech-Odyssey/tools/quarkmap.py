"""What becomes of each Quark id the Integrated mods use; quarkblocks/gen.py and
libgate.py both read it.

A Quark block in the jar keeps its name under the quarkblocks namespace. The ones below
become vanilla blocks instead: storage and signs whose block entity data (loot tables,
sign text) a vanilla block reads, and two ids current Quark no longer has.
"""

import gzip
import json
import re
import zipfile

NS = "quarkblocks"

# Quark id pattern -> (vanilla id, properties kept). \1 is the pattern's group.
VANILLA = [
    (r".+_trapped_chest", "minecraft:trapped_chest", {"facing", "type", "waterlogged"}),
    (r".+_chest", "minecraft:chest", {"facing", "type", "waterlogged"}),
    (r"(deepslate|blackstone)_furnace", "minecraft:furnace", {"facing", "lit"}),
    (r"crate", "minecraft:barrel", {"facing", "open"}),
    (r"blossom_wall_sign", "minecraft:cherry_wall_sign", {"facing", "waterlogged"}),
    (r"bamboo_block", "minecraft:bamboo_block", {"axis"}),
    (r"potted_pink_blossom_sapling", "minecraft:potted_cherry_sapling", set()),
]
# Block entity ids in template block data, renamed with their blocks.
BLOCK_ENTITIES = {
    "quark:variant_chest": "minecraft:chest",
    "quark:variant_trapped_chest": "minecraft:trapped_chest",
    "quark:crate": "minecraft:barrel",
    "quark:monster_box": f"{NS}:monster_box",
}
# Quark's wraith and forgotten don't exist without Quark.
ENTITIES = {"quark:wraith": "minecraft:stray", "quark:forgotten": "minecraft:skeleton"}

# The Integrated mods whose templates and data name Quark ids.
JAR_PREFIXES = ("idas", "ida_", "iss-", "integrated_villages")
# Integrated Dungeons Arise reskins When Dungeons Arise at the same paths without
# requiring it, so which mod's file loads is arbitrary; the pack carries all of IDA's
# data so its structures, pools, processors and templates always load together.
WHOLE_DATA = ("ida_",)


def vanilla(qid):
    """(vanilla id, kept properties) for a Quark id that maps to vanilla, else None."""
    for pat, target, keep in VANILLA:
        if re.fullmatch(pat, qid):
            return target, keep
    return None


def integrated_jars(mods):
    return sorted(p for p in mods.glob("*.jar") if p.name.lower().startswith(JAR_PREFIXES))


def used_ids(jars):
    """Every quark:<id> named by the jars' templates and JSON data, without the prefix."""
    found = set()
    pat = re.compile(rb"quark:([a-z0-9_/]+)")
    for jar in jars:
        with zipfile.ZipFile(jar) as z:
            for n in z.namelist():
                if n.endswith(".nbt") and "/structures/" in n:
                    data = gzip.decompress(z.read(n))
                elif n.startswith("data/") and n.endswith(".json"):
                    data = z.read(n)
                else:
                    continue
                found.update(m.decode() for m in pat.findall(data))
    return found


def rename_json(value, keep_item):
    """Rename quark ids inside parsed JSON; drop loot entries for ids keep_item refuses.

    Returns the new value, or None for a loot entry to remove.
    """
    if isinstance(value, dict):
        if value.get("type") == "minecraft:item" and str(value.get("name", "")).startswith("quark:"):
            qid = value["name"][6:]
            if not keep_item(qid):
                return None
        out = {}
        for k, v in value.items():
            nv = rename_json(v, keep_item)
            if nv is not None:
                out[k] = nv
        return out
    if isinstance(value, list):
        return [nv for v in value if (nv := rename_json(v, keep_item)) is not None]
    if isinstance(value, str) and value.startswith(("quark:", "#quark:")):
        return rename_id(value)
    return value


def rename_id(value):
    tag = value.startswith("#")
    qid = value.lstrip("#")[6:]
    if f"quark:{qid}" in ENTITIES:
        new = ENTITIES[f"quark:{qid}"]
    elif (v := vanilla(qid)) is not None:
        new = v[0]
    else:
        new = f"{NS}:{qid}"
    return ("#" if tag else "") + new


def dumps(value):
    return json.dumps(value, indent=2) + "\n"
