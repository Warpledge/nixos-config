"""The Hardware tab's pages: firmware from fwupd, the battery's state and the
charge limit in force, and whether apps can run on the NVIDIA GPU."""

import glob
import json
import os
import re
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


#--------------------------------------------------------------------#
#-- CPU Scheduler (sched_ext)
#--------------------------------------------------------------------#
#--- The schedulers offered, from each one's README in sched-ext/scx; the
#--- helper switches only to these
SCHEDULERS = {
    "scx_lavd": "Built for gaming: finds the latency-critical tasks and runs them first. "
                "Best on single-CCX CPUs.",
    "scx_bpfland": "Keeps interactive tasks (games, streaming, audio) running at their pace "
                   "while CPU-heavy work runs beside them.",
    "scx_flash": "Fair and predictable, for multimedia and real-time audio.",
    "scx_cosmos": "Lightweight and general purpose: keeps tasks on the same CPU until the "
                  "system is busy.",
    "scx_p2dq": "General purpose, with load balancing across caches. Needs tuning for games.",
    "scx_rusty": "General purpose, balancing load between each cache's CPUs from user space.",
}
SCX_UNIT = "scx.service"
SCX_BIN = re.compile(r"(/nix/store/[^ ']+/bin)/\$\{SCX_SCHEDULER")


def scx_unit():
    """{active, bin}: whether scx.service runs and the folder its schedulers are
    in, or None when the machine has no scx.service."""
    try:
        out = subprocess.run(["systemctl", "show", SCX_UNIT, "-p", "LoadState,ActiveState,ExecStart"],
                             capture_output=True, text=True, timeout=10).stdout
    except (OSError, subprocess.TimeoutExpired):
        return None
    props = dict(line.split("=", 1) for line in out.splitlines() if "=" in line)
    if props.get("LoadState") != "loaded":
        return None
    m = SCX_BIN.search(props.get("ExecStart", ""))
    return {"active": props.get("ActiveState") == "active", "bin": m.group(1) if m else ""}


def scheduler():
    """The running sched_ext scheduler, what the unit was told to run and the
    choices, or None without scx.service."""
    unit = scx_unit()
    if unit is None:
        return None
    running = read("/sys/kernel/sched_ext/state") == "enabled"
    ops = read("/sys/kernel/sched_ext/root/ops") if running else ""
    env = {}
    try:
        out = subprocess.run(["systemctl", "show-environment"], capture_output=True, text=True,
                             timeout=10).stdout
        env = dict(line.split("=", 1) for line in out.splitlines() if "=" in line)
    except (OSError, subprocess.TimeoutExpired):
        pass
    return {"running": running, "ops": ops, "active": unit["active"],
            "override": env.get("SCX_SCHEDULER_OVERRIDE", ""),
            "choices": [{"name": n, "text": t} for n, t in SCHEDULERS.items()
                        if not unit["bin"] or os.access(os.path.join(unit["bin"], n), os.X_OK)]}
