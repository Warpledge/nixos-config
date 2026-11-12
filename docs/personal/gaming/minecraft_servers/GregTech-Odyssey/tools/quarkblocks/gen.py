#!/usr/bin/env python3
"""Write the quarkblocks mod's resources from the Quark jar and the Integrated mods' jars.

Usage:
    python3 -I <this file> <Quark jar> <mods folder>

Takes every Quark block the Integrated mods' templates and data name (minus the ones
quarkmap.VANILLA sends to vanilla blocks), and writes into src/generated/resources/:
blocks.json (kind, properties, the vanilla block whose properties it copies, render
layer), Quark's blockstates, models, textures, names, block loot tables and vanilla
tags renamed to quarkblocks:, and the monster box's loot tables and sound. Quark's
assets are CC BY-NC-SA 3.0, so this folder stays out of git. build.py runs this.
"""

import argparse
import json
import re
import shutil
import sys
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import quarkmap  # noqa: E402

NS = quarkmap.NS
OUT = HERE / "src" / "generated" / "resources"
PACK = {"pack": {"pack_format": 15, "description": "Quark Blocks resources"}}

#-- Kinds

WOODS = ("oak|spruce|birch|jungle|acacia|dark_oak|mangrove|cherry|bamboo|crimson|warped|"
         "azalea|blossom|ancient|midori")
# Vanilla blocks to copy properties from. Only ones whose light and other state
# lambdas don't read their own properties, since the copy's states are different.
COPY = [
    (r".*corundum_cluster", "minecraft:amethyst_cluster"),
    (r".*(corundum|crystal).*", "minecraft:amethyst_block"),
    (r".*(glass|paper_wall).*", "minecraft:glass"),
    (r".*(lantern|lamp).*", "minecraft:glowstone"),
    (rf".*(blossom|{WOODS})_(leaves|hedge|leaf_carpet)|.*_hedge", "minecraft:oak_leaves"),
    (r".*bookshelf", "minecraft:bookshelf"),
    (r"(cherry|blossom).*", "minecraft:cherry_planks"),
    (r"(bamboo).*", "minecraft:bamboo_planks"),
    (r"(crimson|warped).*", "minecraft:crimson_planks"),
    (rf"({WOODS}|stripped|hollow|vertical).*(log|wood)", "minecraft:oak_log"),
    (rf"({WOODS}|stripped|vertical).*", "minecraft:oak_planks"),
    (r".*shingles.*", "minecraft:terracotta"),
    (r"thatch.*", "minecraft:hay_block"),
    (r".*(sack|bonded|stool|paper).*", "minecraft:white_wool"),
    (r".*(crate|feeding_trough|stick_block|cactus_block|sugar_cane_block).*", "minecraft:oak_planks"),
    (r".*(iron_plate|iron_rod|pipe|gold_bars|grate|chute|crafter|randomizer|watcher).*",
     "minecraft:iron_block"),
    (r"monster_box", "minecraft:spawner"),
    (r"potted_.*", "minecraft:flower_pot"),
    (r"glow_shroom.*|glow_lichen_growth", "minecraft:brown_mushroom_block"),
    (r".*(mud|dirt).*", "minecraft:mud_bricks"),
    (r".*(nether|netherrack).*", "minecraft:nether_bricks"),
    (r".*deepslate.*", "minecraft:deepslate_bricks"),
    (r".*blackstone.*|duskbound.*", "minecraft:polished_blackstone_bricks"),
    (r".*sandstone.*", "minecraft:sandstone"),
    (r".*(quartz).*", "minecraft:quartz_block"),
    (r".*purpur.*", "minecraft:purpur_block"),
    (r".*prismarine.*", "minecraft:prismarine"),
    (r".*end_stone.*", "minecraft:end_stone_bricks"),
    (r".*copper.*", "minecraft:copper_block"),
    (r".*(calcite).*", "minecraft:calcite"),
    (r".*(dripstone).*", "minecraft:dripstone_block"),
    (r".*(tuff).*", "minecraft:tuff"),
    (r"obsidian.*", "minecraft:obsidian"),
    (r"gravisand", "minecraft:sand"),
    (r".*", "minecraft:stone_bricks"),
]
SETS = [("cherry|blossom", "cherry"), ("bamboo", "bamboo"), ("crimson|warped", "crimson"),
        ("iron", "iron"), ("gold", "gold"), ("obsidian|stone", "stone")]
# PropsBlock shapes by id; anything else in PropsBlock is a full block.
SHAPES = [(r".*_vertical_slab", "vertical_slab"), (r".*_post", "post"), (r"iron_rod", "rod"),
          (r"pipe", "pipe"), (r".*_stool", "stool"), (r"potted_.*", "pot"),
          (r"redstone_randomizer|bamboo_mat_carpet", "thin"),
          (r"glow_shroom|glow_lichen_growth|.*_sapling|tiny_potato|rope", "cross")]
CUTOUT = re.compile(r".*(glass|leaves|hedge|leaf_carpet|ladder|door|trapdoor|cluster|potted_|"
                    r"paper_wall|grate|bars|glow_shroom$|glow_lichen|sapling|rope|post|pipe|"
                    r"iron_rod|lantern).*")
TRANSLUCENT = re.compile(r".*(framed_glass|corundum(?!_cluster)|dirty_glass|crystal).*")
LIGHT = {"orange_crystal_lamp": 15}


def first(table, qid, default=None):
    for pat, value in table:
        if re.fullmatch(pat, qid):
            return value
    return default


def kind(qid, props):
    keys = set(props)
    if qid == "monster_box":
        return "monster_box"
    if qid.endswith("_vertical_slab"):
        return "props"
    for suffix, k in (("_slab", "slab"), ("_stairs", "stairs"), ("_wall", "wall"),
                      ("_fence_gate", "fence_gate"), ("_fence", "fence"), ("_trapdoor", "trapdoor"),
                      ("_door", "door"), ("_button", "button"), ("_pressure_plate", "pressure_plate"),
                      ("_ladder", "ladder"), ("_leaves", "leaves"), ("_leaf_carpet", "carpet"),
                      ("_corundum_cluster", "cluster")):
        if qid.endswith(suffix) and not (k == "wall" and "up" not in keys):
            return k
    if keys and keys <= {"east", "north", "south", "west", "waterlogged"} and not qid.endswith("_hedge"):
        return "pane"
    if keys == {"axis"} and not qid.endswith("_post"):
        return "pillar"
    if not keys and re.fullmatch(r".*(framed_glass|dirty_glass)", qid):
        return "glass"
    if not keys and not first(SHAPES, qid):
        return "cube"
    return "props"


def spec(qid, props):
    k = kind(qid, props)
    s = {"id": qid, "kind": k, "copy": first(COPY, qid)}
    if k in ("door", "trapdoor", "button", "pressure_plate", "fence_gate"):
        s["set"] = next((v for pat, v in SETS if re.search(pat, qid)), "oak")
    if k == "props":
        s["props"] = props
        s["shape"] = first(SHAPES, qid, "full")
    if qid in LIGHT:
        s["light"] = LIGHT[qid]
    if TRANSLUCENT.fullmatch(qid):
        s["render"] = "translucent"
    elif CUTOUT.fullmatch(qid):
        s["render"] = "cutout_mipped" if re.search("leaves|hedge|leaf_carpet", qid) else "cutout"
    if k in ("props", "cube") and ("render" in s or s.get("shape", "full") != "full"):
        s["see_through"] = True
    return s

#-- Properties


def blockstate_props(quark, qid):
    props = {}
    d = json.loads(quark.read(f"assets/quark/blockstates/{qid}.json"))
    for key in d.get("variants", {}):
        for pair in key.split(","):
            if "=" in pair:
                a, b = pair.split("=")
                props.setdefault(a, set()).add(b)
    for part in d.get("multipart", []):
        when = part.get("when", {})
        for cond in when.get("OR", [when]):
            for a, b in cond.items():
                props.setdefault(a, set()).update(str(b).lower().split("|"))
    return props


def template_props(jars, ids):
    """Property values the templates set on each Quark block, beyond its blockstate's."""
    import gzip

    found = {}
    rx = re.compile(rb"quark:")
    sys.path.insert(0, str(HERE.parent))
    import nbt

    for jar in jars:
        with zipfile.ZipFile(jar) as z:
            for n in z.namelist():
                if not (n.endswith(".nbt") and "/structures/" in n):
                    continue
                raw = z.read(n)
                if not rx.search(gzip.decompress(raw)):
                    continue
                root = nbt.plain(nbt.load(raw)[1])
                states = [e for pal in root.get("palettes") or [root.get("palette") or []]
                          for e in pal]
                # Block entities can hold states too (IMM's Mimic), with the same
                # Name/Properties shape as a palette entry.
                stack = [b.get("nbt") for b in root.get("blocks") or []]
                while stack:
                    t = stack.pop()
                    if isinstance(t, dict):
                        if isinstance(t.get("Name"), str) and "Properties" in t:
                            states.append(t)
                        stack.extend(t.values())
                    elif isinstance(t, list):
                        stack.extend(t)
                for e in states:
                    q = e["Name"][6:] if e["Name"].startswith("quark:") else None
                    if q in ids:
                        for a, b in (e.get("Properties") or {}).items():
                            found.setdefault(q, {}).setdefault(a, set()).add(b)
    return found

#-- Assets


def rename(text):
    return text.replace('"quark:', f'"{NS}:').replace('"zeta:', f'"{NS}:')


def copy_json(src, path, dst_path):
    data = rename(src.read(path).decode())
    out = OUT / dst_path
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(data)
    return json.loads(data)


def model_refs(model):
    """(parent model, texture paths); kept apart since the two share path names."""
    parent = model.get("parent") if isinstance(model.get("parent"), str) else None
    tex = [v for v in (model.get("textures") or {}).values()
           if isinstance(v, str) and not v.startswith("#")]
    return parent, tex


def copy_assets(quark, zeta, ids):
    names = set(quark.namelist())
    znames = set(zeta.namelist()) if zeta else set()
    models, textures = [], set()
    for q in ids:
        bs = copy_json(quark, f"assets/quark/blockstates/{q}.json",
                       f"assets/{NS}/blockstates/{q}.json")
        for m in re.findall(rf'"{NS}:(block/[a-z0-9_/]+)"', json.dumps(bs)):
            models.append(m)
        if f"assets/quark/models/item/{q}.json" in names:
            models.append(f"item/{q}")
        else:
            (OUT / f"assets/{NS}/models/item").mkdir(parents=True, exist_ok=True)
            (OUT / f"assets/{NS}/models/item/{q}.json").write_text(
                json.dumps({"parent": f"{NS}:block/{q}"}))
    done = set()
    while models:
        m = models.pop()
        if m in done:
            continue
        done.add(m)
        for src, nm in ((quark, f"assets/quark/models/{m}.json"), (zeta, f"assets/zeta/models/{m}.json")):
            if src and nm in (names if src is quark else znames):
                model = copy_json(src, nm, f"assets/{NS}/models/{m}.json")
                parent, tex = model_refs(model)
                if parent and parent.startswith(f"{NS}:"):
                    models.append(parent.split(":", 1)[1])
                textures.update(t.split(":", 1)[1] for t in tex if t.startswith(f"{NS}:"))
                break
        else:
            print(f"warning: model {m} not found", file=sys.stderr)
    for t in sorted(textures):
        found = False
        for ext in (".png", ".png.mcmeta"):
            for src, root in ((quark, "quark"), (zeta, "zeta")):
                nm = f"assets/{root}/textures/{t}{ext}"
                if src and nm in (names if src is quark else znames):
                    out = OUT / f"assets/{NS}/textures/{t}{ext}"
                    out.parent.mkdir(parents=True, exist_ok=True)
                    out.write_bytes(src.read(nm))
                    found = True
                    break
        if not found:
            print(f"warning: texture {t} not found", file=sys.stderr)
    lang = json.loads(quark.read("assets/quark/lang/en_us.json"))
    ours = {f"block.{NS}.{q}": lang.get(f"block.quark.{q}", q.replace("_", " ").title()) for q in ids}
    (OUT / f"assets/{NS}/lang").mkdir(parents=True, exist_ok=True)
    (OUT / f"assets/{NS}/lang/en_us.json").write_text(json.dumps(ours, indent=1, sort_keys=True))
    sounds = json.loads(quark.read("assets/quark/sounds.json"))
    growl = sounds["block.monster_box.growl"]
    (OUT / f"assets/{NS}/sounds.json").write_text(rename(json.dumps({"block.monster_box.growl": growl})))
    for s in growl["sounds"]:
        path = (s["name"] if isinstance(s, dict) else s).split(":", 1)[1]
        out = OUT / f"assets/{NS}/sounds/{path}.ogg"
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_bytes(quark.read(f"assets/quark/sounds/{path}.ogg"))

#-- Data


def copy_data(quark, ids):
    names = quark.namelist()
    keep = lambda q: q in ids or quarkmap.vanilla(q) is not None  # noqa: E731
    tables = [f"blocks/{q}" for q in ids] + ["misc/monster_box", "misc/monster_box_spawns"]
    for t in tables:
        nm = f"data/quark/loot_tables/{t}.json"
        if nm not in names:
            print(f"warning: no loot table {t}", file=sys.stderr)
            continue
        data = quarkmap.rename_json(json.loads(quark.read(nm)), keep)
        out = OUT / f"data/{NS}/loot_tables/{t}.json"
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(quarkmap.dumps(data))
    tag_rx = re.compile(r"data/minecraft/tags/blocks/(.+)\.json$")
    for nm in names:
        if not (m := tag_rx.match(nm)):
            continue
        values = json.loads(quark.read(nm)).get("values", [])
        ours = []
        for v in values:
            vid = v["id"] if isinstance(v, dict) else v
            if vid.startswith("quark:") and vid[6:] in ids:
                ours.append(f"{NS}:{vid[6:]}")
        if ours:
            out = OUT / f"data/minecraft/tags/blocks/{m[1]}.json"
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(quarkmap.dumps({"replace": False, "values": sorted(ours)}))


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("quark", type=Path)
    ap.add_argument("mods", type=Path)
    ap.add_argument("--zeta", type=Path, help="Zeta jar, for any model Quark borrows from it")
    a = ap.parse_args()
    quark = zipfile.ZipFile(a.quark)
    zeta = zipfile.ZipFile(a.zeta) if a.zeta else None
    jars = quarkmap.integrated_jars(a.mods)
    if not jars:
        sys.exit(f"no Integrated jars in {a.mods}")
    names = set(quark.namelist())
    named = quarkmap.used_ids(jars) | {"monster_box"}
    ids = sorted(q for q in named if quarkmap.vanilla(q) is None
                 and f"assets/quark/blockstates/{q}.json" in names)
    print(f"{len(ids)} blocks; {len(named) - len(ids)} other ids (items, mobs, vanilla-mapped)")
    tprops = template_props(jars, set(ids))
    if OUT.exists():
        shutil.rmtree(OUT)
    (OUT / NS).mkdir(parents=True)
    specs = []
    for q in ids:
        props = blockstate_props(quark, q)
        for a_, vals in tprops.get(q, {}).items():
            # Older Quark's templates carry properties current Quark dropped (posts'
            # chain_*), which multiplied the states to millions; Minecraft ignores a
            # template property the block lacks. Blockstate files never list waterlogged.
            if a_ in props or a_ == "waterlogged":
                props.setdefault(a_, set()).update(vals)
        specs.append(spec(q, {k: sorted(v) for k, v in sorted(props.items())}))
    (OUT / NS / "blocks.json").write_text(json.dumps(specs, indent=1))
    (OUT / "pack.mcmeta").write_text(json.dumps(PACK))
    copy_assets(quark, zeta, ids)
    copy_data(quark, set(ids))
    counts = {}
    for s in specs:
        counts[s["kind"]] = counts.get(s["kind"], 0) + 1
    print("kinds:", dict(sorted(counts.items(), key=lambda x: -x[1])))


if __name__ == "__main__":
    main()
