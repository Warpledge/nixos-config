#!/usr/bin/env python3
"""Drop mixins that break against the pack's mods from added jars.

Usage:
    python3 -I <this file> <mods folder>

Each entry in PATCHES names a jar, its mixin config and the mixins to remove from it.
A jar already patched, or missing, is left alone. Rerun after updating one of these
mods; 0.6.0/mods.md says why each is dropped.
"""

import json
import os
import sys
import tempfile
import zipfile
from pathlib import Path

# (jar glob, mixin config, mixins to drop)
PATCHES = [
    # Targets a JEI field the pack's JEI (15.59) lacks. It applies whenever JEI is
    # installed, and dev27 ships JEI beside EMI, so it fails and leaves JEI's
    # RecipeTransferButton unloadable. Its EMI hook stays.
    ("*maid_storage_manager-*.jar", "maid_storage_manager.mixins.json",
     ["JEIRecipeTransferHook"]),
    # Wraps a call Better Advancements 0.6.0.73 no longer makes; the config is
    # required, so the game crashes. It only labels Youkai's advancement criteria.
    ("youkaishomecoming-*.jar", "youkaishomecoming.mixins.json",
     ["CriterionGridMixin"]),
]


def patch(jar, config, drop):
    with zipfile.ZipFile(jar) as z:
        cfg = json.loads(z.read(config))
        gone = [m for k in ("mixins", "client", "server") for m in cfg.get(k) or []
                if m in drop]
        if not gone:
            print(f"{jar.name}: already patched")
            return
        for k in ("mixins", "client", "server"):
            if cfg.get(k):
                cfg[k] = [m for m in cfg[k] if m not in drop]
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
    for pattern, config, drop in PATCHES:
        jars = sorted(mods.glob(pattern))
        if len(jars) > 1:
            sys.exit(f"more than one {pattern} in {mods}")
        if jars:
            patch(jars[0], config, drop)


if __name__ == "__main__":
    main()
