"""World backups, as zips in the server's `backups/` folder, the folder mods like
ServerUtilities use, with one top-level folder named after the world. Restoring moves the current
world aside rather than deleting it."""

import glob
import os
import shutil
import sys
import time
import zipfile

import addons
import servers

SAVE_WAIT = 60


def folder(cfg):
    return f"{cfg['dir']}/backups"


def listing(cfg):
    found = []
    for file in glob.glob(f"{folder(cfg)}/*.zip"):
        stat = os.stat(file)
        found.append({"name": os.path.basename(file), "size": stat.st_size, "time": stat.st_mtime})
    moved = glob.glob(f"{servers.level_dir(cfg)}.before-restore-*")
    return {
        "backups": sorted(found, key=lambda b: -b["time"]),
        "liveBackup": (addons.live_backup(cfg) or {}).get("label", ""),
        "setAside": [os.path.basename(m) for m in sorted(moved)],
    }


def checked(cfg, name):
    """The backup's path; `name` comes from the page, so it can't leave the folder."""
    if os.path.basename(name or "") != name or not name.endswith(".zip"):
        raise servers.ServerError(f"Bad backup name: {name}")
    file = f"{folder(cfg)}/{name}"
    if not os.path.isfile(file):
        raise servers.ServerError(f"No backup called {name}")
    return file


def report(line):
    print(line, file=sys.stderr, flush=True)


def wait_for_save(cfg, since):
    """Until the console shows a finished save, or SAVE_WAIT runs out."""
    log = f"{servers.state_dir(cfg['id'])}/console.log"
    deadline = time.time() + SAVE_WAIT
    with open(log, "rb") as f:
        f.seek(since)
        while time.time() < deadline:
            if b"Saved the world" in f.read():
                return
            time.sleep(0.5)


def create(cfg):
    """Zip the world. On a running server with no add-on's backup, saving pauses around it."""
    world = servers.level_dir(cfg)
    if not os.path.isdir(world):
        raise servers.ServerError(f"There's no world at {world} yet")
    status = servers.status_of(cfg)
    live = status["active"]
    if status["state"] == "outside":
        raise servers.ServerError("This server is running outside Omni Server")
    backup = addons.live_backup(cfg)
    if live and backup:
        servers.send(cfg, backup["command"])
        return {"via": "addon"}
    os.makedirs(folder(cfg), exist_ok=True)
    target = f"{folder(cfg)}/{time.strftime('%Y-%m-%d-%H-%M-%S')}.zip"
    partial = f"{target}.part"
    if live:
        since = os.path.getsize(f"{servers.state_dir(cfg['id'])}/console.log")
        servers.send(cfg, "save-off")
        servers.send(cfg, "save-all flush")
        report("Waiting for the server to save")
        wait_for_save(cfg, since)
    try:
        base = os.path.dirname(world)
        files = [os.path.join(d, f) for d, _, names in os.walk(world) for f in names]
        with zipfile.ZipFile(partial, "w", zipfile.ZIP_DEFLATED, compresslevel=1, allowZip64=True) as z:
            for i, file in enumerate(files):
                try:
                    z.write(file, os.path.relpath(file, base))
                except OSError:
                    continue  # a mod's temp file that was gone by the time it was read
                if i % 200 == 0:
                    report(f"{i} of {len(files)} files")
        os.replace(partial, target)
    finally:
        if os.path.exists(partial):
            os.unlink(partial)
        if live:
            servers.send(cfg, "save-on")
    return {"via": "zip", "name": os.path.basename(target)}


def restore(cfg, name):
    file = checked(cfg, name)
    if servers.status_of(cfg)["active"]:
        raise servers.ServerError("Stop the server before restoring a backup")
    world = servers.level_dir(cfg)
    level = os.path.basename(world)
    with zipfile.ZipFile(file) as z:
        members = [m for m in z.infolist() if m.filename.startswith(f"{level}/")]
        if not members:
            raise servers.ServerError(f"This backup has no {level} folder, so it's from another world")
        moved = None
        if os.path.exists(world):
            moved = f"{world}.before-restore-{time.strftime('%Y-%m-%d-%H-%M-%S')}"
            os.replace(world, moved)
        root = os.path.realpath(cfg["dir"])
        for i, member in enumerate(members):
            target = os.path.realpath(os.path.join(root, member.filename))
            if not target.startswith(root + os.sep):
                raise servers.ServerError(f"Unsafe path in the backup: {member.filename}")
            z.extract(member, root)
            if i % 200 == 0:
                report(f"{i} of {len(members)} files")
    return {"setAside": os.path.basename(moved) if moved else ""}


def delete(cfg, name):
    os.unlink(checked(cfg, name))


def delete_set_aside(cfg, name):
    """Delete a world an earlier restore moved aside."""
    world = servers.level_dir(cfg)
    prefix = f"{os.path.basename(world)}.before-restore-"
    if os.path.basename(name or "") != name or not name.startswith(prefix):
        raise servers.ServerError(f"Bad folder name: {name}")
    shutil.rmtree(f"{cfg['dir']}/{name}")
