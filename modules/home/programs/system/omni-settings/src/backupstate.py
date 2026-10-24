"""The Backups page: which backups apply to the user, when each was last made,
and the `nixm` run behind its buttons."""

import os
import re
import subprocess
import time

ROOT = os.path.join(os.path.expanduser("~"), "SyncBackups")
STAMP = re.compile(r"^(\d{4})-(\d\d)-(\d\d)_(\d\d)-(\d\d)-(\d\d)$")
#--- (nixm command, title, what it saves, user setting it needs, its folder)
KINDS = [
    ("freetube-backup", "FreeTube", "Subscriptions, playlists, history and settings",
     ("media", "freetube"), "FreeTube"),
    ("zen-backup", "Zen Bookmarks", "Every bookmark, as a bookmarks.html any browser imports",
     ("browsers", "zen"), "Zen"),
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
