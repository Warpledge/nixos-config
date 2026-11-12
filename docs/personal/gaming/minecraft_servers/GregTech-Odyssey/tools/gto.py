#!/usr/bin/env python3
"""Back up, stage, update and check GregTech Odyssey Prism instances.

Usage:
    python3 -I <this file> <command> <instance> [...]

An instance is a folder name under Prism's instances/ or a path. overlay.json beside
this file lists the hand-added jars, the pack's own jars switched off (`removed`, which
`carry` disables with Prism's .disabled suffix and `server` leaves out) and the files
to carry into a new pack build;
0.6.0/updating.md has the procedures. Commands that write refuse while Prism or the
instance's game is running. Nothing is ever deleted except a staging copy replaced
with --replace, which is backed up first, the instance's copy of the recipe
datapack and the Reliable Remover/Recipes rules, which `datapack` rebuilds from
../datapack/ and ../reliable/, and a server folder's mods/, which `server` rebuilds
from the instance.
"""

import argparse
import difflib
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
import uuid
import zipfile
from pathlib import Path

PRISM = Path.home() / ".local/share/PrismLauncher"
BACKUPS = Path.home() / "Documents/Minecraft_Servers/GTO-backups"
OVERLAY = Path(__file__).resolve().with_name("overlay.json")
DATAPACK = Path(__file__).resolve().parent.parent / "datapack" / "warpledge-gto"
RELIABLE = Path(__file__).resolve().parent.parent / "reliable"
INTEGRATED = DATAPACK.with_name("warpledge-gto-integrated")
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

    for mod in ov.get("removed", []):
        have = shipped.get(mod["modId"])
        if not have:
            print(f"have {mod['name']} off")
            continue
        jar = ngame / "mods" / have[1]
        act(f"disable mods/{jar.name}")
        if not a.dry_run:
            jar.rename(jar.with_name(jar.name + ".disabled"))

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

def sync_tree(inst, src, dst, dry_run):
    """Make dst a copy of src; reports and returns whether anything changed."""
    want = {str(p.relative_to(src)): p for p in src.rglob("*") if p.is_file()}
    have = {}
    if dst.is_dir():
        # The Reliable mods write a *.disabled example into their folders on launch.
        have = {str(p.relative_to(dst)): p for p in dst.rglob("*")
                if p.is_file() and p.suffix != ".disabled"}
    changed = [r for r in sorted(want) if r not in have or not same(want[r], have[r])]
    gone = sorted(have.keys() - want.keys())
    for r in changed:
        print(f"{'would copy' if dry_run else 'copy'} {dst.name}/{r}")
    for r in gone:
        print(f"{'would remove' if dry_run else 'remove'} {dst.name}/{r}")
    if not changed and not gone:
        print(f"{dst} is up to date ({len(want)} files)")
        return False
    if dry_run:
        return True
    refuse_if_running(inst, prism_ok=True)
    # The folder is generated from the repo, so replacing it whole loses nothing.
    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(src, dst)
    print(f"{dst}: {len(want)} files")
    return True


def cmd_datapack(a):
    inst = instance(a.instance)
    gdir = game_dir(inst)
    if not (DATAPACK / "pack.mcmeta").is_file():
        sys.exit(f"no datapack at {DATAPACK}; run gregify.py first")
    pairs = [(DATAPACK, gdir / "config/openloader/data" / DATAPACK.name)]
    # Names the Integrated mods' structures; without them a new world won't load.
    if INTEGRATED.is_dir():
        if any((gdir / "mods").glob("integrated_api-*.jar")):
            pairs.append((INTEGRATED, gdir / "config/openloader/data" / INTEGRATED.name))
        else:
            print(f"skip {INTEGRATED.name}: Integrated API isn't in {inst.name}")
    # libgate.py's Reliable Remover/Recipes rules, only once those mods are installed.
    for src in sorted(RELIABLE.glob("reliable_*")) if RELIABLE.is_dir() else []:
        if any((gdir / "mods").glob(f"{src.name}-*.jar")):
            pairs.append((src, gdir / "config" / src.name))
        else:
            print(f"skip {src.name}: the mod isn't in {inst.name}")
    changed = [sync_tree(inst, s, d, a.dry_run) for s, d in pairs]
    if any(changed) and not a.dry_run:
        print("reload with /reload or restart the world")

#-- server

SERVER_DIRS = ("config", "defaultconfigs")
SERVER_PROPERTIES = """\
server-port=25566
online-mode=true
white-list=true
enforce-whitelist=true
max-players=2
motd=GregTech Odyssey {build}
"""


def sha1(path):
    h = hashlib.sha1()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def cmd_server(a):
    inst = instance(a.instance)
    gdir = game_dir(inst)
    zpath = Path(a.zip).expanduser()
    out = Path(a.out).expanduser() if a.out else (
        Path.home() / "Documents/Minecraft_Servers" / f"{inst.name}-server")
    # A rebuilt folder keeps its world; only the pack's files are replaced.
    if (out / "world").exists():
        print(f"{out.name} has a world; keeping it and server.properties")
    client = set(overlay()["clientOnly"])
    removed = {m["modId"] for m in overlay().get("removed", [])}
    act = (lambda msg: print("would " + msg)) if a.dry_run else (lambda msg: print(msg))

    # The release's server zip is a packwiz installer: its pack/mods/*.toml name
    # the server-side jars and their hashes, which the client instance already has.
    with zipfile.ZipFile(zpath) as z:
        tomls = [n for n in z.namelist()
                 if n.startswith("gto-installer/pack/mods/") and n.endswith(".toml")]
        wanted = []
        for n in tomls:
            text = z.read(n).decode("utf-8", "replace")
            name = re.search(r'^filename\s*=\s*"([^"]+)"', text, re.M).group(1)
            algo = re.search(r'^hash-format\s*=\s*"([^"]+)"', text, re.M).group(1)
            want = re.search(r'^hash\s*=\s*"([^"]+)"', text, re.M).group(1)
            wanted.append((name, algo, want))
        act(f"unpack {zpath.name} into {out}")
        if not a.dry_run:
            if (out / "mods").exists():
                shutil.rmtree(out / "mods")
            out.mkdir(parents=True, exist_ok=True)
            z.extractall(out)

    bad = []
    for name, algo, want in list(wanted):
        src = gdir / "mods" / name
        off = gdir / "mods" / (name + ".disabled")
        if off.is_file() and jar_mods(off).keys() & removed:
            print(f"skip removed {name}")
            wanted.remove((name, algo, want))
        elif not src.is_file():
            bad.append(f"{name}: not in {inst.name}")
        elif (sha1(src) if algo == "sha1" else digest(src)) != want:
            bad.append(f"{name}: hash differs from the pack index")
        elif not a.dry_run:
            shutil.copy2(src, out / "mods" / name)
    act(f"copy {len(wanted) - len(bad)} of the pack's {len(wanted)} server jars")
    for line in bad:
        print(f"  missing {line}")
    if bad:
        print("  run install-mods.sh in the folder to download them")

    for mod in overlay()["mods"]:
        src = gdir / "mods" / mod["jar"]
        if mod["modId"] in client:
            print(f"skip client-only {mod['jar']}")
        elif not src.is_file():
            print(f"skip {mod['name']}: {mod['jar']} is not in {inst.name}")
        else:
            act(f"copy mods/{mod['jar']}")
            if not a.dry_run:
                shutil.copy2(src, out / "mods" / mod["jar"])

    # The client's config/ carries the rules file, worldgen configs and datapack.
    for name in SERVER_DIRS:
        src = gdir / name
        if not src.is_dir():
            continue
        act(f"copy {name}/")
        if not a.dry_run:
            shutil.copytree(src, out / name, dirs_exist_ok=True)

    props = out / "server.properties"
    if not props.exists():
        act("write server.properties (port 25566, whitelist on)")
        if not a.dry_run:
            props.write_text(SERVER_PROPERTIES.format(build=inst.name.split("-", 1)[-1]))

    pack = json.loads((inst / "mmc-pack.json").read_text())
    forge = next(c["version"] for c in pack["components"]
                 if c["uid"] == "net.minecraftforge")
    full = f"1.20.1-{forge}"
    installer = out / "gto-installer/tools" / f"forge-{full}-installer.jar"
    if not (out / "libraries/net/minecraftforge/forge" / full).is_dir():
        act(f"install Forge {full} with the zip's installer")
        if not a.dry_run:
            if not installer.is_file():
                sys.exit(f"{installer.name} isn't in the zip; is it for Forge {forge}?")
            subprocess.run(["java", "-jar", str(installer), "--installServer", str(out)],
                           check=True, stdout=subprocess.DEVNULL)

    if a.tar:
        tar = out.with_name(out.name + ".tar.zst")
        act(f"pack {tar.name} (without world/, backups/ and logs/)")
        if not a.dry_run:
            subprocess.run(["tar", "--zstd", "-cf", str(tar), "--exclude", "./world",
                            "--exclude", "./backups", "--exclude", "./logs",
                            "--exclude", "./crash-reports", "-C", str(out), "."],
                           check=True)
            print(f"{tar}: {gib(tar.stat().st_size)}")

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

    s = sub.add_parser("server", help="build a dedicated server folder from the server zip")
    s.add_argument("instance")
    s.add_argument("--zip", required=True,
                   help="the release's GregTech-Odyssey-server.zip for the same build")
    s.add_argument("--out", metavar="DIR",
                   help="default ~/Documents/Minecraft_Servers/<instance>-server")
    s.add_argument("--tar", action="store_true",
                   help="also pack it as <DIR>.tar.zst to move to the laptop")
    s.add_argument("-n", "--dry-run", action="store_true")
    s.set_defaults(func=cmd_server)

    a = p.parse_args()
    rc = a.func(a)
    sys.exit(rc if isinstance(rc, int) else 0)


if __name__ == "__main__":
    main()
