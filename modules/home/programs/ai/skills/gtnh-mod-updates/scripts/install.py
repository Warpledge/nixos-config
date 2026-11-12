#!/usr/bin/env python3
"""Install picked mod updates from check.py's report.

Usage: install.py REPORT "Mod Name" "Other Mod=version" ...
A bare name takes the newest stable build, or the newest build if none is stable.
The report's role says where it goes: the client, or the server on a server machine.
The old jar moves to backups/replaced-mods/<date>/ on that side; nothing is deleted.
"""
import argparse
import datetime
import glob
import hashlib
import json
import os
import re
import shutil
import sys
import tempfile
import urllib.request

UA = "gtnh-mod-updates (github.com/Warpledge/nixos-config)"


def running_in(folders):
    """PIDs of java processes whose working directory is inside one of folders."""
    pids = []
    for proc in glob.glob("/proc/[0-9]*"):
        try:
            if "java" not in os.path.basename(os.readlink(f"{proc}/exe")):
                continue
            cwd = os.readlink(f"{proc}/cwd")
        except OSError:
            continue
        if any(cwd == f or cwd.startswith(f + "/") for f in folders):
            pids.append(os.path.basename(proc))
    return pids


def download(url, dest):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=120) as r, open(dest, "wb") as f:
        shutil.copyfileobj(r, f)


def verify(path, build):
    """Raises on a mismatch; returns what was checked."""
    with open(path, "rb") as f:
        data = f.read()
    if build.get("hash"):
        algo, _, want = build["hash"].partition(":")
        if hashlib.new(algo, data).hexdigest() != want:
            raise ValueError(f"{algo} mismatch")
        return algo
    if build.get("size") and len(data) != build["size"]:
        raise ValueError(f"size {len(data)}, expected {build['size']}")
    return "size only" if build.get("size") else "nothing, the source gives no hash"


def move_pw_toml(mods_dir, old_name, backup):
    index = os.path.join(mods_dir, ".index")
    for toml in glob.glob(f"{index}/*.pw.toml"):
        with open(toml) as f:
            if f"filename = '{old_name}'" in f.read():
                shutil.move(toml, os.path.join(backup, os.path.basename(toml)))


def swap(mods_dir, jar_pattern, new_file, backup):
    """Replace every jar of this mod, since each side's file may carry another name."""
    os.makedirs(backup, exist_ok=True)
    for name in os.listdir(mods_dir):
        if jar_pattern and re.search(jar_pattern, name) and name.endswith((".jar", ".jar.disabled")):
            shutil.move(os.path.join(mods_dir, name), os.path.join(backup, name))
            move_pw_toml(mods_dir, name, backup)
    shutil.copy2(new_file, mods_dir)


def pick_build(mod, wanted):
    if wanted:
        return next((b for b in mod["newer"] if b["version"] == wanted), None)
    stable = [b for b in mod["newer"] if not b["prerelease"]]
    return (stable or mod["newer"] or [None])[0]


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    ap.add_argument("report")
    ap.add_argument("mods", nargs="+", metavar="MOD[=VERSION]")
    args = ap.parse_args()

    with open(args.report) as f:
        report = json.load(f)
    by_name = {m["name"]: m for m in report["mods"]}
    is_server = report["role"] == "server"
    server = report["serverDir"]
    other = [host for host, role in report["machines"].items() if role != report["role"]]
    other = other[0] if other else "the other machine"

    picks = []
    for arg in args.mods:
        name, _, version = arg.partition("=")
        mod = by_name.get(name)
        if not mod:
            sys.exit(f"Not in the report: {name}")
        build = pick_build(mod, version)
        if not build or not build.get("asset"):
            sys.exit(f"No installable build for {arg}; its source has no jar to download.")
        picks.append((mod, build))

    folders = [os.path.realpath(p) for p in (report["instance"], server) if p]
    pids = running_in(folders)
    if pids:
        sys.exit(f"Close the game and stop the server first; java is running there: {pids}")

    stamp = datetime.date.today().isoformat()
    server_backup = os.path.join(server, "backups/replaced-mods", stamp) if server else None
    server_mods = os.path.join(server, "mods") if server else None
    failed = []
    with tempfile.TemporaryDirectory(prefix="gtnh-mod-updates-") as tmp:
        for mod, build in picks:
            name = build["asset"]["name"]
            path = os.path.join(tmp, name)
            try:
                download(build["asset"]["url"], path)
                checked = verify(path, build)
            except Exception as e:
                failed.append(f"{mod['name']}: {e}")
                continue
            pattern = mod.get("jarPattern")
            if is_server:
                swap(server_mods, pattern, path, server_backup)
                where = "server"
            else:
                client_backup = os.path.join(report["instance"],
                                             ".minecraft/backups/replaced-mods", stamp)
                swap(report["modsDir"], pattern, path, client_backup)
                where = "client"
                # A client machine's own server is only there for debugging
                if mod["side"] == "B" and server:
                    swap(server_mods, pattern, path, server_backup)
                    where = "client and this machine's debug server"
            print(f"{mod['name']}: {mod.get('jar')} -> {name} on {where}; checked {checked}")
            if mod.get("note"):
                print(f"  Note: {mod['note']}")

    failed_names = {line.partition(":")[0] for line in failed}
    shared = [m["name"] for m, _ in picks if m["side"] == "B" and m["name"] not in failed_names]
    if shared:
        print(f"\nBoth sides must match. Update these on {other} too: {', '.join(shared)}")
        if is_server or server:
            print("Back up the world before the server loads these.")
    if failed:
        print("\nNot installed:")
        for line in failed:
            print(f"  {line}")
        sys.exit(1)


if __name__ == "__main__":
    main()
