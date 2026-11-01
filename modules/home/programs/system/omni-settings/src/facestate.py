"""The Security tab's Face Auth page: the cameras to choose from, whether Howdy is
applied yet, and the caller's saved faces. Only reads; omni-face-auth does the writing."""

import getpass
import glob
import json
import os

CONFIG = "/etc/howdy/config.ini"
MODELS = "/var/lib/howdy/models"
BY_PATH = "/dev/v4l/by-path"
TOOL = "/run/current-system/sw/bin/omni-face-auth"


def cameras():
    """Each capture node once: by-path lists a device under both usb- and usbv2- names,
    and a camera's odd nodes (index1) carry metadata, not video."""
    seen, found = set(), []
    for path in sorted(glob.glob(os.path.join(BY_PATH, "*-video-index0"))):
        node = os.path.basename(os.path.realpath(path))
        if node in seen:
            continue
        seen.add(node)
        try:
            with open(f"/sys/class/video4linux/{node}/name", encoding="utf-8") as f:
                name = f.read().strip()
        except OSError:
            name = node
        found.append({"path": path, "name": name.split(": ")[-1]})
    return found


def faces():
    """The caller's models, which Howdy keeps world-readable as JSON."""
    try:
        with open(os.path.join(MODELS, getpass.getuser() + ".dat"), encoding="utf-8") as f:
            models = json.load(f)
    except (OSError, ValueError):
        return []
    return [{"id": m.get("id"), "label": m.get("label", "")} for m in models]


def state():
    #--- pkexec matches its polkit action on the store path, as with api.py's helper()
    return {"applied": os.path.exists(CONFIG), "cameras": cameras(), "faces": faces(),
            "tool": os.path.realpath(TOOL)}
