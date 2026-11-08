#!/usr/bin/env python3
"""Back up, stage, update and check GregTech Odyssey Prism instances.

Usage:
    python3 -I <this file> <command> <instance> [...]

An instance is a folder name under Prism's instances/ or a path. overlay.json beside
this file lists the hand-added jars and the files to carry into a new pack build;
0.6.0/updating.md has the procedures. Commands that write refuse while Prism or the
instance's game is running. Nothing is ever deleted except a staging copy replaced
with --replace, which is backed up first, and the instance's copy of the recipe
datapack, which `datapack` rebuilds from ../datapack/.
"""

import argparse
import difflib
import hashlib
import json
import os
import re
import shutil
import sys
import time
import uuid
import zipfile
from pathlib import Path

PRISM = Path.home() / ".local/share/PrismLauncher"
BACKUPS = Path.home() / "Documents/Minecraft_Servers/GTO-backups"
OVERLAY = Path(__file__).resolve().with_name("overlay.json")
DATAPACK = Path(__file__).resolve().parent.parent / "datapack" / "warpledge-gto"
BASELINE = "gto-baseline.txt"
FULL_DIFF = {"config/gtocore-rules.txt", "config/gtocore.yaml"}

#-- Instances

def instance(arg):
    path = Path(arg).expanduser()
    if not (path / "instance.cfg").is_file():
        path = PRISM / "instances" / arg
    if not (path / "instance.cfg").is_file():
        sys.exit(f"no Prism instance at {arg}")
    return path.resolve()


def game_dir(inst):
    for name in ("minecraft", ".minecraft"):
        if (inst / name).is_dir():
            return inst / name
    sys.exit(f"{inst} has no minecraft folder")


def running(inst=None):
    """Names what blocks a write: Prism itself, or a game started from inst."""
    for proc in Path("/proc").iterdir():
        if not proc.name.isdigit() or int(proc.name) == os.getpid():
            continue
        try:
            args = (proc / "cmdline").read_bytes().split(b"\0")
        except OSError:
            continue
        exe = os.path.basename(args[0]).lower()
        if b"prismlauncher" in exe:
            return "Prism Launcher"
        if inst and b"java" in exe and any(str(inst).encode() in a for a in args):
            return f"the game in {inst.name}"
    return None


def refuse_if_running(inst=None, prism_ok=False):
    what = running(inst)
    if what and not (prism_ok and what == "Prism Launcher"):
        sys.exit(f"{what} is running; close it first")


def read_cfg(inst):
    return (inst / "instance.cfg").read_text().splitlines()


def cfg_lines(lines, keys):
    """The raw [General] lines for keys, so quoted values copy unchanged."""
    found, section = {}, None
    for line in lines:
        if line.startswith("["):
            section = line
        elif section == "[General]" and "=" in line:
            key = line.split("=", 1)[0]
            if key in keys:
                found[key] = line
    return found


def set_cfg(lines, new):
    """Replace or add [General] lines; new maps key to its whole line."""
    out, section, done = [], None, set()
    for line in lines:
        if line.startswith("["):
            if section == "[General]":
                at = len(out)
                while at and not out[at - 1].strip():
                    at -= 1
                out[at:at] = [v for k, v in new.items() if k not in done]
                done |= set(new)
            section = line
        elif section == "[General]" and line.split("=", 1)[0] in new:
            key = line.split("=", 1)[0]
            line = new[key]
            done.add(key)
        out.append(line)
    if section == "[General]":
        out += [v for k, v in new.items() if k not in done]
    return out


def size(path):
    return sum(f.stat().st_size for f in path.rglob("*") if f.is_file())


def gib(n):
    return f"{n / 2**30:.1f} GiB"

#-- Mods

def jar_mods(jar):
    """modId -> version for every [[mods]] entry in a jar's mods.toml."""
    try:
        with zipfile.ZipFile(jar) as z:
            toml = z.read("META-INF/mods.toml").decode("utf-8", "replace")
            try:
                manifest = z.read("META-INF/MANIFEST.MF").decode("utf-8", "replace")
            except KeyError:
                manifest = ""
    except (KeyError, zipfile.BadZipFile):
        return {}
    impl = re.search(r"^Implementation-Version:\s*(\S+)", manifest, re.M)
    mods = {}
    for block in re.split(r"^\s*\[\[mods\]\]", toml, flags=re.M)[1:]:
        block = re.split(r"^\s*\[", block, maxsplit=1, flags=re.M)[0]
        mid = re.search(r'^\s*modId\s*=\s*["\']([^"\']+)', block, re.M)
        ver = re.search(r'^\s*version\s*=\s*["\']([^"\']+)', block, re.M)
        if not mid:
            continue
        version = ver.group(1) if ver else ""
        if not version or "${" in version:
            version = impl.group(1) if impl else f"({jar.name})"
        mods[mid.group(1)] = version
    return mods


def scan_mods(gdir):
    """modId -> (version, jar name) for every enabled jar in mods/."""
    found = {}
    for jar in sorted((gdir / "mods").glob("*.jar")):
        for mid, ver in jar_mods(jar).items():
            found[mid] = (ver, jar.name)
    return found


def overlay():
    return json.loads(OVERLAY.read_text())

#-- backup

def cmd_backup(a):
    inst = instance(a.instance)
    dst = BACKUPS / f"{inst.name}-{time.strftime('%Y-%m-%d-%H%M')}"
    if dst.exists():
        sys.exit(f"{dst} already exists")
    if a.dry_run:
        print(f"would copy {inst} ({gib(size(inst))}) to {dst}")
        return
    refuse_if_running(inst, prism_ok=True)
    BACKUPS.mkdir(parents=True, exist_ok=True)
    shutil.copytree(inst, dst, symlinks=True)
    print(f"backed up {inst.name} to {dst}")
    print(f"all backups in {BACKUPS}: {gib(size(BACKUPS))}")
    return dst

#-- stage

def cmd_stage(a):
    inst = instance(a.instance)
    dst = inst.with_name(f"{inst.name}-{a.suffix}")
    if dst.exists() and not a.replace:
        sys.exit(f"{dst.name} exists; pass --replace to back it up and copy again")
    if a.dry_run:
        print(f"would copy {inst.name} to {dst.name} with a new name and uuid")
        return
    # Prism rewrites its instance list on exit, so it must be closed.
    refuse_if_running(inst)
    if dst.exists():
        cmd_backup(argparse.Namespace(instance=str(dst), dry_run=False))
        shutil.rmtree(dst)
    shutil.copytree(inst, dst, symlinks=True)
    lines = set_cfg(read_cfg(dst), {
        "name": f"name={dst.name}",
        "uuid": f"uuid={uuid.uuid4().hex}",
    })
    (dst / "instance.cfg").write_text("\n".join(lines) + "\n")
    print(f"staged {inst.name} as {dst.name}; Prism lists it on its next start")

#-- carry

def same(a, b):
    return a.stat().st_size == b.stat().st_size and digest(a) == digest(b)


def digest(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def cmd_carry(a):
    old, new = instance(a.old), instance(a.new)
    if not a.dry_run:
        refuse_if_running(new)
    ogame, ngame = game_dir(old), game_dir(new)
    ov = overlay()
    shipped = scan_mods(ngame)
    act = (lambda msg: print("would " + msg)) if a.dry_run else (lambda msg: print(msg))

    for mod in ov["mods"]:
        src, dst = ogame / "mods" / mod["jar"], ngame / "mods" / mod["jar"]
        have = shipped.get(mod["modId"])
        if have and have[1] != mod["jar"]:
            print(f"skip {mod['name']}: the pack now ships {have[1]} ({have[0]})")
        elif not src.is_file():
            print(f"skip {mod['name']}: {mod['jar']} is not in {old.name}")
        elif dst.exists():
            print(f"have {mod['jar']}")
        else:
            act(f"copy mods/{mod['jar']}")
            if not a.dry_run:
                shutil.copy2(src, dst)

    carried = []
    for entry in ov["carry"]:
        root = ogame / entry
        if root.is_dir():
            carried += sorted(str(p.relative_to(ogame)) for p in root.rglob("*") if p.is_file())
        else:
            carried.append(entry)
    for rel in carried:
        src, dst = ogame / rel, ngame / rel
        if not src.is_file():
            print(f"skip {rel}: not in {old.name}")
            continue
        if dst.exists() and same(src, dst):
            print(f"have {rel}")
            continue
        if dst.exists():
            # Keep the pack's copy so a new build's new options can be reviewed.
            act(f"keep the pack's {rel} as {rel}.pack-new")
            if not a.dry_run:
                shutil.copy2(dst, dst.with_name(dst.name + ".pack-new"))
        act(f"copy {rel}")
        if not a.dry_run:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)

    keys = cfg_lines(read_cfg(old), set(ov["instanceSettings"]))
    act(f"set {', '.join(sorted(keys))} in {new.name}/instance.cfg")
    if not a.dry_run:
        lines = set_cfg(read_cfg(new), keys)
        (new / "instance.cfg").write_text("\n".join(lines) + "\n")

    if a.saves:
        for world in sorted((ogame / "saves").iterdir()):
            dst = ngame / "saves" / world.name
            if not world.is_dir():
                continue
            if dst.exists():
                print(f"skip world {world.name}: already in {new.name}")
                continue
            act(f"copy world {world.name}")
            if not a.dry_run:
                shutil.copytree(world, dst, symlinks=True)

#-- datapack

def cmd_datapack(a):
    inst = instance(a.instance)
    src = DATAPACK
    dst = game_dir(inst) / "config/openloader/data" / DATAPACK.name
    if not (src / "pack.mcmeta").is_file():
        sys.exit(f"no datapack at {src}; run gregify.py first")
    want = {str(p.relative_to(src)): p for p in src.rglob("*") if p.is_file()}
    have = {}
    if dst.is_dir():
        have = {str(p.relative_to(dst)): p for p in dst.rglob("*") if p.is_file()}
    changed = [r for r in sorted(want) if r not in have or not same(want[r], have[r])]
    gone = sorted(have.keys() - want.keys())
    for r in changed:
        print(f"{'would copy' if a.dry_run else 'copy'} {r}")
    for r in gone:
        print(f"{'would remove' if a.dry_run else 'remove'} {r}")
    if not changed and not gone:
        print(f"{dst} is up to date ({len(want)} files)")
        return
    if a.dry_run:
        return
    refuse_if_running(inst, prism_ok=True)
    # The folder is generated from the repo, so replacing it whole loses nothing.
    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(src, dst)
    print(f"{dst}: {len(want)} files; reload with /reload or restart the world")

#-- diff

def files_under(root):
    if not root.is_dir():
        return {}
    return {
        str(p.relative_to(root.parent)): p
        for p in root.rglob("*")
        if p.is_file() and not p.name.endswith(".pack-new")
    }


def cmd_diff(a):
    old, new = instance(a.old), instance(a.new)
    ogame, ngame = game_dir(old), game_dir(new)
    for inst in (old, new):
        pack = json.loads((inst / "mmc-pack.json").read_text())
        parts = [f"{c['uid']} {c.get('version', '')}" for c in pack["components"]]
        print(f"{inst.name}: {', '.join(parts)}")

    om, nm = scan_mods(ogame), scan_mods(ngame)
    mine = {m["modId"] for m in overlay()["mods"]}
    print("\n== Mods")
    for mid in sorted(nm.keys() - om.keys()):
        print(f"+ {mid} {nm[mid][0]}  ({nm[mid][1]})")
    for mid in sorted(om.keys() - nm.keys()):
        note = "  (yours, not carried yet)" if mid in mine else ""
        print(f"- {mid} {om[mid][0]}{note}")
    for mid in sorted(om.keys() & nm.keys()):
        if om[mid][0] != nm[mid][0]:
            print(f"~ {mid} {om[mid][0]} -> {nm[mid][0]}")
    yours = {m["modId"]: m["jar"] for m in overlay()["mods"]}
    for mid, jar in sorted(yours.items()):
        if mid in nm and nm[mid][1] != jar:
            print(f"! {mid}: the pack now ships {nm[mid][1]}; drop your {jar}")

    print("\n== Config")
    for sub in ("config", "defaultconfigs", "kubejs"):
        of, nf = files_under(ogame / sub), files_under(ngame / sub)
        for rel in sorted(nf.keys() - of.keys()):
            print(f"+ {rel}")
        for rel in sorted(of.keys() - nf.keys()):
            print(f"- {rel}")
        for rel in sorted(of.keys() & nf.keys()):
            if same(of[rel], nf[rel]):
                continue
            print(f"~ {rel}")
            if rel in FULL_DIFF:
                text = difflib.unified_diff(
                    of[rel].read_text(errors="replace").splitlines(),
                    nf[rel].read_text(errors="replace").splitlines(),
                    f"{old.name}/{rel}", f"{new.name}/{rel}", lineterm="")
                print("\n".join(text))

#-- check

# Thread names can hold brackets ("DH-World Gen Thread[7]"), so match up to "/ERROR]".
LINE = re.compile(r"^\[[^\]]*\] \[(.*?)/(ERROR|FATAL)\] \[([^\]]*)\]: (.*)")
ALWAYS = re.compile(
    r"Mixin apply .*failed|MixinApplyError|InvalidMixinException"
    r"|Missing or unsupported mandatory dependencies"
    r"|Exception in server tick loop|Encountered an unexpected exception"
    r"|Failed to load .*mod", re.I)
BEHIND = re.compile(r"Can't keep up!.*Running (\d+)ms or (\d+) ticks behind")


def signature(thread, level, logger, msg):
    """One ERROR line with the parts that change between runs stripped out.

    The thread is left out: the same error moves between worker threads (DH's world
    gen and Worker-Main both log HangingEntity), and the logger names the source.
    """
    msg = re.sub(r"0x[0-9a-fA-F]+|\b[0-9a-fA-F]{8,}\b", "H", msg)
    msg = re.sub(r"-?\d+(\.\d+)?", "N", msg)
    return f"{level} [{logger}] {msg[:160]}"


def cmd_check(a):
    inst = instance(a.instance)
    gdir = game_dir(inst)
    log = gdir / "logs/latest.log"
    if not log.is_file():
        sys.exit(f"no {log}")
    sigs, always, behind = {}, [], []
    for line in log.read_text(errors="replace").splitlines():
        m = LINE.match(line)
        if m:
            sig = signature(*m.groups())
            sigs.setdefault(sig, [0, line])[0] += 1
        if ALWAYS.search(line):
            always.append(line)
        b = BEHIND.search(line)
        if b:
            behind.append(int(b.group(2)))

    base_inst = instance(a.against) if a.against else inst
    base_file = base_inst / BASELINE
    if a.save_baseline:
        base_file = inst / BASELINE
        base_file.write_text("\n".join(sorted(sigs)) + "\n")
        print(f"saved {len(sigs)} error signatures to {base_file}")
        return 0

    base = set()
    if base_file.is_file():
        base = set(base_file.read_text().splitlines())
        since = base_file.stat().st_mtime
        print(f"baseline: {base_file} ({len(base)} signatures)")
    else:
        since = 0
        print(f"no baseline at {base_file}; every error counts as new")

    found = 0
    new = {s: v for s, v in sigs.items() if s not in base}
    print(f"\n== New error signatures: {len(new)} (of {len(sigs)} in this log)")
    for sig, (count, first) in sorted(new.items(), key=lambda kv: -kv[1][0]):
        print(f"{count:>5}x {first[:220]}")
    found += len(new)

    print(f"\n== Mixin, dependency and load failures: {len(always)}")
    for line in dict.fromkeys(always):
        print(f"  {line[:220]}")
    found += len(always)

    crashes = [
        p for p in sorted((gdir / "crash-reports").glob("*.txt"))
        if p.stat().st_mtime > since
    ] if (gdir / "crash-reports").is_dir() else []
    print(f"\n== Crash reports since the baseline: {len(crashes)}")
    for p in crashes:
        print(f"  {p}")
    found += len(crashes)

    if behind:
        print(f"\n== Server fell behind {len(behind)} times, worst {max(behind)} ticks")
    print("\nclean" if not found else f"\n{found} findings")
    return 1 if found else 0

#-- Arguments

def main():
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    sub = p.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("backup", help="copy the whole instance to GTO-backups")
    s.add_argument("instance")
    s.add_argument("-n", "--dry-run", action="store_true")
    s.set_defaults(func=cmd_backup)

    s = sub.add_parser("stage", help="clone an instance to <name>-staging")
    s.add_argument("instance")
    s.add_argument("--as", dest="suffix", default="staging", metavar="SUFFIX",
                   help="name the copy <name>-SUFFIX, for side-by-side trials")
    s.add_argument("--replace", action="store_true",
                   help="back up an existing staging copy, then copy again")
    s.add_argument("-n", "--dry-run", action="store_true")
    s.set_defaults(func=cmd_stage)

    s = sub.add_parser("carry", help="copy your mods, files and Java settings to a new build")
    s.add_argument("old")
    s.add_argument("new")
    s.add_argument("--saves", action="store_true", help="copy the worlds too")
    s.add_argument("-n", "--dry-run", action="store_true")
    s.set_defaults(func=cmd_carry)

    s = sub.add_parser("diff", help="compare mods and configs of two instances")
    s.add_argument("old")
    s.add_argument("new")
    s.set_defaults(func=cmd_diff)

    s = sub.add_parser("check", help="report errors in latest.log the baseline lacks")
    s.add_argument("instance")
    s.add_argument("--against", metavar="INSTANCE",
                   help="use another instance's baseline, such as the old build's")
    s.add_argument("--save-baseline", action="store_true")
    s.set_defaults(func=cmd_check)

    s = sub.add_parser("datapack", help="install the repo's recipe datapack into an instance")
    s.add_argument("instance")
    s.add_argument("-n", "--dry-run", action="store_true")
    s.set_defaults(func=cmd_datapack)

    a = p.parse_args()
    rc = a.func(a)
    sys.exit(rc if isinstance(rc, int) else 0)


if __name__ == "__main__":
    main()
