"""The last startup, from `systemd-analyze`: how long each stage took, the units
that held it up and the chain the desktop waited on. Read-only; empty when
systemd-analyze answers nothing, so the Overview just leaves the section out."""

import re
import subprocess

#--- "739ms", "4.123s" or "1min 2.345s": a systemd timespan in seconds
PART = re.compile(r"(\d+(?:\.\d+)?)\s*(us|ms|s|min|h|d)")
UNITS = {"us": 1e-6, "ms": 1e-3, "s": 1, "min": 60, "h": 3600, "d": 86400}
#--- "Startup finished in 11.6s (firmware) + ... = 43.9s"
STAGE = re.compile(r"(\S+) \(([a-z]+)\)")
TOTAL = re.compile(r"=\s*(\S+)\s*$")
GRAPHICAL = re.compile(r"(\S+) reached after (\S+) in userspace")
#--- A critical-chain line's "unit @started +took", after the tree drawing
TREE = re.compile(r"^[ │├└─]*")
AT = re.compile(r"^(\S+) @(\S+)(?: \+(\S+))?$")


def seconds(text):
    """A systemd timespan in seconds, or None when it isn't one."""
    parts = PART.findall(text or "")
    return sum(float(v) * UNITS[u] for v, u in parts) if parts else None


def run(*args):
    try:
        res = subprocess.run(["systemd-analyze", *args], capture_output=True, text=True,
                             timeout=30)
    except (OSError, subprocess.TimeoutExpired):
        return ""
    return res.stdout


def stages(text):
    """The startup split into firmware, loader, kernel, initrd and userspace."""
    line = next((l for l in text.splitlines() if l.startswith("Startup finished")), "")
    out = {name: seconds(value) for value, name in STAGE.findall(line)}
    total = TOTAL.search(line)
    named = list(out.values())
    out["total"] = seconds(total.group(1)) if total else sum(v for v in named if v)
    return out


def graphical(text):
    """When the desktop's target was reached, and which target that was."""
    m = GRAPHICAL.search(text)
    return {"target": m.group(1), "seconds": seconds(m.group(2))} if m else None


def blame(limit=12):
    """The non-device units that took longest to start, slowest first, and the
    slowest device unit: one wait shows up under many device names, which would
    fill the chart with the same bar."""
    units, devices = [], None
    for line in run("blame", "--no-pager").splitlines():
        # The duration may hold a space ("1min 2.3s"), so split at the last one
        took, _, unit = line.strip().rpartition(" ")
        value = seconds(took)
        if not unit or value is None:
            continue
        if unit.endswith(".device"):
            devices = max(devices or 0, value)
        else:
            units.append({"unit": unit, "seconds": value})
    return {"units": sorted(units, key=lambda u: -u["seconds"])[:limit],
            "devices": devices}


def chain(limit=40):
    """The units the desktop waited on, in order, nested under the one they
    waited for: when each started (@) and how long it took (+)."""
    rows = []
    for line in run("critical-chain", "--no-pager").splitlines():
        tree = TREE.match(line).group(0)
        m = AT.match(line[len(tree):].strip())
        if not m or len(rows) >= limit:
            continue
        # Each level is two spaces in, and the line carrying it starts with └
        indent = len(tree) - len(tree.lstrip(" "))
        depth = indent // 2 + (1 if "└" in tree or "├" in tree else 0)
        rows.append({"unit": m.group(1), "at": seconds(m.group(2)),
                     "took": seconds(m.group(3)) if m.group(3) else None,
                     "depth": depth})
    return rows


def summary():
    """What the last startup costs and where it went."""
    text = run()
    return {"stages": stages(text), "graphical": graphical(text),
            "blame": blame(), "chain": chain()}
