"""The mods folder and crash reports. A disabled mod is its jar renamed to
`.jar.disabled`, which every loader skips. Names and versions come from inside each
jar and are cached in the state folder by size and time."""

import glob
import json
import os
import re
import shutil
import tempfile
import zipfile

import servers

NAME = re.compile(r'^\s*displayName\s*=\s*"([^"]*)"', re.MULTILINE)
VERSION = re.compile(r'^\s*version\s*=\s*"([^"]*)"', re.MULTILINE)
READ_LIMIT = 256 * 1024


def about_jar(file):
    """{name, version} from mcmod.info, mods.toml or fabric.mod.json; empty if none."""
    try:
        with zipfile.ZipFile(file) as z:
            names = set(z.namelist())
            if "mcmod.info" in names:
                info = json.loads(z.read("mcmod.info")[:READ_LIMIT].decode("utf-8", errors="replace"))
                mods = info.get("modList", []) if isinstance(info, dict) else info
                if mods:
                    return {"name": mods[0].get("name", ""), "version": str(mods[0].get("version", ""))}
            for toml in ("META-INF/mods.toml", "META-INF/neoforge.mods.toml"):
                if toml in names:
                    text = z.read(toml)[:READ_LIMIT].decode("utf-8", errors="replace")
                    name, version = NAME.search(text), VERSION.search(text)
                    return {"name": name[1] if name else "", "version": version[1] if version else ""}
            if "fabric.mod.json" in names:
                info = json.loads(z.read("fabric.mod.json")[:READ_LIMIT].decode("utf-8", errors="replace"))
                return {"name": info.get("name", ""), "version": str(info.get("version", ""))}
    except (OSError, ValueError, zipfile.BadZipFile, AttributeError, KeyError):
        pass
    return {}


def listing(cfg):
    root = f"{cfg['dir']}/mods"
    cache_file = f"{servers.state_dir(cfg['id'])}/mods-cache.json"
    try:
        with open(cache_file, encoding="utf-8") as f:
            cache = json.load(f)
    except (OSError, ValueError):
        cache = {}
    fresh, mods = {}, []
    for folder, _, names in os.walk(root):
        rel_dir = os.path.relpath(folder, root)
        #--- mods/1.7.10/ holds jars; deeper is a mod's own data
        if rel_dir.count(os.sep) > 0:
            continue
        for name in names:
            if not name.endswith((".jar", ".jar.disabled")):
                continue
            file = os.path.join(folder, name)
            stat = os.stat(file)
            key = f"{os.path.relpath(file, root)}:{stat.st_size}:{int(stat.st_mtime)}"
            about = cache.get(key)
            if about is None:
                about = about_jar(file)
            fresh[key] = about
            on = name.endswith(".jar")
            bare = name[: -len(".jar")] if on else name[: -len(".jar.disabled")]
            version = about.get("version", "")
            if not version or "${" in version or "@" in version:
                version = ""
            mods.append({"file": os.path.relpath(file, root), "name": about.get("name") or bare,
                         "version": version, "on": on, "size": stat.st_size})
    os.makedirs(os.path.dirname(cache_file), exist_ok=True)
    with open(cache_file, "w", encoding="utf-8") as f:
        json.dump(fresh, f)
    return sorted(mods, key=lambda m: m["name"].lower())


def add(cfg, files):
    """Copy jars into mods/. Safe while the server runs, which reads them at its next
    start. Returns what was added, skipped and what may clash with an installed mod."""
    root = f"{cfg['dir']}/mods"
    os.makedirs(root, exist_ok=True)
    installed = {m["name"].lower(): m["file"] for m in listing(cfg) if m["on"]}
    added, skipped, clashes = [], [], []
    for file in files:
        name = os.path.basename(file)
        target = f"{root}/{name}"
        if not name.endswith(".jar") or not zipfile.is_zipfile(file):
            skipped.append({"file": name, "why": "isn't a mod jar"})
        elif os.path.exists(target) or os.path.exists(f"{target}.disabled"):
            skipped.append({"file": name, "why": "is already in the mods folder"})
        else:
            #--- A temp name no loader reads, so a failed copy never looks like a mod
            fd, tmp = tempfile.mkstemp(dir=root, prefix=".adding-")
            os.close(fd)
            try:
                shutil.copyfile(file, tmp)
                os.chmod(tmp, 0o644)
                os.replace(tmp, target)
            except OSError as e:
                os.unlink(tmp)
                skipped.append({"file": name, "why": f"couldn't be copied: {e.strerror}"})
                continue
            added.append(name)
            title = about_jar(target).get("name", "").lower()
            if title and title in installed:
                clashes.append({"file": name, "existing": installed[title]})
            elif title:
                installed[title] = name
    return {"added": added, "skipped": skipped, "clashes": clashes}


def toggle(cfg, file, on):
    if servers.status_of(cfg)["active"]:
        raise servers.ServerError("Stop the server to change its mods")
    root = os.path.realpath(f"{cfg['dir']}/mods")
    path = os.path.realpath(os.path.join(root, file or ""))
    if not path.startswith(root + os.sep) or not path.endswith((".jar", ".jar.disabled")):
        raise servers.ServerError(f"Bad mod file: {file}")
    if not os.path.isfile(path):
        raise servers.ServerError(f"No mod file called {file}")
    if on and path.endswith(".disabled"):
        os.rename(path, path[: -len(".disabled")])
    elif not on and path.endswith(".jar"):
        os.rename(path, f"{path}.disabled")


def crash_files(cfg):
    return glob.glob(f"{cfg['dir']}/crash-reports/*.txt") + glob.glob(f"{cfg['dir']}/hs_err_pid*.log")


def crashes(cfg):
    found = []
    for file in crash_files(cfg):
        stat = os.stat(file)
        title = ""
        try:
            with open(file, encoding="utf-8", errors="replace") as f:
                head = f.read(4096)
            if m := re.search(r"^Description: (.*)$", head, re.MULTILINE):
                title = m[1]
            elif "fatal error has been detected" in head:
                title = "The JVM crashed"
        except OSError:
            pass
        found.append({"name": os.path.relpath(file, cfg["dir"]), "time": stat.st_mtime, "title": title})
    return sorted(found, key=lambda c: -c["time"])


def read_crash(cfg, name):
    root = os.path.realpath(cfg["dir"])
    path = os.path.realpath(os.path.join(root, name or ""))
    if path not in [os.path.realpath(f) for f in crash_files(cfg)]:
        raise servers.ServerError(f"Bad crash report: {name}")
    with open(path, encoding="utf-8", errors="replace") as f:
        return f.read(512 * 1024)
