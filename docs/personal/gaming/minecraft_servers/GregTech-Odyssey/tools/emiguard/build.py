#!/usr/bin/env python3
"""Build the emiguard jar and copy it into an instance's mods folder.

Usage:
    python3 -I <this file> <mods folder>

Compiles against the GTO EMI fork jar found in <mods folder> (emi-forge-*.jar) with
nixpkgs' JDK 21 (the fork is Java 21 bytecode) and Gradle 8 through nix-shell, and copies
build/libs/emiguard-<version>.jar into <mods folder>. The plugin only loads once
warpledge.emiguard.EmiGuardPlugin is listed under misc.enableEmiJeiExternalPlugins in
the instance's config/gtocore.yaml.
"""

import argparse
import shlex
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("mods", type=Path)
    a = ap.parse_args()
    emi = sorted(a.mods.glob("emi-forge-*.jar"))
    if not emi:
        sys.exit(f"no emi-forge-*.jar in {a.mods}")
    gradle = ("export JAVA_HOME=$(dirname $(dirname $(readlink -f $(command -v java)))); "
              "gradle build --no-daemon --console=plain -q "
              f"-Pemi_jar={shlex.quote(str(emi[-1].resolve()))}")
    subprocess.run(["nix-shell", "-p", "jdk21", "gradle_8", "--run", gradle], cwd=HERE, check=True)
    jars = sorted((HERE / "build" / "libs").glob("emiguard-*.jar"))
    if not jars:
        sys.exit("gradle built no jar")
    for old in a.mods.glob("emiguard-*.jar"):
        if old.name != jars[-1].name:
            print(f"replacing {old.name}")
            old.unlink()
    shutil.copy2(jars[-1], a.mods / jars[-1].name)
    print(f"copied {jars[-1].name} to {a.mods}")


if __name__ == "__main__":
    main()
