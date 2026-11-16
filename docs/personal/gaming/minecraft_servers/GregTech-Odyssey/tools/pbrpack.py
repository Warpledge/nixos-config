#!/usr/bin/env python3
"""Generate a LabPBR specular pack for GTCEu and gtocore blocks from their jars.

Usage:
    nix-shell -p 'python3.withPackages(p: [p.pillow])' --run \\
        "python3 -I <this file> <mods folder> [-n] [--replace] [-o <zip>]"

Reads every block texture under assets/{gtceu,gtocore}/textures/block/ in the gtceu and
gtocore jars (gtocore's copy wins on the same path) and writes only generated _s.png maps,
plus an _s.png.mcmeta carrying the base texture's animation, to
resourcepacks/Warpledge GT PBR.zip beside <mods folder>. Nothing from the jars is copied.
Rerun after a GTO update. 0.6.0/shaders.md explains the values; tune the tables below.
"""

import argparse
import io
import json
import re
import sys
import zipfile
from collections import Counter
from pathlib import Path

from PIL import Image

PACK_NAME = "Warpledge GT PBR.zip"
PACK = {"pack": {"pack_format": 15, "description": "warpledge GT emissives + reflections"}}
JARS = ("gtceu-*.jar", "gtocore-*.jar")  # later wins on the same texture path
TEXTURE = re.compile(r"^assets/(gtceu|gtocore)/textures/block/(.+)\.png$")

#-- Rules, matched against the path under textures/block/

EMISSIVE = re.compile(r"_emissive|_bloom")
REFLECTIVE = re.compile(r"^(casings|coil)/")
MATTE = re.compile(
    r"glass|transparent|wood|brick|stone|concrete|plascrete|sign|crafting_table"
    r"|filter|cleanroom|magic|mana|asphalt|plank|wool|leather|cold_ice|tile|bio"
    r"|create_casing"
)
PLASTIC = re.compile(r"abs_|ptfe|polybenzimidazole|plastic|rubber|pvc")

#--- Values (LabPBR: R smoothness, G F0, B porosity, A emission with 255 = none)
# Metal: close to Neon Horizons' GT casings; the darkest pixels of a texture get the
# low end, so grooves and rivets read rougher than plates.
METAL_SMOOTH = (200, 232)
METAL_F0 = (120, 150)
PLASTIC_SMOOTH, PLASTIC_F0 = 150, 10
# Emission scales with pixel brightness from EMIT_MIN to 254, times the pixel's alpha;
# unlit pixels get 0, as in KuramA's GTNH packs.
EMIT_MIN = 100


def lerp(lo, hi, t):
    return round(lo + (hi - lo) * t)


def pixels(im):
    # getdata is deprecated from Pillow 12 and goes in 14.
    flat = getattr(im, "get_flattened_data", None)
    return list(flat() if flat else im.getdata())


def emissive_map(im):
    out = []
    for r, g, b, a in pixels(im):
        if a == 0:
            out.append((0, 0, 0, 0))
            continue
        e = lerp(EMIT_MIN, 254, max(r, g, b) / 255) * a // 255
        out.append((0, 0, 0, max(1, e)))
    return out


def reflective_map(im, plastic):
    px = pixels(im)
    if plastic:
        return [(PLASTIC_SMOOTH, PLASTIC_F0, 0, 255) if p[3] else (0, 0, 0, 255) for p in px]
    lum = [0.2126 * r + 0.7152 * g + 0.0722 * b for r, g, b, _ in px]
    lo, hi = min(lum), max(lum)
    span = (hi - lo) or 1.0
    out = []
    for (_, _, _, a), v in zip(px, lum):
        t = (v - lo) / span
        if a == 0:
            out.append((0, 0, 0, 255))
        else:
            out.append((lerp(*METAL_SMOOTH, t), lerp(*METAL_F0, t), 0, 255))
    return out


def classify(rel):
    if EMISSIVE.search(rel):
        return "emissive"
    if REFLECTIVE.search(rel) and not MATTE.search(rel):
        return "plastic" if PLASTIC.search(rel) else "metal"
    return None


def textures(mods):
    """{zip path: (jar, mcmeta zip path or None)}, later jars overriding earlier."""
    found = {}
    for pattern in JARS:
        jars = sorted(mods.glob(pattern))
        if not jars:
            sys.exit(f"no {pattern} in {mods}")
        for jar in jars:
            with zipfile.ZipFile(jar) as z:
                names = set(z.namelist())
            for name in names:
                if TEXTURE.match(name) and not re.search(r"_[sn]\.png$", name):
                    meta = name + ".mcmeta"
                    found[name] = (jar, meta if meta in names else None)
    return found


def build(mods, dry_run):
    counts, files = Counter(), {}
    by_jar = {}
    for name, (jar, meta) in textures(mods).items():
        kind = classify(TEXTURE.match(name).group(2))
        if kind:
            by_jar.setdefault(jar, []).append((name, meta, kind))
    for jar, items in by_jar.items():
        with zipfile.ZipFile(jar) as z:
            for name, meta, kind in items:
                im = Image.open(io.BytesIO(z.read(name))).convert("RGBA")
                if kind == "emissive" and im.getextrema()[3][1] == 0:
                    counts["skipped, blank"] += 1
                    continue
                counts[kind] += 1
                if dry_run:
                    continue
                data = emissive_map(im) if kind == "emissive" else reflective_map(
                    im, kind == "plastic"
                )
                spec = Image.new("RGBA", im.size)
                spec.putdata(data)
                buf = io.BytesIO()
                spec.save(buf, "PNG", optimize=True)
                base = name[: -len(".png")]
                files[base + "_s.png"] = buf.getvalue()
                anim = json.loads(z.read(meta)).get("animation") if meta else None
                if anim is not None:
                    # Oculus squashes an animated strip into one frame without this.
                    files[base + "_s.png.mcmeta"] = json.dumps({"animation": anim})
    return counts, files


def main():
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("mods", type=Path, help="the instance's mods folder")
    p.add_argument("-o", "--out", type=Path, help=f"default: ../resourcepacks/{PACK_NAME}")
    p.add_argument("-n", "--dry-run", action="store_true", help="count, write nothing")
    p.add_argument("--replace", action="store_true", help="overwrite an existing pack")
    a = p.parse_args()
    mods = a.mods.expanduser().resolve()
    out = a.out or mods.parent / "resourcepacks" / PACK_NAME
    if out.exists() and not (a.replace or a.dry_run):
        sys.exit(f"{out} exists; pass --replace")
    counts, files = build(mods, a.dry_run)
    for kind, n in sorted(counts.items()):
        print(f"{kind:>16}: {n}")
    if a.dry_run:
        print(f"would write {out}")
        return
    part = out.with_name(out.name + ".part")
    out.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(part, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("pack.mcmeta", json.dumps(PACK, indent=2))
        for name in sorted(files):
            z.writestr(name, files[name])
    part.replace(out)
    print(f"wrote {out} ({len(files)} files)")


if __name__ == "__main__":
    main()
