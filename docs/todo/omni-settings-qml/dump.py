# Prototype backend: Omni Settings' Overview data as JSON, reusing system.py.
import json
import os
import sys
import time

SRC = "/etc/nixos-config/modules/home/programs/system/omni-settings/src"
sys.path.insert(0, SRC)
import closure  # noqa: E402
import system  # noqa: E402

FLAKE = os.environ.get("OMNI_SETTINGS_FLAKE", "/etc/nixos-config")


def when(epoch):
    t, today = time.localtime(epoch), time.localtime()
    clock = time.strftime("%H:%M", t)
    if t.tm_year == today.tm_year and t.tm_yday == today.tm_yday:
        return f"Today, {clock}"
    if t.tm_year == today.tm_year and t.tm_yday == today.tm_yday - 1:
        return f"Yesterday, {clock}"
    return time.strftime("%-d %b, %H:%M", t)


i = system.info(FLAKE)
running = os.path.realpath(closure.CURRENT)
booted = os.path.realpath(closure.BOOTED)
free, total = i.disk
print(json.dumps({
    "hostname": i.hostname,
    "pretty": i.pretty,
    "kernel": i.kernel,
    "generation": i.generation,
    "pending": i.pending,
    "newKernel": i.new_kernel,
    "updated": time.strftime("%-d %b %Y", time.localtime(i.updated)) if i.updated else "?",
    "flake": FLAKE,
    "diskFree": free or 0,
    "diskTotal": total or 0,
    "generations": [{
        "number": g.number,
        "when": when(g.when),
        "kernel": g.kernel,
        "running": g.path == running,
        "booted": g.path == booted,
    } for g in i.generations[:6]],
}))
