#!/usr/bin/env python3
"""Drop mixins, or other JSON list entries, that break against the pack from jars.

Usage:
    python3 -I <this file> <mods folder>

Each entry in PATCHES names a jar, a JSON file in it, the lists in that file and the
entries to remove from them. A jar already patched, or missing, is left alone. Rerun
after updating one of these mods, or after a new pack build for a pack jar;
0.6.0/mods.md says why each is dropped.
"""

import json
import os
import sys
import tempfile
import zipfile
from pathlib import Path

MIXIN_LISTS = [("mixins",), ("client",), ("server",)]

# (jar glob, JSON file, paths to the lists in it, entries to drop)
PATCHES = [
    # Targets a JEI field the pack's JEI (15.59) lacks. It applies whenever JEI is
    # installed, and dev27 ships JEI beside EMI, so it fails and leaves JEI's
    # RecipeTransferButton unloadable. Its EMI hook stays.
    ("*maid_storage_manager-*.jar", "maid_storage_manager.mixins.json", MIXIN_LISTS,
     ["JEIRecipeTransferHook"]),
    # Wraps a call Better Advancements 0.6.0.73 no longer makes; the config is
    # required, so the game crashes. It only labels Youkai's advancement criteria.
    ("youkaishomecoming-*.jar", "youkaishomecoming.mixins.json", MIXIN_LISTS,
     ["CriterionGridMixin"]),
    # A pack jar. JECh swaps Searchables' StringUtils.containsIgnoreCase for its
    # case-sensitive pinyin match, so Controlling's key bind search finds nothing.
    ("jecharacters-*.jar", "me/towdium/jecharacters/targets.json",
     [("contains", "default")],
     ["com.blamejared.searchables.api.SearchableComponent:lambda$create$2"
      "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/Boolean;"]),
]


def lists(cfg, paths):
    for path in paths:
        node = cfg
        for key in path[:-1]:
            node = node.get(key) or {}
        if node.get(path[-1]):
            yield node, path[-1]


def patch(jar, config, paths, drop):
    with zipfile.ZipFile(jar) as z:
        cfg = json.loads(z.read(config))
        gone = [m for node, k in lists(cfg, paths) for m in node[k] if m in drop]
        if not gone:
            print(f"{jar.name}: already patched")
            return
        for node, k in lists(cfg, paths):
            node[k] = [m for m in node[k] if m not in drop]
        fd, tmp = tempfile.mkstemp(dir=jar.parent, suffix=".tmp")
        os.close(fd)
        with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as out:
            for info in z.infolist():
                data = z.read(info)
                if info.filename == config:
                    data = (json.dumps(cfg, indent=2) + "\n").encode()
                out.writestr(info, data)
    os.replace(tmp, jar)
    print(f"{jar.name}: removed {', '.join(gone)}")


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    mods = Path(sys.argv[1]).expanduser()
    for pattern, config, paths, drop in PATCHES:
        jars = sorted(mods.glob(pattern))
        if len(jars) > 1:
            sys.exit(f"more than one {pattern} in {mods}")
        if jars:
            patch(jars[0], config, paths, drop)


if __name__ == "__main__":
    main()
