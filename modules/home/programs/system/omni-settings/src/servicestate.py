"""Running Now's GTK-free half: whether each background service the config can
turn on is running, its last log lines, and restarting it. Only services the
running system has are listed. A system service's restart goes through
polkit, so DMS's password prompt asks for it. Kept free of GTK for both front
ends."""

import subprocess

#--- (name, "system" or "user", unit), from the modules under nixos/services
#--- and nixos/security; Sunshine and rootless Docker run per user
UNITS = [
    ("SSH", "system", "sshd.service"),
    ("Syncthing", "system", "syncthing.service"),
    ("Sunshine", "user", "sunshine.service"),
    ("Suwayomi", "system", "suwayomi-server.service"),
    ("FlareSolverr", "system", "flaresolverr.service"),
    ("Mullvad VPN", "system", "mullvad-daemon.service"),
    ("Docker", "system", "docker.service"),
    ("Docker (rootless)", "user", "docker.service"),
    ("ClamAV", "system", "clamav-daemon.service"),
]
LOG_LINES = 30


def systemctl(scope):
    return ["systemctl"] + (["--user"] if scope == "user" else [])


def states():
    """{(scope, unit): (ActiveState, SubState, since)} for the units that exist."""
    out = {}
    for scope in ("system", "user"):
        units = [u for _, s, u in UNITS if s == scope]
        try:
            res = subprocess.run(systemctl(scope) + ["show", "-p", "Id,LoadState,ActiveState,SubState,"
                                                     "ActiveEnterTimestamp", "--", *units],
                                 capture_output=True, text=True, timeout=10)
        except (OSError, subprocess.TimeoutExpired):
            continue
        for chunk in res.stdout.strip().split("\n\n"):
            props = dict(line.split("=", 1) for line in chunk.splitlines() if "=" in line)
            if props.get("LoadState") == "loaded":
                out[(scope, props["Id"])] = (props.get("ActiveState", ""), props.get("SubState", ""),
                                             props.get("ActiveEnterTimestamp", ""))
    return out


def journal(scope, unit):
    cmd = ["journalctl", "--no-pager", "-o", "short", "-n", str(LOG_LINES)]
    cmd += ["--user-unit", unit] if scope == "user" else ["-u", unit]
    res = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
    return (res.stdout or res.stderr).strip() or "No log lines yet."


def restart(scope, unit):
    """Restarts `unit`; returns (ok, why not)."""
    res = subprocess.run(systemctl(scope) + ["restart", "--", unit], capture_output=True, text=True,
                         timeout=120)
    return res.returncode == 0, res.stderr.strip() or "it didn't restart"
