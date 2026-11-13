#!/usr/bin/env python3
"""Write the quarkblocks mod's resources from the Quark jar and the Integrated mods' jars.

Usage:
    python3 -I <this file> <Quark jar> <mods folder>

Takes every Quark block the Integrated mods' templates and data name (minus the ones
quarkmap.VANILLA sends to vanilla blocks), and writes into src/generated/resources/:
blocks.json (kind, properties, the vanilla block whose properties it copies, render
layer, colour source), Quark's blockstates, models, textures, names, block loot tables and vanilla
tags renamed to quarkblocks:, and the monster box's loot tables and sound. Quark's
assets are CC BY-NC-SA 3.0, so this folder stays out of git. build.py runs this.
"""

import argparse
import fnmatch
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
    (r"nether_brick_(trapped_)?chest", "minecraft:nether_bricks"),
    (r"purpur_(trapped_)?chest", "minecraft:purpur_block"),
    (r"prismarine_(trapped_)?chest", "minecraft:prismarine"),
    (r".+_chest", "minecraft:chest"),
    (r"deepslate_furnace", "minecraft:deepslate"),
    (r"blackstone_furnace", "minecraft:blackstone"),
    (r"crate", "minecraft:barrel"),
    (r".+_sign", "minecraft:cherry_sign"),
    (r".*corundum_cluster", "minecraft:amethyst_cluster"),
    (r".*(corundum|crystal).*", "minecraft:amethyst_block"),
    (r".*(glass|paper_wall).*", "minecraft:glass"),
    (r".*(lantern|lamp).*", "minecraft:glowstone"),
    # Quark's hedges copy their wood's fence; leaf carpets build their own properties.
    (r"(cherry|.*blossom)_hedge", "minecraft:cherry_fence"),
    (r".*_hedge", "minecraft:oak_fence"),
    (rf".*(blossom|{WOODS})_(leaves|leaf_carpet)", "minecraft:oak_leaves"),
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
SHAPES = [(r"iron_rod", "rod"), (r"pipe", "pipe"), (r"potted_.*", "pot"),
          (r"redstone_randomizer|bamboo_mat_carpet", "thin"),
          (r"glow_shroom|glow_lichen_growth|.*_sapling|tiny_potato|rope", "cross")]
CUTOUT = re.compile(r".*(glass|leaves|hedge|leaf_carpet|ladder|door|trapdoor|cluster|potted_|"
                    r"paper_wall|grate|bars|glow_shroom$|glow_lichen|sapling|rope|post|pipe|"
                    r"iron_rod|lantern|chute|redstone_randomizer).*")
TRANSLUCENT = re.compile(r".*(framed_glass|corundum(?!_cluster)|dirty_glass|crystal).*")
LIGHT = {"orange_crystal_lamp": 15}
# Colour source for blocks whose models are tinted: Quark's named colour providers.
# A block id copies that block's colour; "myalite" is Quark's position-based hue.
TINT = [(r"myalite.*", "myalite"),
        (r"(ancient|.+_blossom)_(hedge|leaf_carpet)", rf"{NS}:\1_leaves"),
        (r"(.+)_(hedge|leaf_carpet)", r"minecraft:\1_leaves")]
COPPER = re.compile(r"(waxed_)?((exposed|weathered|oxidized)_)?cut_copper_vertical_slab")
# Neighbour-aware Quark classes, ported to Java; matched before kind()'s other rules.
OWN_KINDS = [(r".*_vertical_slab", "vertical_slab"), (r".*_hedge", "hedge"),
             (r".*_post", "post"), (r".*_stool", "stool"), (r".*_leaf_carpet", "leaf_carpet"),
             (r".+_trapped_chest", "trapped_chest"), (r".+_chest", "chest"),
             (r".+_furnace", "furnace"), (r"crate", "crate"),
             (r".+_wall_sign", "wall_sign"), (r".+_sign", "sign"),
             (r"feeding_trough|pipe|ender_watcher|chute|redstone_randomizer|cloud", None),
             (r"crafter|tiny_potato", "keeper")]
# Data the ported code uses besides blocks: extra models, sounds, screens, lang keys.
EXTRA_MODELS = {"pipe": ["item/extra/pipe_flare"]}
EXTRA_SOUNDS = {"monster_box": ["block.monster_box.growl"],
                "pipe": ["block.pipe.pickup", "block.pipe.shoot"],
                "pickarang": ["entity.pickarang.throw", "entity.pickarang.clank",
                              "entity.pickarang.spark", "entity.pickarang.pickup"],
                "soul_bead": ["entity.soul_bead.idle", "item.soul_powder.spawn"]}
# Item kinds (ItemFactory); any other item is plain. Discs and parrot eggs go by prefix.
ITEM_KINDS = {"abacus": "abacus", "ancient_fruit": "ancient_fruit", "ancient_tome": "ancient_tome",
              "bottled_cloud": "bottled_cloud", "crab_leg": "food", "cooked_crab_leg": "food",
              "forgotten_hat": "forgotten_hat", "pathfinders_quill": "quill",
              "pickarang": "pickarang", "seed_pouch": "seed_pouch",
              "slime_in_a_bucket": "slime_bucket", "smithing_template_rune": "rune",
              "soul_bead": "soul_bead", "torch_arrow": "torch_arrow", "trowel": "trowel"}
# Items not ported yet: they need the mobs and entities (a stoneling, the frame entity).
LATER_ITEMS = {"glass_item_frame", "diamond_heart"}
QUARK_TAGS = ["blocks/pickarang_immune", "items/seed_pouch_holdable", "items/seed_pouch_fertilizers",
              "worldgen/structure/soul_bead_target"]
# Blocks an item places, registered with it.
ITEM_BLOCKS = {"bottled_cloud": ["cloud"]}
EXTRA_TEXTURES = {"crate": ["gui/crate"], "feeding_trough": ["gui/container/feeding_trough"],
                  "forgotten_hat": ["misc/forgotten_hat_worn"],
                  "torch_arrow": ["model/entity/torch_arrow"],
                  "smithing_template_rune": ["item/empty_slot_dye", "item/empty_slot_blaze_powder",
                                             "item/empty_slot_nothing"]}
# Lang keys besides block.quark.<id> and item.quark.<id>*; a trailing * is a prefix.
EXTRA_LANG = {"feeding_trough": ["quark.container.feeding_trough"],
              "pipe": ["quark.subtitles.pipe_pickup", "quark.subtitles.pipe_shoot"],
              "pathfinders_quill": ["quark.misc.quill_*", "quark.misc.only_one_quill", "item.quark.biome_map"],
              "ancient_tome": ["quark.misc.ancient_tome_tooltip*"],
              "smithing_template_rune": ["item.quark.smithing_template.rune.*", "upgrade.quark.rune_upgrade",
                                         "rune.quark.*"]}
# Data files the ported code needs besides block loot (fnmatch patterns under data/quark/).
EXTRA_DATA = {"smithing_template_rune": ["recipes/tools/smithing/rune_smithing_*.json"]}
CHEST_TEXTURES = ("normal", "left", "right", "trap", "trap_left", "trap_right")


def first(table, qid, default=None):
    for pat, value in table:
        if re.fullmatch(pat, qid):
            return value
    return default


def kind(qid, props):
    keys = set(props)
    if qid == "monster_box":
        return "monster_box"
    for pat, own in OWN_KINDS:
        if re.fullmatch(pat, qid):
            return own or qid
    for suffix, k in (("_slab", "slab"), ("_stairs", "stairs"), ("_wall", "wall"),
                      ("_fence_gate", "fence_gate"), ("_fence", "fence"), ("_trapdoor", "trapdoor"),
                      ("_door", "door"), ("_button", "button"), ("_pressure_plate", "pressure_plate"),
                      ("_ladder", "ladder"), ("_leaves", "leaves"),
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
    if k in ("door", "trapdoor", "button", "pressure_plate", "fence_gate", "chest", "trapped_chest"):
        s["set"] = next((v for pat, v in SETS if re.search(pat, qid)), "oak")
    if k in ("chest", "trapped_chest"):
        s["texture"] = re.sub(r"_(trapped_)?chest$", "", qid)
    if k in ("sign", "wall_sign"):
        s["wood"] = re.sub(r"_(wall_)?sign$", "", qid)
    if k in ("props", "keeper"):
        s["props"] = props
        s["shape"] = first(SHAPES, qid, "full")
    if qid in LIGHT:
        s["light"] = LIGHT[qid]
    if COPPER.fullmatch(qid):
        s["copper"] = True
    if TRANSLUCENT.fullmatch(qid):
        s["render"] = "translucent"
    elif CUTOUT.fullmatch(qid):
        s["render"] = "cutout_mipped" if re.search("leaves|hedge|leaf_carpet|chute", qid) else "cutout"
    if k in ("props", "keeper", "cube") and ("render" in s or s.get("shape", "full") != "full"):
        s["see_through"] = True
    return s

def item_spec(qid):
    if qid.startswith("music_disc_"):
        s = {"id": qid, "kind": "disc"}
    elif qid.startswith("egg_parrot_"):
        s = {"id": qid, "kind": "parrot_egg", "variant": qid[11:]}
    else:
        s = {"id": qid, "kind": ITEM_KINDS.get(qid, "plain")}
    # Registered by the mod before the items; a disc plays the first.
    if sounds := extra_sounds(qid):
        s["sounds"] = sounds
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
    """(models it names: parent and item overrides, texture paths); kept apart since the
    two share path names."""
    refs = [model["parent"]] if isinstance(model.get("parent"), str) else []
    refs += [o["model"] for o in model.get("overrides") or [] if isinstance(o.get("model"), str)]
    tex = [v for v in (model.get("textures") or {}).values()
           if isinstance(v, str) and not v.startswith("#")]
    return refs, tex


def tinted(qid):
    """Whether any model the block's blockstate uses (or its parents) has a tintindex."""
    bs = (OUT / f"assets/{NS}/blockstates/{qid}.json").read_text()
    todo, seen = re.findall(rf'"{NS}:(block/[a-z0-9_/]+)"', bs), set()
    while todo:
        m = todo.pop()
        if m in seen or not (f := OUT / f"assets/{NS}/models/{m}.json").exists():
            continue
        seen.add(m)
        text = f.read_text()
        parent = json.loads(text).get("parent")
        if "tintindex" in text or parent == "minecraft:block/leaves":
            return True
        if isinstance(parent, str) and parent.startswith(f"{NS}:"):
            todo.append(parent.split(":", 1)[1])
    return False


def tint(qid):
    for pat, src in TINT:
        if re.fullmatch(pat, qid):
            return re.sub(pat, src, qid) if "\\" in src else src
    print(f"warning: {qid} has a tinted model but no TINT rule", file=sys.stderr)
    return None


def copy_assets(quark, zeta, ids, items):
    names = set(quark.namelist())
    znames = set(zeta.namelist()) if zeta else set()
    models = [m for q in ids + items for m in EXTRA_MODELS.get(q, [])] + [f"item/{i}" for i in items]
    textures = set()
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
                refs, tex = model_refs(model)
                models += [r.split(":", 1)[1] for r in refs if r.startswith(f"{NS}:")]
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
    # Items' own keys, and the ones under them (item.quark.music_disc_wind.desc).
    for key, text in lang.items():
        if key.startswith("item.quark.") and key[11:].split(".")[0] in items:
            ours[key.replace("item.quark.", f"item.{NS}.", 1)] = text
    sounds = json.loads(quark.read("assets/quark/sounds.json"))
    events = {e: sounds[e] for q in ids + items for e in extra_sounds(q)}
    extra = [k for q in ids + items for k in EXTRA_LANG.get(q, [])]
    extra += [ev["subtitle"] for ev in events.values() if "subtitle" in ev]
    for pat in extra:
        for key in ([k for k in lang if k.startswith(pat[:-1])] if pat.endswith("*") else [pat]):
            ours[key.replace("quark.", f"{NS}.", 1)] = lang[key]
    (OUT / f"assets/{NS}/lang").mkdir(parents=True, exist_ok=True)
    (OUT / f"assets/{NS}/lang/en_us.json").write_text(json.dumps(ours, indent=1, sort_keys=True))
    # Subtitles are lang keys; ours start quarkblocks. like the copied ones above.
    text = json.dumps(events).replace('"quark.subtitles.', f'"{NS}.subtitles.')
    (OUT / f"assets/{NS}/sounds.json").write_text(rename(text))
    for ev in events.values():
        for s in ev["sounds"]:
            name = s["name"] if isinstance(s, dict) else s
            if not name.startswith("quark:"):
                continue  # a vanilla sound file
            path = name.split(":", 1)[1]
            out = OUT / f"assets/{NS}/sounds/{path}.ogg"
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_bytes(quark.read(f"assets/quark/sounds/{path}.ogg"))


def extra_sounds(qid):
    if m := re.fullmatch(r"music_disc_(.+)", qid):
        return [f"ambient.{m[1]}"]
    return EXTRA_SOUNDS.get(qid, [])

def copy_file(src, path, dst_path):
    out = OUT / dst_path
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(src.read(path))


def copy_entity_textures(quark, specs):
    """Textures code draws rather than models: chests (and the atlas listing them),
    sign faces and screens."""
    names = set(quark.namelist())
    chests = {s["texture"] for s in specs if "texture" in s}
    for t in sorted(chests):
        for n in CHEST_TEXTURES:
            copy_file(quark, f"assets/quark/textures/quark_variant_chests/{t}/{n}.png",
                      f"assets/{NS}/textures/quark_variant_chests/{t}/{n}.png")
    if chests:
        # A directory source, so it stitches the folder from every namespace.
        copy_file(quark, "assets/minecraft/atlases/chests.json", "assets/minecraft/atlases/chests.json")
    for w in sorted({s["wood"] for s in specs if "wood" in s}):
        copy_file(quark, f"assets/quark/textures/entity/signs/{w}.png",
                  f"assets/{NS}/textures/entity/signs/{w}.png")
    for t in (t for s in specs for t in EXTRA_TEXTURES.get(s["id"], [])):
        if f"assets/quark/textures/{t}.png" in names:
            copy_file(quark, f"assets/quark/textures/{t}.png", f"assets/{NS}/textures/{t}.png")
        else:
            print(f"warning: texture {t} not found", file=sys.stderr)

#-- Data


def strip_flags(value):
    """Drop Quark's config-flag conditions (always on here), which name a quark: type."""
    if isinstance(value, dict):
        out = {}
        for k, v in value.items():
            if k == "conditions" and isinstance(v, list):
                v = [c for c in v if not (isinstance(c, dict) and {c.get("type"), c.get("condition")}
                                          & {"quark:flag", "zeta:flag"})]
                if not v:
                    continue
            out[k] = strip_flags(v)
        return out
    if isinstance(value, list):
        return [strip_flags(v) for v in value]
    return value


def copy_data(quark, blocks, items):
    names = quark.namelist()
    ids = blocks | items
    keep = lambda q: q in ids or quarkmap.vanilla(q) is not None  # noqa: E731
    tables = [f"blocks/{q}" for q in blocks] + ["misc/monster_box", "misc/monster_box_spawns"]
    for t in tables:
        nm = f"data/quark/loot_tables/{t}.json"
        if nm not in names:
            print(f"warning: no loot table {t}", file=sys.stderr)
            continue
        data = quarkmap.rename_json(strip_flags(json.loads(quark.read(nm))), keep)
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
    for pat in (p for q in sorted(ids) for p in EXTRA_DATA.get(q, [])):
        for nm in sorted(fnmatch.filter(names, f"data/quark/{pat}")):
            data = strip_flags(json.loads(quark.read(nm)))
            out = OUT / nm.replace("data/quark/", f"data/{NS}/", 1)
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(quarkmap.dumps(quarkmap.rename_json(data, keep)))
    # Quark's own tags the ported code reads, as quarkblocks: tags.
    for t in QUARK_TAGS:
        nm = f"data/quark/tags/{t}.json"
        if nm not in names:
            print(f"warning: no tag {t}", file=sys.stderr)
            continue
        values = []
        for v in json.loads(quark.read(nm)).get("values", []):
            vid = v["id"] if isinstance(v, dict) else v
            if vid.lstrip("#").startswith("quark:"):
                if vid.startswith("#") or vid[6:] in ids:
                    values.append(vid.replace("quark:", f"{NS}:", 1))
            else:
                values.append({"id": vid, "required": False})
        out = OUT / f"data/{NS}/tags/{t}.json"
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(quarkmap.dumps({"replace": False, "values": values}))


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
    named = {quarkmap.current(q) for q in quarkmap.used_ids(jars)} | {"monster_box"}
    ids = {q for q in named if quarkmap.vanilla(q) is None
           and f"assets/quark/blockstates/{q}.json" in names}
    items = sorted(q for q in named - ids - LATER_ITEMS if quarkmap.vanilla(q) is None
                   and f"assets/quark/models/item/{q}.json" in names)
    ids |= {b for i in items for b in ITEM_BLOCKS.get(i, [])}
    # A copper vertical slab weathers and waxes into its siblings, so all of them exist.
    if any(COPPER.fullmatch(q) for q in ids):
        ids |= {f"{w}{a}cut_copper_vertical_slab" for w in ("", "waxed_")
                for a in ("", "exposed_", "weathered_", "oxidized_")}
    # A wall sign drops and is placed by its standing sign's item.
    ids |= {q.replace("_wall_sign", "_sign") for q in ids if q.endswith("_wall_sign")}
    ids = sorted(q for q in ids if f"assets/quark/blockstates/{q}.json" in names)
    print(f"{len(ids)} blocks, {len(items)} items; {len(named) - len(ids) - len(items)} other ids"
          " (mobs, vanilla-mapped, not ported)")
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
    (OUT / "pack.mcmeta").write_text(json.dumps(PACK))
    copy_assets(quark, zeta, ids, items)
    item_specs = [item_spec(i) for i in items]
    (OUT / NS / "items.json").write_text(json.dumps(item_specs, indent=1))
    copy_entity_textures(quark, specs + item_specs)
    copy_data(quark, set(ids), set(items))
    for s in specs:
        if tinted(s["id"]) and (src := tint(s["id"])):
            s["tint"] = src
    (OUT / NS / "blocks.json").write_text(json.dumps(specs, indent=1))
    counts = {}
    for s in specs:
        counts[s["kind"]] = counts.get(s["kind"], 0) + 1
    print("kinds:", dict(sorted(counts.items(), key=lambda x: -x[1])))


if __name__ == "__main__":
    main()
