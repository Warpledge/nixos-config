#!/usr/bin/env python3
"""Build Eclipse-Shader Warpledge Edit.zip from the ChromaPatch-built KuraEdit pack.

Usage, from .minecraft with the game closed:
    python3 -I <this file> "shaderpacks/Eclipse-Shader KuraEdit [OBS07-Chroma Patch].zip"

Writes "Eclipse-Shader Warpledge Edit.zip" beside the input and refuses to overwrite it.
Eclipse is "All rights reserved", so this file holds only short anchors to find each
spot and the lines it adds; shaders.md explains each edit.
"""

import os
import sys
import zipfile

OUT_NAME = "Eclipse-Shader Warpledge Edit.zip"
MARKER = "Warpledge:"


def line_index(lines, fragment, start=0):
    """Index of the only line at or after start that contains fragment."""
    hits = [i for i in range(start, len(lines)) if fragment in lines[i]]
    if len(hits) != 1:
        sys.exit(f"anchor {fragment!r} matched {len(hits)} lines, expected 1")
    return hits[0]


def emission_fix(text):
    """all_solid.fsh: only glow where the full-size glow map glows."""
    lines = text.split("\n")
    i = line_index(lines, "SpecularTex = texture_POMSwitch(specular")
    add = [
        "",
        "\t\t\t// Warpledge: labPBR alpha 255 means no glow, so mipmaps averaging it with a"
        " glowing texel",
        "\t\t\t// read as nearly full glow. Only glow where the full size texture does,"
        " as Complementary does.",
        "\t\t\tfloat warpledgeEmissionL0 = textureLod(specular, adjustedTexCoord.xy,"
        " 0.0).a;",
        "\t\t\tif(warpledgeEmissionL0 >= 254.5/255.0 || SpecularTex.a >= 254.5/255.0)"
        " SpecularTex.a = 1.0;",
        "\t\t\telse SpecularTex.a = min(SpecularTex.a, warpledgeEmissionL0);",
    ]
    return "\n".join(lines[: i + 1] + add + lines[i + 1 :])


def lod_taa(text):
    """composite6.fsh: steadier anti-aliasing on Distant Horizons LOD pixels."""
    lines = text.split("\n")
    lod = "depthCheck && texture(dhVoxyDepthTex, adjTC).x < 1.0"
    a = line_index(lines, "colMin = 0.5 * (colMin")
    b = line_index(lines, "colMax = 0.5 * (colMax", a)
    if b != a + 1:
        sys.exit("colMin and colMax lines are no longer next to each other")
    before = [
        "\t\t#if defined DISTANT_HORIZONS || defined VOXY",
        "\t\t// Warpledge: LOD pixels keep the full 3x3 range, so thin bright detail keeps"
        " its history.",
        f"\t\tif(!({lod}))",
        "\t\t{",
        "\t\t#endif",
    ]
    after = ["\t\t#if defined DISTANT_HORIZONS || defined VOXY", "\t\t}", "\t\t#endif"]
    lines = lines[:a] + before + lines[a : b + 1] + after + lines[b + 1 :]
    c = line_index(lines, "blendingFactor = clamp(blendingFactor + luma(")
    blend = [
        "\t#if defined DISTANT_HORIZONS || defined VOXY",
        "\t// Warpledge: LOD pixels use a steady blend; the ratio below drops history on"
        " dark, high contrast detail.",
        f"\tif({lod}) blendingFactor = 0.1;",
        "\telse",
        "\t#endif",
    ]
    return "\n".join(lines[:c] + blend + lines[c:])


def menu_row(text):
    """shaders.properties: drop the blank row below ChromaPatch's Atmosphere row."""
    lines = text.split("\n")
    i = line_index(lines, "[Atmosphere] <empty>")
    if lines[i + 1].split() != ["<empty>", "<empty>", "\\"]:
        sys.exit("the row after [Atmosphere] is not the blank row any more")
    return "\n".join(lines[: i + 1] + lines[i + 2 :])


EDITS = {
    "shaders/dimensions/all_solid.fsh": emission_fix,
    "shaders/dimensions/composite6.fsh": lod_taa,
    "shaders/shaders.properties": menu_row,
}


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    src = sys.argv[1]
    dst = os.path.join(os.path.dirname(os.path.abspath(src)), OUT_NAME)
    if os.path.exists(dst):
        sys.exit(f"{dst} exists; move it aside first")
    with zipfile.ZipFile(src) as zin:
        names = zin.namelist()
        for name in EDITS:
            if name not in names:
                sys.exit(f"{name} missing from {src}")
            if MARKER in zin.read(name).decode():
                sys.exit(f"{name} is already edited; start from the KuraEdit pack")
        with zipfile.ZipFile(dst + ".part", "w", zipfile.ZIP_DEFLATED) as zout:
            for info in zin.infolist():
                data = zin.read(info)
                if info.filename in EDITS:
                    data = EDITS[info.filename](data.decode()).encode()
                zout.writestr(info, data)
    with zipfile.ZipFile(dst + ".part") as check:
        if check.testzip() is not None:
            sys.exit("the written zip failed its check")
    os.replace(dst + ".part", dst)
    print(f"wrote {dst}")


if __name__ == "__main__":
    main()
