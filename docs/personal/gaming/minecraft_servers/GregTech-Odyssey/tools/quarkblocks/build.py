#!/usr/bin/env python3
"""Build the quarkblocks jar and copy it into an instance's mods folder.

Usage:
    python3 -I <this file> <Quark jar> <mods folder> [--zeta <Zeta jar>]

Runs gen.py against the Integrated mods' jars in <mods folder>, builds with nixpkgs'
JDK 17 and Gradle 8 through nix-shell (the first build downloads Forge, about a
minute), and copies build/libs/quarkblocks-<version>.jar into <mods folder>. Rerun
after updating an Integrated mod, then rerun libgate.py, which reads blocks.json.
"""

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
GRADLE = ("export JAVA_HOME=$(dirname $(dirname $(readlink -f $(command -v java)))); "
          "gradle build --no-daemon --console=plain -q")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("quark", type=Path)
    ap.add_argument("mods", type=Path)
    ap.add_argument("--zeta", type=Path)
    a = ap.parse_args()
    gen = [sys.executable, "-I", str(HERE / "gen.py"), str(a.quark), str(a.mods)]
    if a.zeta:
        gen += ["--zeta", str(a.zeta)]
    subprocess.run(gen, check=True)
    subprocess.run(["nix-shell", "-p", "jdk17", "gradle_8", "--run", GRADLE], cwd=HERE, check=True)
    jars = sorted((HERE / "build" / "libs").glob("quarkblocks-*.jar"))
    if not jars:
        sys.exit("gradle built no jar")
    for old in a.mods.glob("quarkblocks-*.jar"):
        if old.name != jars[-1].name:
            print(f"replacing {old.name}")
            old.unlink()
    shutil.copy2(jars[-1], a.mods / jars[-1].name)
    print(f"copied {jars[-1].name} to {a.mods}")


if __name__ == "__main__":
    main()
