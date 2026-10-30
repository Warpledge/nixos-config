"""The Hardware tab's pages: firmware from fwupd, the battery's state and the
charge limit in force, and whether apps can run on the NVIDIA GPU."""

import glob
import json
import os
import shutil
import subprocess
import time

import system

#--- fwupd-refresh.timer keeps the metadata fresh; this only spares the badge
#--- a slow get-updates on every check
UPDATES_TTL = 3600


#--------------------------------------------------------------------#
#-- Firmware
#--------------------------------------------------------------------#
def fwupd(*args):
    """fwupdmgr's JSON for `args`; fwupdmgr exits 2 when it has nothing to list."""
    exe = shutil.which("fwupdmgr")
    if exe is None:
        raise RuntimeError("fwupd isn't installed on this computer")
    proc = subprocess.run([exe, *args, "--json"], capture_output=True, text=True, timeout=60,
                          check=False)
    if proc.returncode not in (0, 2):
        raise RuntimeError(proc.stderr.strip() or f"fwupdmgr {args[0]} failed")
    try:
        return json.loads(proc.stdout or "{}").get("Devices", [])
    except ValueError:
        return []


def updates(fresh=False):
    """Devices with a newer release: [{id, name, vendor, version, available, summary}]."""
    cache = os.path.join(system.runtime_dir(), "firmware-updates.json")
    if not fresh:
        try:
            if time.time() - os.path.getmtime(cache) < UPDATES_TTL:
                with open(cache) as f:
                    return json.load(f)
        except (OSError, ValueError):
            pass
    out = []
    for d in fwupd("get-updates"):
        releases = d.get("Releases") or [{}]
        out.append({"id": d.get("DeviceId", ""), "name": d.get("Name", ""),
                    "vendor": d.get("Vendor", ""), "version": d.get("Version", ""),
                    "available": releases[0].get("Version", ""),
                    "summary": releases[0].get("Summary", "")})
    with open(cache, "w") as f:
        json.dump(out, f)
    return out


def firmware(fresh=False):
    """Every named device fwupd knows, updatable ones first, with any update waiting."""
    waiting = {u["id"]: u for u in updates(fresh)}
    devices = []
    for d in fwupd("get-devices"):
        flags = d.get("Flags") or []
        if not d.get("Name") or "updatable-hidden" in flags:
            continue
        u = waiting.get(d.get("DeviceId", ""))
        devices.append({"id": d.get("DeviceId", ""), "name": d["Name"], "vendor": d.get("Vendor", ""),
                        "version": d.get("Version", ""), "updatable": "updatable" in flags,
                        "available": u["available"] if u else "", "summary": u["summary"] if u else ""})
    devices.sort(key=lambda d: (not d["available"], not d["updatable"], d["name"].casefold()))
    return {"devices": devices, "updates": len(waiting)}


#--------------------------------------------------------------------#
#-- Battery
#--------------------------------------------------------------------#
def read(path):
    try:
        with open(path) as f:
            return f.read().strip()
    except OSError:
        return ""


def batteries():
    return sorted(glob.glob("/sys/class/power_supply/BAT*"))


def battery():
    """Each battery's charge, state, health and cycles, and which limit is set now."""
    out = []
    for b in batteries():
        full = read(f"{b}/energy_full") or read(f"{b}/charge_full")
        design = read(f"{b}/energy_full_design") or read(f"{b}/charge_full_design")
        health = round(100 * int(full) / int(design)) if full.isdigit() and design.isdigit() and int(design) else None
        cycles = read(f"{b}/cycle_count")
        out.append({"name": os.path.basename(b), "capacity": int(read(f"{b}/capacity") or 0),
                    "status": read(f"{b}/status"), "health": health,
                    "cycles": int(cycles) if cycles.isdigit() and int(cycles) > 0 else None,
                    "threshold": read(f"{b}/charge_control_end_threshold")})
    conservation = [read(p) for p in glob.glob("/sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode")]
    return {"batteries": out,
            "conservation": None if not conservation else conservation[0] == "1"}


#--------------------------------------------------------------------#
#-- Run on the dGPU
#--------------------------------------------------------------------#
def has_offload():
    return shutil.which("nvidia-offload") is not None
