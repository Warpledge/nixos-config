"""The Backups page: which backups apply to the user, when each was last made,
what each run wrote, copying one back out, and the `nixm` run behind its buttons."""

import os
import re
import shutil
import subprocess
import tempfile
import time

DEFAULT_FOLDER = "~/SyncBackups"
#--- Where this build's nixm writes, not the saved setting, which waits for a rebuild
ROOT = os.environ.get("OMNI_SETTINGS_BACKUP_FOLDER") or os.path.expanduser(DEFAULT_FOLDER)
STAMP = re.compile(r"^(\d{4})-(\d\d)-(\d\d)_(\d\d)-(\d\d)-(\d\d)$")
#--- (nixm command, title, what it saves, user setting it needs, its folder,
#--- name in backups.skip, kept in step with listChoices in lib/settings.nix, how to import)
KINDS = [
    ("freetube-backup", "FreeTube", "Subscriptions, playlists and history",
     ("media", "freetube"), "FreeTube", "freetube",
     "In FreeTube: Settings → Data Settings → Import Subscriptions, Import History or Import Playlists."),
    ("zen-backup", "Zen Bookmarks", "Every bookmark, as a bookmarks.html any browser imports",
     ("browsers", "zen"), "Zen", "zen",
     "In Zen: Ctrl+Shift+O → Import and Backup → Import Bookmarks from HTML."),
]


def kinds(user):
    """The KINDS whose app is on in `user`, that user's resolved settings."""
    return [k for k in KINDS if (user.get(k[3][0]) or {}).get(k[3][1])]


def newest(folder):
    """When the newest dated backup in `folder` was made (epoch), or None."""
    try:
        stamps = sorted(n for n in os.listdir(folder) if STAMP.match(n))
    except OSError:
        return None
    if not stamps:
        return None
    return time.mktime(time.strptime(stamps[-1], "%Y-%m-%d_%H-%M-%S"))


def hosts(folder, this_host):
    """The computers with runs of this kind under ROOT, `this_host` first."""
    try:
        names = sorted(e.name for e in os.scandir(ROOT)
                       if e.is_dir(follow_symlinks=False) and not e.name.startswith("."))
    except OSError:
        return []
    found = [n for n in names if runs(os.path.join(ROOT, n, folder))]
    return sorted(found, key=lambda n: n != this_host)


def runs(folder):
    """The dated runs in `folder`, newest first, with their files and sizes. Regular
    files only, since Syncthing can carry a symlink in."""
    try:
        stamps = [e.name for e in os.scandir(folder)
                  if STAMP.match(e.name) and e.is_dir(follow_symlinks=False)]
    except OSError:
        return []
    out = []
    for stamp in sorted(stamps, reverse=True):
        with os.scandir(os.path.join(folder, stamp)) as it:
            files = [{"name": e.name, "size": e.stat(follow_symlinks=False).st_size}
                     for e in it if e.is_file(follow_symlinks=False)]
        files.sort(key=lambda f: f["name"])
        out.append({"stamp": stamp, "when": time.mktime(time.strptime(stamp, "%Y-%m-%d_%H-%M-%S")),
                    "size": sum(f["size"] for f in files), "files": files})
    return out


def restore(kind, host, stamp, name=None):
    """Copies a run's file, or all of them when `name` is None, into a new private folder
    in /tmp for the app's own Import, and leaves live data alone. /tmp clears on boot, so
    nothing here deletes, and Syncthing never sees a copy."""
    folder, title, how = kind[4], kind[1], kind[6]
    if host not in hosts(folder, None):
        raise ValueError("no such computer")
    run = next((r for r in runs(os.path.join(ROOT, host, folder)) if r["stamp"] == stamp), None)
    if run is None:
        raise ValueError("no such backup")
    names = [f["name"] for f in run["files"]]
    if name is not None:
        if name not in names:
            raise ValueError("no such file")
        names = [name]
    dest = tempfile.mkdtemp(prefix=f"{folder.lower()}-{stamp}-", dir="/tmp")
    for n in names:
        shutil.copyfile(os.path.join(ROOT, host, folder, stamp, n), os.path.join(dest, n))
    return {"title": title, "folder": dest, "files": names, "how": how}


def freetube_open():
    """Whether FreeTube is running, as nixm's own check sees it."""
    try:
        out = subprocess.run(["pgrep", "-f", "freetube/resources/app.asar"], capture_output=True)
    except OSError:
        return False
    return out.returncode == 0


def run(command):
    """Runs `nixm <command>`; returns (ok, what it printed)."""
    out = subprocess.run(["nixm", command], capture_output=True, text=True, timeout=600,
                         stdin=subprocess.DEVNULL)
    return out.returncode == 0, (out.stdout + out.stderr).strip()
