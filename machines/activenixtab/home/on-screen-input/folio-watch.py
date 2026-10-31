"""Watches for the Z13's folio and osk-auto's off switch. While the folio is attached or
the switch is off, wvkbd doesn't open on text fields; attaching also hides it. The
swipe-up gesture and manual toggles still work. FOLIO_STATE also hides the bar button."""

import glob
import os
import subprocess
import time

FOLIO = "GZ302EA-Keyboard"
STATE_DIR = os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state"))
FOLIO_STATE = os.path.join(STATE_DIR, "osk-folio-attached")
AUTO_OFF = os.path.join(STATE_DIR, "osk-auto-off")


def folio_attached():
    for path in glob.glob("/sys/class/input/input*/name"):
        try:
            with open(path) as name:
                if FOLIO in name.read():
                    return True
        except OSError:
            pass  # a device going away mid-scan
    return False


def signal_keyboard(sig):
    subprocess.run(["pkill", "--signal", sig, "-x", "wvkbd-deskintl"], check=False)


def set_folio_state(attached):
    if attached:
        open(FOLIO_STATE, "w").close()
    elif os.path.exists(FOLIO_STATE):
        os.remove(FOLIO_STATE)


attached_before = blocked_before = None
while True:
    attached = folio_attached()
    blocked = attached or os.path.exists(AUTO_OFF)
    if attached != attached_before:
        set_folio_state(attached)
        if attached and attached_before is not None:
            signal_keyboard("USR1")
    if blocked != blocked_before:
        signal_keyboard("RTMIN+3" if blocked else "RTMIN+4")
    attached_before, blocked_before = attached, blocked
    time.sleep(1)
