"""What came back after a rebuild: Dux Shell, the desktop portals and the
services the Services page lists. The job service takes a snapshot before the
switch, so the check afterwards can name the units that were running then and
aren't now. `docs/wm/niri-xdg-portals.md` explains the portal count."""

import re
import subprocess

import servicestate

DMS = "dms.service"
PORTAL = "org.freedesktop.impl.portal.desktop.gnome"
PORTAL_PATH = "/org/freedesktop/portal/desktop"
INTERFACE = re.compile(r"^org\.freedesktop\.impl", re.MULTILINE)


def _run(cmd, timeout=15):
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    except (OSError, subprocess.TimeoutExpired):
        return None


def dms():
    """Whether Dux Shell's unit is on this machine, and running: None when the
    unit isn't there (another desktop shell, or none)."""
    res = _run(["systemctl", "--user", "show", "-p", "LoadState,ActiveState", "--", DMS])
    props = dict(line.split("=", 1) for line in (res.stdout if res else "").splitlines() if "=" in line)
    if props.get("LoadState") != "loaded":
        return None
    return props.get("ActiveState") == "active"


def portals():
    """How many interfaces the GNOME portal backend exports: 1 is broken, 15 healthy."""
    res = _run(["busctl", "--user", "introspect", PORTAL, PORTAL_PATH])
    if res is None or res.returncode != 0:
        return None
    return len(INTERFACE.findall(res.stdout))


def snapshot():
    """{dms, portals, units} of the running system, before or after a switch."""
    return {"dms": dms(), "portals": portals(),
            "units": {key: state[0] for key, state in servicestate.states().items()}}


def report(before):
    """{items, failed, checked}: a row per check, the units that were running
    before the switch and aren't now, and how many checks there were."""
    after = snapshot()
    items, checked = [], 0
    if after["dms"] is not None:
        checked += 1
        items.append({"title": "Dux Shell", "ok": after["dms"],
                      "detail": "Running, with its bar and panels." if after["dms"]
                      else "It isn't running; `dms restart` starts it again."})
    count = after["portals"]
    checked += 1
    if count is None:
        detail = "The desktop portal service didn't answer."
    elif count <= 1:
        detail = (f"It exports {count or 'no'} portal interface, so file pickers and screen "
                  "sharing don't work. See docs/wm/niri-xdg-portals.md.")
    else:
        detail = f"{count} portal interfaces are there."
    items.append({"title": "Desktop portals", "ok": count is not None and count > 1,
                  "detail": detail})
    running = 0
    for name, scope, unit in servicestate.UNITS:
        key = (scope, unit)
        if before["units"].get(key) != "active":
            continue
        checked += 1
        if after["units"].get(key) == "active":
            running += 1
            continue
        items.append({"title": name, "ok": False,
                      "detail": f"{unit} was running before the rebuild and is "
                                f"{after['units'].get(key) or 'gone'} now."})
    return {"items": items, "failed": sum(1 for i in items if not i["ok"]),
            "checked": checked, "running": running}
