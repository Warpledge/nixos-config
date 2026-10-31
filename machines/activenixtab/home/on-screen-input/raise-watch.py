"""Keeps wvkbd above other overlay surfaces (DMS's launcher, the polkit dialog).
niri stacks a layer surface above the ones made before it, so when a new overlay
surface appears while it's shown, it is hidden and shown again to be made anew
on top."""

import json
import subprocess
import time
from collections import Counter

KEYBOARD = "wvkbd"


def overlays():
    try:
        out = subprocess.run(
            ["niri", "msg", "--json", "layers"],
            capture_output=True,
            text=True,
            timeout=2,
            check=True,
        ).stdout
        return Counter(
            layer["namespace"]
            for layer in json.loads(out)
            if layer.get("layer") == "Overlay"
        )
    except (OSError, subprocess.SubprocessError, ValueError):
        return None


def signal(sig, *match):
    subprocess.run(["pkill", "--signal", sig, *match], check=False)


last = Counter()
while True:
    now = overlays()
    if now is None:
        time.sleep(1)
        continue
    others = now - Counter({KEYBOARD: now[KEYBOARD]})
    if others - last:
        # wvkbd's hide destroys its surface, so it's listed only while shown
        if now[KEYBOARD]:
            signal("USR1", "-x", "wvkbd-deskintl")
            signal("USR2", "-x", "wvkbd-deskintl")
    last = others
    time.sleep(0.2)
