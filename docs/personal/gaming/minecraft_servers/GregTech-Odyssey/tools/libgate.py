#!/usr/bin/env python3
"""Gate Create and Supplementaries behind GT; fit the Integrated mods to the pack.

Usage:
    python3 -I <this file> <mods folder>

Create and Supplementaries are in the pack only as block libraries for the Integrated
structures, and Quark (which breaks GTO's EMI) is replaced by the quarkblocks jar
(build it first: quarkblocks/build.py). From the jars in <mods folder> this writes:

- reliable/reliable_remover/create.json: bans Create's machines, parts and tools
  (hidden, recipes, loot and drops stripped) and blocks right-clicking the processing
  machines (PROCESSING) where a structure placed them. Decor in KEEP stays.
- reliable/reliable_recipes/*.json: removes Create's machine recipe types and every
  crafting recipe in Create or Supplementaries that makes another mod's or vanilla's
  item.
- datapack/warpledge-gto/data/create/forge/biome_modifier/*.json: Create's zinc ore
  and stone layers off.
- datapack/warpledge-gto-integrated/, a separate pack (gitignored, since it holds the
  mods' own templates):
  - data/minecraft/tags/worldgen/structure/village.json: the village tag with every
    entry optional, since Integrated Villages 1.3.2 names a swamp_village it doesn't
    ship and that fails the whole tag.
  - every template and data file of IDAS, Dungeons Arise, Seven Seas and Integrated
    Villages that names Quark, renamed through quarkmap.py, plus the rest of
    Integrated Dungeons Arise's data (quarkmap.WHOLE_DATA says why).

It also patches those mods' jars in place so Quark is optional. `gto datapack`
installs both packs. Rerun after updating any of these mods. 0.6.0/mods.md explains
the choices.
"""

import argparse
import gzip
import json
import os
import re
import shutil
import sys
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import nbt  # noqa: E402
import quarkmap  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
RELIABLE = ROOT / "reliable"
PACK = ROOT / "datapack" / "warpledge-gto" / "data"
# Names the Integrated mods' structures, so a world without them fails to load;
# `gto datapack` installs it only when Integrated API is in mods/.
INTEGRATED = ROOT / "datapack" / "warpledge-gto-integrated"

#-- What stays

# Create items kept: decor and materials that bypass nothing once the machines are gone.
STONES = (
    "granite|diorite|andesite|limestone|calcite|dripstone|deepslate|tuff|scoria|"
    "scorchia|ochrum|veridium|crimsite|asurine"
)
KEEP = [
    rf"(cut_|polished_cut_|small_|layered_)?({STONES})(_bricks?)?(_slab|_stairs|_wall)?",
    rf"({STONES})_pillar",
    r".*_window(_pane)?",
    r".*framed_glass.*|tiled_glass(_pane)?",
    r".*_(seat|sail|table_cloth|toolbox)|sail_frame",
    r".*_(ladder|bars|door|trapdoor|scaffolding)",
    r".*copper_(shingle|tile)s?(_slab|_stairs)?",
    r".*_casing|copycat_.*|metal_girder|placard|clipboard",
    r"industrial_iron_block|weathered_iron_block",
    r"rose_quartz(_block|_lamp|_tiles)?|polished_rose_quartz|small_rose_quartz_tiles",
    r"(andesite_alloy|brass|zinc|raw_zinc|copper|experience)_block|andesite_alloy",
    r"(zinc|brass)_(ingot|nugget|sheet)|copper_(nugget|sheet)|iron_sheet|golden_sheet",
    r"raw_zinc|zinc_ore|deepslate_zinc_ore|crushed_raw_.*|experience_nugget",
    r"(peculiar|haunted|desk)_bell|cuckoo_clock|nixie_tube",
    r"wheat_flour|dough|sweet_roll|bar_of_chocolate|chocolate_glazed_berries",
    r"honeyed_apple|builders_tea|blaze_cake.*|cinder_flour|powdered_obsidian",
]
KEEP_RE = re.compile("|".join(f"(?:{p})" for p in KEEP))

# Placed machines in structures that can't be right-clicked. The rest (cranks, levers,
# valve handles, contraption controls) stay usable, since structures' doors and
# contraptions run on them; banned items still can't be carried off.
PROCESSING = re.compile(
    r"millstone|crushing_wheel.*|mechanical_(press|mixer|crafter|saw|drill|harvester|"
    r"plough|roller|arm)|basin|(lit_|empty_)?blaze_burner|deployer|encased_fan|spout|"
    r"item_drain|schematicannon|schematic_table")

# Create's machine recipe types; with the machines banned they only clutter EMI.
CREATE_TYPES = [
    "crushing", "milling", "mixing", "compacting", "pressing", "splashing", "haunting",
    "deploying", "filling", "emptying", "cutting", "sequenced_assembly",
    "mechanical_crafting", "item_application", "sandpaper_polishing", "basin",
]

#-- Jar reading


def jar_for(mods, prefix):
    hits = sorted(p for p in mods.glob("*.jar") if p.name.lower().startswith(prefix))
    if not hits:
        raise SystemExit(f"no jar starting with {prefix!r} in {mods}")
    return hits[-1]


def create_items(jar):
    with zipfile.ZipFile(jar) as z:
        names = z.namelist()
        lang = json.loads(z.read("assets/create/lang/en_us.json"))
    item = re.compile(r"assets/create/models/item/([a-z0-9_]+)\.json$")
    state = re.compile(r"assets/create/blockstates/([a-z0-9_]+)\.json$")
    # Item models include overlays and states (armour trims, clipboard_0) that aren't
    # items; a lang name marks a real one.
    named = {k.split(".", 2)[2] for k in lang if re.fullmatch(r"(item|block)\.create\.\w+", k)}
    items = {m[1] for n in names if (m := item.match(n))} & named
    blocks = {m[1] for n in names if (m := state.match(n))}
    return sorted(items), blocks


def foreign_crafting(jar, ns):
    """Ids of crafting recipes in ns that make another namespace's item from others'.

    A recipe using one of ns's own items stays, so crates and blocks still uncraft.
    """
    out = []
    pat = re.compile(rf"data/{ns}/recipes/(.+)\.json$")
    with zipfile.ZipFile(jar) as z:
        for n in z.namelist():
            if not (m := pat.match(n)):
                continue
            try:
                r = json.loads(z.read(n))
            except ValueError:
                continue
            if not str(r.get("type", "")).startswith("minecraft:crafting"):
                continue
            res = r.get("result")
            rid = res.get("item") if isinstance(res, dict) else res
            inputs = json.dumps({k: r.get(k) for k in ("key", "ingredients")})
            if (isinstance(rid, str) and not rid.startswith(f"{ns}:")
                    and f'"{ns}:' not in inputs):
                out.append(f"{ns}:{m[1]}")
    return sorted(out)


def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n")
    print("wrote", path.relative_to(ROOT))

#-- Outputs


def gate_create(mods):
    items, blocks = create_items(jar_for(mods, "create-"))
    banned = [i for i in items if not KEEP_RE.fullmatch(i)]
    kept = len(items) - len(banned)
    print(f"create: {len(banned)} banned, {kept} kept")
    write(RELIABLE / "reliable_remover" / "create.json", [
        {"action": "remove", "items": [f"create:{i}" for i in banned]},
        {"action": "remove_interactions",
         "blocks": [f"create:{i}" for i in sorted(blocks) if PROCESSING.fullmatch(i)]},
    ])
    rules = [{"action": "remove_recipe", "type": f"create:{t}"} for t in CREATE_TYPES]
    ids = foreign_crafting(jar_for(mods, "create-"), "create")
    if ids:
        rules.append({"action": "remove_recipe", "id": ids})
    write(RELIABLE / "reliable_recipes" / "create.json", rules)


def gate_crafting(mods, prefix, ns):
    ids = foreign_crafting(jar_for(mods, prefix), ns)
    print(f"{ns}: {len(ids)} recipes for other mods' items removed")
    write(RELIABLE / "reliable_recipes" / f"{ns}.json",
          [{"action": "remove_recipe", "id": ids}])


def create_worldgen(mods):
    """Switch off Create's zinc ore and stone layers; GT's veins own ore generation."""
    pat = re.compile(r"data/create/forge/biome_modifier/(.+\.json)$")
    with zipfile.ZipFile(jar_for(mods, "create-")) as z:
        for n in z.namelist():
            if m := pat.match(n):
                write(PACK / "create" / "forge" / "biome_modifier" / m[1],
                      {"type": "forge:none"})


def village_tag(mods):
    """Merge every jar's village tag into one with optional entries."""
    path = "data/minecraft/tags/worldgen/structure/village.json"
    entries = []
    for jar in sorted(mods.glob("*.jar")):
        with zipfile.ZipFile(jar) as z:
            if path not in z.namelist():
                continue
            for v in json.loads(z.read(path)).get("values", []):
                vid = v["id"] if isinstance(v, dict) else v
                if vid not in entries:
                    entries.append(vid)
    vanilla = [f"minecraft:village_{b}" for b in
               ("plains", "desert", "savanna", "snowy", "taiga")]
    # replace: true, since tags merge across packs and the jar's bad entry would stay.
    ids = list(dict.fromkeys(vanilla + entries))
    write(INTEGRATED / "data" / "minecraft" / "tags" / "worldgen" / "structure"
          / "village.json",
          {"replace": True, "values": [{"id": v, "required": False} for v in ids]})


#-- Quark out, quarkblocks in

QUARKBLOCKS = (Path(__file__).resolve().parent / "quarkblocks" / "src" / "generated"
               / "resources" / "quarkblocks" / "blocks.json")


def jar_blocks():
    if not QUARKBLOCKS.is_file():
        raise SystemExit("no quarkblocks/blocks.json; build the jar first (quarkblocks/build.py)")
    return {s["id"] for s in json.loads(QUARKBLOCKS.read_text())}


def rename_strings(tag):
    """Every quark: string inside an NBT tag, renamed like the blocks (item ids, loot)."""
    if tag.type == nbt.STRING and tag.value.startswith(("quark:", "#quark:")):
        return nbt.string(quarkmap.rename_id(tag.value))
    if tag.type == nbt.COMPOUND:
        return nbt.Tag(nbt.COMPOUND, {k: rename_strings(v) for k, v in tag.value.items()})
    if tag.type == nbt.LIST:
        et, items = tag.value
        return nbt.Tag(nbt.LIST, (et, [rename_strings(v) for v in items]))
    return tag


def rename_template(root, ours, missing):
    """Rewrite one template's palettes, block entities and entities in place."""
    c = root.value
    pals = [p for key in ("palette", "palettes") if key in c
            for p in ([c[key]] if key == "palette" else c[key].value[1])]
    for pal in pals:
        for i, entry in enumerate(pal.value[1]):
            e = entry.value
            name = e["Name"].value
            if not name.startswith("quark:"):
                continue
            qid = name[6:]
            if (v := quarkmap.vanilla(qid)) is not None:
                e["Name"] = nbt.string(v[0])
                if "Properties" in e:
                    kept = {k: t for k, t in e["Properties"].value.items() if k in v[1]}
                    e["Properties"] = nbt.Tag(nbt.COMPOUND, kept)
            elif qid in ours:
                e["Name"] = nbt.string(f"{quarkmap.NS}:{qid}")
            else:
                missing.add(qid)
                pal.value[1][i] = nbt.Tag(nbt.COMPOUND, {"Name": nbt.string("minecraft:air")})
    for b in c.get("blocks", nbt.Tag(nbt.LIST, (0, []))).value[1]:
        data = b.value.get("nbt")
        if data is None:
            continue
        bid = data.value.get("id")
        if bid is not None and bid.value in quarkmap.BLOCK_ENTITIES:
            data.value["id"] = nbt.string(quarkmap.BLOCK_ENTITIES[bid.value])
        b.value["nbt"] = rename_strings(data)
    if "entities" in c:
        et, ents = c["entities"].value
        kept = [x for x in ents
                if not str(nbt.plain(x).get("nbt", {}).get("id", "")).startswith("quark:")]
        # Vanilla entities can still hold Quark items (item frames) or ride Quark mobs.
        c["entities"] = nbt.Tag(nbt.LIST, (et, [rename_strings(x) for x in kept]))
        return len(ents) - len(kept)
    return 0


def quark_values(tag):
    """Count quark: string values left in a tag; Quark's own key names don't matter."""
    if tag.type == nbt.STRING:
        return int(tag.value.startswith(("quark:", "#quark:")))
    if tag.type == nbt.COMPOUND:
        return sum(quark_values(v) for v in tag.value.values())
    if tag.type == nbt.LIST:
        return sum(quark_values(v) for v in tag.value[1])
    return 0


def unquark(mods):
    """Write the Integrated mods' Quark-naming templates and JSON into the integrated pack."""
    ours = jar_blocks()
    keep = lambda q: q in ours or quarkmap.vanilla(q) is not None  # noqa: E731
    missing, templates, files, dropped, whole = set(), 0, 0, 0, 0
    for jar in quarkmap.integrated_jars(mods):
        all_data = jar.name.lower().startswith(quarkmap.WHOLE_DATA)
        with zipfile.ZipFile(jar) as z:
            for n in z.namelist():
                if all_data and n.startswith("data/") and not n.endswith("/"):
                    raw = z.read(n)
                    body = gzip.decompress(raw) if n.endswith(".nbt") else raw
                    if b"quark:" not in body:
                        out = INTEGRATED / n
                        out.parent.mkdir(parents=True, exist_ok=True)
                        out.write_bytes(raw)
                        whole += 1
                        continue
                if n.endswith(".nbt") and "/structures/" in n:
                    raw = z.read(n)
                    if b"quark:" not in gzip.decompress(raw):
                        continue
                    name, root = nbt.load(raw)
                    dropped += rename_template(root, ours, missing)
                    out = INTEGRATED / n
                    out.parent.mkdir(parents=True, exist_ok=True)
                    out.write_bytes(nbt.dump(name, root))
                    templates += 1
                elif n.startswith("data/") and n.endswith(".json"):
                    raw = z.read(n)
                    if b"quark:" not in raw:
                        continue
                    # Minecraft's lenient reader takes raw tabs and // comment lines.
                    text = re.sub(r"^\s*//.*$", "", raw.decode(), flags=re.M)
                    data = quarkmap.rename_json(json.loads(text, strict=False), keep)
                    out = INTEGRATED / n
                    out.parent.mkdir(parents=True, exist_ok=True)
                    out.write_text(quarkmap.dumps(data))
                    files += 1
    print(f"integrated pack: {templates} templates and {files} data files renamed, "
          f"{dropped} Quark entities (item frames and such) dropped, "
          f"{whole} more of IDA's files copied so they win over WDA's")
    if missing:
        print(f"  not in quarkblocks, placed as air: {', '.join(sorted(missing))}")
    left = [p for p in INTEGRATED.rglob("*.nbt") if quark_values(nbt.load(p.read_bytes())[1])]
    left += [p for p in INTEGRATED.rglob("*.json") if b'"quark:' in p.read_bytes()]
    if left:
        raise SystemExit(f"quark: ids left in {len(left)} files, e.g. {left[0]}")


def patch_requires_quark(mods):
    """Make Quark optional in the Integrated jars' mods.toml; they're data only."""
    block = re.compile(r'(\[\[dependencies\.[a-z_]+\]\][^\[]*?modId\s*=\s*"quark"[^\[]*?)'
                       r"mandatory\s*=\s*true")
    for jar in quarkmap.integrated_jars(mods):
        with zipfile.ZipFile(jar) as z:
            toml = z.read("META-INF/mods.toml").decode()
            new = block.sub(r"\1mandatory=false", toml)
            if new == toml:
                continue
            tmp = jar.with_suffix(".jar.tmp")
            with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as out:
                for info in z.infolist():
                    data = new.encode() if info.filename == "META-INF/mods.toml" else z.read(info)
                    out.writestr(info, data)
        os.replace(tmp, jar)
        print(f"patched {jar.name}: Quark is optional")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("mods", type=Path)
    a = ap.parse_args()
    # Generated whole from the jars each run, so a template a mod dropped doesn't linger.
    if INTEGRATED.exists():
        shutil.rmtree(INTEGRATED)
    gate_create(a.mods)
    create_worldgen(a.mods)
    gate_crafting(a.mods, "supplementaries-", "supplementaries")
    village_tag(a.mods)
    if quarkmap.integrated_jars(a.mods):
        unquark(a.mods)
        patch_requires_quark(a.mods)
    write(INTEGRATED / "pack.mcmeta", {"pack": {
        "pack_format": 15, "description": "warpledge GTO Integrated worldgen fixes"}})


if __name__ == "__main__":
    main()
