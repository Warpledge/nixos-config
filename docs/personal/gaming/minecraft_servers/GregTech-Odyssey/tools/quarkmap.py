"""What becomes of each Quark id the Integrated mods use; quarkblocks/gen.py and
libgate.py both read it.

A Quark block in the jar keeps its name under the quarkblocks namespace, and so do the
block entity ids in template data (quark:variant_chest becomes quarkblocks:variant_chest).
The ones below become vanilla blocks instead: two ids current Quark no longer has.
"""

import gzip
import json
import re
import zipfile

NS = "quarkblocks"

# Quark id pattern -> (vanilla id, properties kept). \1 is the pattern's group.
VANILLA = [
    (r"bamboo_block", "minecraft:bamboo_block", {"axis"}),
    (r"potted_pink_blossom_sapling", "minecraft:potted_cherry_sapling", set()),
]
# Items older templates name that Quark 4 merged: the 17 coloured runes became one
# smithing template that takes a dye.
OLD_ITEMS = [(r"(blank|rainbow|white|orange|magenta|light_blue|yellow|lime|pink|gray|light_gray|"
              r"cyan|purple|blue|brown|green|red|black)_rune", "smithing_template_rune")]
# Quark entities quarkblocks registers under the same name; libgate drops any other
# Quark entity a template places.
OUR_ENTITIES = {"glass_frame", "wraith", "forgotten", "foxhound", "crab", "toretoise"}
# Quark entities that become vanilla ones instead (none now; kept for a future swap).
ENTITIES = {}

# The Integrated mods whose templates and data name Quark ids.
# "imm v" and "ibomd v" are Integrated Mowzie's Mobs and Integrated BOMD
# (IMM v1.3.2-1.20.1.jar); the space keeps ImmediatelyFast and Immersive Aircraft out.
JAR_PREFIXES = ("idas", "ida_", "iss-", "integrated_villages", "integrated_cataclysm",
                "imm v", "ibomd v")
# Integrated Dungeons Arise reskins When Dungeons Arise at the same paths without
# requiring it, and Integrated Cataclysm, Mowzie's Mobs and BOMD do the same to their
# base mods, so which mod's file loads is arbitrary; the pack carries all of their data
# so structures, pools, processors and templates always load together.
WHOLE_DATA = ("ida_", "integrated_cataclysm", "imm v", "ibomd v")


def vanilla(qid):
    """(vanilla id, kept properties) for a Quark id that maps to vanilla, else None."""
    for pat, target, keep in VANILLA:
        if re.fullmatch(pat, qid):
            return target, keep
    return None


def current(qid):
    """The id current Quark has for qid (OLD_ITEMS), else qid."""
    for pat, new in OLD_ITEMS:
        if re.fullmatch(pat, qid):
            return new
    return qid


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
            qid = current(value["name"][6:])
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
    qid = current(value.lstrip("#")[6:])
    if f"quark:{qid}" in ENTITIES:
        new = ENTITIES[f"quark:{qid}"]
    elif (v := vanilla(qid)) is not None:
        new = v[0]
    else:
        new = f"{NS}:{qid}"
    return ("#" if tag else "") + new


def dumps(value):
    return json.dumps(value, indent=2) + "\n"
