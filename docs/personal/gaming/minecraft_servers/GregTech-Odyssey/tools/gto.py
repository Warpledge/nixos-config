#!/usr/bin/env python3
"""Back up, stage, update, map and check GregTech Odyssey Prism instances.

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
import io
import json
import os
import re
import shutil
import struct
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

#-- map

# GTO's own mods, and its forks (GTOCore-Main docs/forked-dependencies.md);
# expatternprovider is ExtendedAE
GTO_OWN = {"gtocore", "gtolib", "gtorenders", "gtoutils", "datasynclib"}
GTO_FORKS = {"gtceu", "ae2", "expatternprovider", "emi", "botania", "ars_nouveau"}
VANILLA = ("net/minecraft/", "com/mojang/", "net/minecraftforge/")
EXCLUSIVE = {"Overwrite", "Redirect", "ModifyConstant"}  # clash with other mods' mixins


def _element(data, pos, cp):
    """One annotation element_value: (value, next position)."""
    tag = chr(data[pos])
    pos += 1
    if tag == "e":
        return None, pos + 4
    if tag == "@":
        return _annotation(data, pos, cp)
    if tag == "[":
        n = struct.unpack_from(">H", data, pos)[0]
        pos += 2
        out = []
        for _ in range(n):
            v, pos = _element(data, pos, cp)
            out.append(v)
        return out, pos
    return cp[struct.unpack_from(">H", data, pos)[0]], pos + 2


def _annotation(data, pos, cp):
    kind, n = struct.unpack_from(">HH", data, pos)
    pos += 4
    values = {}
    for _ in range(n):
        name = cp[struct.unpack_from(">H", data, pos)[0]]
        values[name], pos = _element(data, pos + 2, cp)
    return (cp[kind], values), pos


def _skip_members(data, pos):
    count = struct.unpack_from(">H", data, pos)[0]
    pos += 2
    for _ in range(count):
        attrs = struct.unpack_from(">H", data, pos + 6)[0]
        pos += 8
        for _ in range(attrs):
            pos += 6 + struct.unpack_from(">I", data, pos + 2)[0]
    return pos


def mixin_info(data):
    """(target classes, exclusive injector kinds) of one compiled mixin class."""
    if data[:4] != b"\xca\xfe\xba\xbe":
        return None
    count = struct.unpack_from(">H", data, 8)[0]
    cp, pos, i = [None] * count, 10, 1
    while i < count:
        tag = data[pos]
        pos += 1
        if tag == 1:
            n = struct.unpack_from(">H", data, pos)[0]
            cp[i] = data[pos + 2:pos + 2 + n].decode("utf-8", "replace")
            pos += 2 + n
        elif tag in (7, 8, 16, 19, 20):
            cp[i] = ("ref", struct.unpack_from(">H", data, pos)[0])
            pos += 2
        elif tag in (3, 4, 9, 10, 11, 12, 17, 18):
            pos += 4
        elif tag in (5, 6):
            pos += 8
            i += 1
        elif tag == 15:
            pos += 3
        else:
            return None
        i += 1
    cp = [cp[v[1]] if isinstance(v, tuple) else v for v in cp]
    pos += 6
    pos += 2 + 2 * struct.unpack_from(">H", data, pos)[0]
    pos = _skip_members(data, _skip_members(data, pos))  # fields, then methods
    targets = []
    attrs = struct.unpack_from(">H", data, pos)[0]
    pos += 2
    for _ in range(attrs):
        name_index, length = struct.unpack_from(">HI", data, pos)
        name = cp[name_index]
        body, pos = pos + 6, pos + 6 + length
        if name not in ("RuntimeInvisibleAnnotations", "RuntimeVisibleAnnotations"):
            continue
        at = body + 2
        for _ in range(struct.unpack_from(">H", data, body)[0]):
            (kind, values), at = _annotation(data, at, cp)
            if kind != "Lorg/spongepowered/asm/mixin/Mixin;":
                continue
            for d in values.get("value") or []:
                targets.append(d[1:-1] if d.startswith("L") else d)
            for t in values.get("targets") or []:
                targets.append(t.replace(".", "/"))
    kinds = {k for k in EXCLUSIVE
             if f"Lorg/spongepowered/asm/mixin/{k};" in cp
             or f"Lorg/spongepowered/asm/mixin/injection/{k};" in cp}
    return targets, kinds


def _manifest_main(z):
    try:
        text = z.read("META-INF/MANIFEST.MF").decode("utf-8", "replace")
    except KeyError:
        return {}
    main = re.split(r"\r?\n\r?\n", text, maxsplit=1)[0]
    main = re.sub(r"\r?\n ", "", main)  # manifest continuation lines
    return dict(line.split(": ", 1) for line in main.splitlines() if ": " in line)


def scan_jar(name, z, nested=True):
    """Everything map reports about one jar, and its jar-in-jar jars."""
    names = z.namelist()
    try:
        toml = z.read("META-INF/mods.toml").decode("utf-8", "replace")
    except KeyError:
        toml = ""
    mods = re.findall(r'^\s*modId\s*=\s*"([^"]+)"', toml.split("[[dependencies", 1)[0], re.M)
    deps = {}
    for owner, block in re.findall(r"\[\[dependencies\.([\w-]+)\]\]([^\[]*)", toml):
        mid = re.search(r'modId\s*=\s*"([^"]+)"', block)
        rng = re.search(r'versionRange\s*=\s*"([^"]*)"', block)
        req = re.search(r"mandatory\s*=\s*(\w+)", block)
        typ = re.search(r'type\s*=\s*"(\w+)"', block)
        if mid and mid.group(1) not in ("minecraft", "forge"):
            kind = (typ.group(1).lower() if typ else
                    "required" if req and req.group(1) == "true" else "optional")
            deps[mid.group(1)] = f"{kind} {rng.group(1) if rng else ''}".strip()
    manifest = _manifest_main(z)
    configs = [c.strip() for c in manifest.get("MixinConfigs", "").split(",") if c.strip()]
    configs += re.findall(r'\[\[mixins\]\]\s*config\s*=\s*"([^"]+)"', toml)
    mixins, plugins = [], []
    for cfg in dict.fromkeys(configs):
        try:
            conf = json.loads(z.read(cfg))
        except (KeyError, ValueError):
            continue
        if conf.get("plugin"):
            plugins.append(conf["plugin"])
        pkg = conf.get("package", "").replace(".", "/")
        for side in ("mixins", "client", "server"):
            for m in conf.get(side) or []:
                path = f"{pkg}/{m.replace('.', '/')}.class"
                try:
                    info = mixin_info(z.read(path))
                except (KeyError, struct.error, IndexError):
                    info = None
                targets, kinds = info or ([], set())
                mixins.append({"name": m, "side": side, "config": cfg,
                               "targets": targets, "kinds": sorted(kinds)})
    jar = {
        "jar": name, "mods": mods, "deps": deps, "mixins": mixins, "plugins": plugins,
        "services": [n.split("/")[-1] for n in names
                     if n.startswith("META-INF/services/") and not n.endswith("/")],
        "at": sum(1 for line in z.read("META-INF/accesstransformer.cfg").decode(
            "utf-8", "replace").splitlines() if line.strip() and not line.startswith("#"))
        if "META-INF/accesstransformer.cfg" in names else 0,
        "sealed": sum(1 for n in names if n.endswith(".prod.bin")),
        "classes": {n[:-6] for n in names if n.endswith(".class")},
        "jarjar": [],
    }
    if nested:
        for n in names:
            if n.startswith("META-INF/jarjar/") and n.endswith(".jar"):
                try:
                    with zipfile.ZipFile(io.BytesIO(z.read(n))) as inner:
                        jar["jarjar"].append(scan_jar(n.split("/")[-1], inner, False))
                except zipfile.BadZipFile:
                    pass
    return jar


def open_jar(path):
    try:
        with zipfile.ZipFile(path) as z:
            return scan_jar(path.name, z)
    except zipfile.BadZipFile:
        return None


def owner_index(jars):
    owners = {}
    for jar in jars:
        for j in [jar] + jar["jarjar"]:
            label = j["mods"][0] if j["mods"] else j["jar"]
            for c in j["classes"]:
                owners.setdefault(c, label)
    return owners


def owner_of(cls, owners):
    if cls.startswith(VANILLA):
        return "minecraft" if not cls.startswith("net/minecraftforge/") else "forge"
    return owners.get(cls, "?")


def mixin_targets(jars):
    """target class -> [(mod, mixin, kinds)] across every jar."""
    found = {}
    for jar in jars:
        for j in [jar] + jar["jarjar"]:
            label = j["mods"][0] if j["mods"] else j["jar"]
            for m in j["mixins"]:
                # gtocore's jar carries gtolib's mixins too; name them by their config
                src = m["config"].split(".mixins")[0] if label in GTO_OWN else label
                for t in m["targets"]:
                    found.setdefault(t, []).append((src, m["name"], m["kinds"]))
    return found


def is_gto(mod):
    return mod in GTO_OWN or mod in GTO_FORKS


def print_jar(jar):
    sides = {}
    for m in jar["mixins"]:
        sides[m["side"]] = sides.get(m["side"], 0) + 1
    print(f"\n{jar['jar']}")
    print(f"  mods: {', '.join(jar['mods']) or '(none: not a Forge mod)'}")
    if jar["deps"]:
        print("  deps: " + ", ".join(f"{k} {v}" for k, v in sorted(jar["deps"].items())))
    if jar["mixins"]:
        print(f"  mixins: {len(jar['mixins'])} ("
              + ", ".join(f"{k} {v}" for k, v in sorted(sides.items())) + ")"
              + (f", plugin {', '.join(jar['plugins'])}" if jar["plugins"] else ""))
    for key, label in (("services", "services"), ("at", "access transformer lines"),
                       ("sealed", "sealed method bodies (.prod.bin)")):
        if jar[key]:
            val = jar[key]
            print(f"  {label}: {', '.join(val) if isinstance(val, list) else val}")
    for inner in jar["jarjar"]:
        print(f"  jar-in-jar: {inner['jar']} ({', '.join(inner['mods']) or 'library'})")


def cmd_map(a):
    gdir = game_dir(instance(a.instance))
    jars = [j for j in (open_jar(p) for p in sorted((gdir / "mods").glob("*.jar"))) if j]
    extra = [j for j in (open_jar(Path(p).expanduser()) for p in a.mod or []) if j]
    owners = owner_index(jars + extra)
    targets = mixin_targets(jars)

    if extra:
        return check_mods(extra, jars, owners, targets)

    gto = [j for j in jars if any(is_gto(m) for m in j["mods"]) or j["jar"].startswith("gto-")]
    print("== GTO's own jars")
    for jar in gto:
        if any(m in GTO_OWN for m in jar["mods"]) or not jar["mods"]:
            print_jar(jar)
    print("\n== GTO's forks")
    for jar in gto:
        if any(m in GTO_FORKS for m in jar["mods"]):
            print_jar(jar)

    by_mod = {}
    for cls, hits in targets.items():
        for mod, name, kinds in hits:
            if mod in GTO_OWN:
                by_mod.setdefault(owner_of(cls, owners), {}).setdefault(cls, []).append(
                    (f"{mod}:{name}", kinds))
    print("\n== GTO's own mixins by target mod (target class: mixins, [exclusive])")
    for mod in sorted(by_mod, key=lambda k: -sum(len(v) for v in by_mod[k].values())):
        classes = by_mod[mod]
        print(f"\n{mod}: {sum(len(v) for v in classes.values())} mixins, "
              f"{len(classes)} classes")
        if a.summary:
            continue
        for cls in sorted(classes):
            names = ", ".join(n + (f" [{'/'.join(k)}]" if k else "")
                              for n, k in classes[cls])
            print(f"  {cls.split('/')[-1]} ({cls.rsplit('/', 1)[0]}): {names}")

    print("\n== Classes GTO patches that other mods patch too")
    shared = 0
    for cls in sorted(targets):
        hits = targets[cls]
        mine = [h for h in hits if is_gto(h[0])]
        other = [h for h in hits if not is_gto(h[0])]
        if mine and other:
            shared += 1
            ex = any(h[2] for h in hits)
            print(f"  {cls}{'  [exclusive injector]' if ex else ''}")
            print("    GTO: " + ", ".join(f"{m}:{n}" for m, n, _ in mine))
            print("    others: " + ", ".join(sorted({m for m, _, _ in other})))
    print(f"\n{shared} shared classes")
    return 0


def check_mods(extra, jars, owners, targets):
    """Report what a candidate jar touches that GTO also owns or patches."""
    installed = {m: j["jar"] for j in jars for m in j["mods"]}
    for jar in extra:
        print_jar(jar)
        for m in jar["mods"]:
            if m in installed:
                print(f"  ! modId {m} already provided by {installed[m]}")
        # gto_native stops the game on unknown ModLauncher services (mods.md, Maid Spell)
        for j in [jar] + jar["jarjar"]:
            for svc in j["services"]:
                if svc.startswith("cpw.mods.modlauncher."):
                    print(f"  ! {j['jar']} registers ModLauncher service {svc}")
        for dep, rng in sorted(jar["deps"].items()):
            if rng.startswith("required") and dep not in installed:
                print(f"  ! needs {dep} ({rng}), not in the pack")
            if dep in GTO_FORKS and rng.startswith("required"):
                print(f"  ! depends on {dep}, which GTO forks: check the API it uses")
            if rng.startswith("incompatible") and dep in installed:
                print(f"  ! declares {dep} incompatible, and the pack has it")
        clash = 0
        for m in jar["mixins"]:
            for t in m["targets"]:
                owner = owner_of(t, owners)
                gto_hits = [h for h in targets.get(t, []) if is_gto(h[0])]
                if gto_hits or owner in GTO_OWN or owner in GTO_FORKS:
                    clash += 1
                    why = (f"GTO patches it ({', '.join(f'{x}:{n}' for x, n, _ in gto_hits)})"
                           if gto_hits else f"class belongs to {owner}, which GTO "
                           + ("owns" if owner in GTO_OWN else "forks"))
                    kinds = f" [{'/'.join(m['kinds'])}]" if m["kinds"] else ""
                    print(f"  ~ {m['name']}{kinds} -> {t}: {why}")
                elif owner == "?":
                    print(f"  ? {m['name']} -> {t}: target not in the pack (soft mixin?)")
        print(f"  {clash} mixin targets overlap GTO")
    return 0

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

    s = sub.add_parser("map", help="list GTO's jars and mixins, or check a new mod against them")
    s.add_argument("instance")
    s.add_argument("--mod", action="append", metavar="JAR",
                   help="a candidate jar to check instead (repeatable)")
    s.add_argument("--summary", action="store_true",
                   help="counts per target mod, without each class")
    s.set_defaults(func=cmd_map)

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
