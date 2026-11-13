#!/usr/bin/env python3
"""Replace classes in added jars with patched versions compiled from classpatch/.

Usage:
    python3 -I <this file> <mods folder>

Each entry in PATCHES names a jar and a folder of Java sources under classpatch/.
The sources are compiled against the instance's Forge and SRG Minecraft jars from
Prism's libraries, plus the mods folder, and their classes replace the jar's. A jar
already patched with the same sources, or missing, is left alone. The jar names are
exact versions: a replacement class is a copy of that version's class, so an update
needs the source checked against the new jar first. 0.6.0/mods.md says why each is
patched.
"""

import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
LIBS = Path.home() / ".local/share/PrismLauncher/libraries"
STAMP = "META-INF/warpledge-classpatch.sha256"

# (jar name, source folder under classpatch/)
PATCHES = [
    # Its brewing recipes share EMI ids in GTO's EMI, which crashes gtolib's bake.
    ("alexsmobs-2.3.0-forge+1.20.1.jar", "alexsmobs"),
]


def sources_hash(src):
    h = hashlib.sha256()
    for f in sorted(src.rglob("*.java")):
        h.update(f.relative_to(src).as_posix().encode())
        h.update(f.read_bytes())
    return h.hexdigest()


def classpath(mods):
    # mods is <instance>/minecraft/mods; mmc-pack.json names the Forge version.
    pack = json.loads((mods.parent.parent / "mmc-pack.json").read_text())
    ver = {c["uid"]: c.get("version") for c in pack["components"]}
    mc, forge = ver["net.minecraft"], ver["net.minecraftforge"]
    fdir = LIBS / f"net/minecraftforge/forge/{mc}-{forge}"
    jars = [fdir / f"forge-{mc}-{forge}-client.jar",
            fdir / f"forge-{mc}-{forge}-universal.jar"]
    jars += sorted((LIBS / "net/minecraft/client").glob(f"{mc}-*/client-{mc}-*-srg.jar"))
    missing = [str(j) for j in jars if not j.exists()]
    if missing or len(jars) < 3:
        sys.exit("missing compile jars (launch the instance once):\n" + "\n".join(missing))
    return os.pathsep.join(map(str, jars + sorted(mods.glob("*.jar"))))


def javac():
    if shutil.which("javac"):
        return ["javac"]
    return ["nix", "shell", "nixpkgs#jdk21", "-c", "javac"]


def patch(jar, src, mods):
    digest = sources_hash(src)
    with zipfile.ZipFile(jar) as z:
        if STAMP in z.namelist() and z.read(STAMP).decode().strip() == digest:
            print(f"{jar.name}: already patched")
            return
    with tempfile.TemporaryDirectory() as out:
        files = [str(f) for f in sorted(src.rglob("*.java"))]
        subprocess.run(javac() + ["--release", "17", "-nowarn", "-cp", classpath(mods),
                                  "-d", out] + files, check=True)
        classes = {p.relative_to(out).as_posix(): p.read_bytes()
                   for p in Path(out).rglob("*.class")}
    with zipfile.ZipFile(jar) as z:
        names = set(z.namelist())
        new = sorted(set(classes) - names)
        if new:
            sys.exit(f"{jar.name}: {', '.join(new)} not in the jar; check the source")
        fd, tmp = tempfile.mkstemp(dir=jar.parent, suffix=".tmp")
        os.close(fd)
        with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as o:
            for info in z.infolist():
                if info.filename == STAMP:
                    continue
                o.writestr(info, classes.get(info.filename) or z.read(info))
            o.writestr(STAMP, digest + "\n")
    os.replace(tmp, jar)
    print(f"{jar.name}: replaced {', '.join(sorted(classes))}")


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    mods = Path(sys.argv[1]).expanduser()
    for name, folder in PATCHES:
        jar = mods / name
        if jar.exists():
            patch(jar, HERE / "classpatch" / folder, mods)


if __name__ == "__main__":
    main()
