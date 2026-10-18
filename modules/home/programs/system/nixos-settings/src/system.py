"""This computer's state for the Overview page: versions, the generation running
and the one set for the next boot, how old the flake inputs are, what updates
are out, and which ports the running firewall opens."""

import json
import os
import platform
import re
import shlex
import shutil
import socket
import subprocess
import time
from dataclasses import dataclass, field

import closure

FIREWALL_UNIT = "/etc/systemd/system/firewall.service"
DPORT = re.compile(r"-p (tcp|udp) --dport (\d+(?::\d+)?) -j nixos-fw-accept")
#--- Who opens the ports the config's modules open; anything else is labelled
#--- by the machine's own firewall settings or left as "opened by the config"
PORT_NAMES = {
    ("tcp", "22"): "SSH",
    ("tcp", "22000"): "Syncthing", ("udp", "22000"): "Syncthing", ("udp", "21027"): "Syncthing discovery",
    ("tcp", "27036"): "Steam Remote Play", ("tcp", "27037"): "Steam Remote Play",
    ("udp", "27031:27035"): "Steam Remote Play", ("udp", "27036"): "Steam Remote Play",
    ("udp", "10400"): "Steam Remote Play", ("udp", "10401"): "Steam Remote Play",
    ("tcp", "27040"): "Steam game transfers on the network",
    ("tcp", "47984"): "Sunshine", ("tcp", "47989"): "Sunshine", ("tcp", "48010"): "Sunshine",
    ("udp", "47998:48000"): "Sunshine", ("udp", "48002"): "Sunshine", ("udp", "48010"): "Sunshine",
    ("udp", "5353"): "Network device discovery (Avahi)",
    ("udp", "546"): "IPv6 addresses (DHCPv6)",
    ("tcp", "25566"): "Minecraft servers",
}


@dataclass
class Info:
    hostname: str
    pretty: str  # "NixOS 26.11 (Zebra)"
    version: str  # nixos-version of the running system
    kernel: str  # running kernel
    generation: int  # running generation, 0 if it isn't one
    pending: int  # generation set for the next boot when it isn't the running one
    new_kernel: str  # the running system's kernel, when it isn't the booted one
    updated: float  # when nixpkgs in flake.lock was last updated (epoch)
    generations: list = field(default_factory=list)
    disk: tuple = (None, None)  # bytes free and in total where /nix/store lives


def os_release():
    try:
        with open("/etc/os-release") as f:
            for line in f:
                if line.startswith("PRETTY_NAME="):
                    return line.split("=", 1)[1].strip().strip('"')
    except OSError:
        pass
    return "NixOS"


def lock_nodes(path):
    with open(path) as f:
        lock = json.load(f)
    nodes = lock.get("nodes", {})
    root = nodes.get(lock.get("root", "root"), {}).get("inputs", {})
    return {name: nodes.get(ref, {}) for name, ref in root.items() if isinstance(ref, str)}


def info(flake):
    gens = closure.generations()
    running = os.path.realpath(closure.CURRENT)
    default = os.path.realpath(closure.SYSTEM_PROFILE)
    by_path = {}
    for g in gens:
        by_path.setdefault(g.path, g.number)
    try:
        updated = lock_nodes(os.path.join(flake, "flake.lock"))["nixpkgs"]["locked"]["lastModified"]
    except (OSError, ValueError, KeyError):
        updated = 0
    booted_kernel = closure.kernel(closure.BOOTED)
    current_kernel = closure.kernel(closure.CURRENT)
    try:
        usage = shutil.disk_usage("/nix/store")
        disk = (usage.free, usage.total)
    except OSError:
        disk = (None, None)
    return Info(socket.gethostname(), os_release(), closure.read(os.path.join(closure.CURRENT, "nixos-version")),
                platform.release(), by_path.get(running, 0),
                by_path.get(default, 0) if default != running else 0,
                current_kernel if current_kernel and current_kernel != booted_kernel else "",
                updated, gens, disk)


#--------------------------------------------------------------------#
#-- Clean-up
#--------------------------------------------------------------------#
DURATION = re.compile(r"(\d+)\s*([a-z]*)")
SECONDS = {"s": 1, "m": 60, "h": 3600, "d": 86400, "w": 604800, "y": 31536000}
UNIT_NAMES = {"s": "second", "m": "minute", "h": "hour", "d": "day", "w": "week", "y": "year"}


@dataclass
class CleanPolicy:
    keep: int  # the newest generations every clean-up keeps
    since: float  # seconds; generations younger than this are kept too
    since_text: str  # "5 days"
    schedule: str  # the weekly job's systemd calendar, "" when it's off


def clean_policy():
    """The weekly nh clean job's arguments (NIXOS_SETTINGS_CLEAN_ARGS, from nh.nix),
    which the helper's clean-up uses as well."""
    args = shlex.split(os.environ.get("NIXOS_SETTINGS_CLEAN_ARGS", "--keep-since 5d --keep 5"))
    keep, since, text = 1, 0.0, ""
    for i, arg in enumerate(args):
        name, _, value = arg.partition("=")
        if not value and i + 1 < len(args):
            value = args[i + 1]
        if name in ("--keep", "-k") and value.isdigit():
            keep = int(value)
        elif name in ("--keep-since", "-K"):
            m = DURATION.fullmatch(value.strip())
            unit = (m.group(2) or "d")[0] if m else ""
            if m and unit in SECONDS:
                count = int(m.group(1))
                since = count * SECONDS[unit]
                text = UNIT_NAMES[unit] if count == 1 else f"{count} {UNIT_NAMES[unit]}s"
    return CleanPolicy(keep, since, text, os.environ.get("NIXOS_SETTINGS_CLEAN_DATES", ""))


def to_delete(generations, policy):
    """The system generations a clean-up would delete: past the newest `keep`,
    older than `since`, and not the profile's current one."""
    try:
        current = int(re.search(r"system-(\d+)-link", os.readlink(closure.SYSTEM_PROFILE)).group(1))
    except (OSError, AttributeError, ValueError):
        current = None
    cutoff = time.time() - policy.since
    newest = {g.number for g in sorted(generations, key=lambda g: -g.number)[:policy.keep]}
    return [g for g in generations
            if g.number not in newest and g.when < cutoff and g.number != current]


#--------------------------------------------------------------------#
#-- Updates
#--------------------------------------------------------------------#
@dataclass
class InputChange:
    name: str
    old: float  # lastModified
    new: float
    link: str  # a page listing the changes, when the input is on GitHub


def runtime_dir():
    base = os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}"
    path = os.path.join(base, "nixos-settings")
    os.makedirs(path, mode=0o700, exist_ok=True)
    return path


class UpdateError(Exception):
    pass


def check_updates(flake):
    """Locks every input to its newest version in a separate lock file, leaving the
    repo's flake.lock alone. Returns (that file, [InputChange])."""
    new_lock = os.path.join(runtime_dir(), "flake.lock")
    try:
        os.unlink(new_lock)
    except OSError:
        pass
    try:
        out = subprocess.run(["nix", "flake", "update", "--flake", flake, "--output-lock-file", new_lock],
                             capture_output=True, text=True, timeout=900)
    except (OSError, subprocess.TimeoutExpired) as e:
        raise UpdateError(str(e))
    if out.returncode != 0 or not os.path.exists(new_lock):
        import nixlog
        raise UpdateError(nixlog.first_error(out.stderr) or "nix flake update failed")
    old_nodes = lock_nodes(os.path.join(flake, "flake.lock"))
    new_nodes = lock_nodes(new_lock)
    changes = []
    for name, node in sorted(new_nodes.items()):
        old, new = old_nodes.get(name, {}).get("locked", {}), node.get("locked", {})
        if not new or old.get("narHash") == new.get("narHash"):
            continue
        link = ""
        if new.get("type") == "github" and old.get("rev") and new.get("rev"):
            link = f"https://github.com/{new['owner']}/{new['repo']}/compare/{old['rev']}...{new['rev']}"
        changes.append(InputChange(name, old.get("lastModified", 0), new.get("lastModified", 0), link))
    return new_lock, changes


def apply_lock(flake, new_lock):
    """Puts `new_lock` in place of the repo's flake.lock; returns the old text."""
    path = os.path.join(flake, "flake.lock")
    with open(path) as f:
        old = f.read()
    with open(new_lock) as f:
        new = f.read()
    with open(path, "r+") as f:  # in place, keeping the file's mode, owner and ACL
        f.seek(0)
        f.write(new)
        f.truncate()
    return old


def restore_lock(flake, old):
    path = os.path.join(flake, "flake.lock")
    with open(path, "r+") as f:
        f.seek(0)
        f.write(old)
        f.truncate()


#--------------------------------------------------------------------#
#-- Firewall
#--------------------------------------------------------------------#
def open_ports(machine):
    """Ports the running firewall accepts, as (protocol, port, who opened it)."""
    try:
        with open(FIREWALL_UNIT) as f:
            unit = f.read()
        script = re.search(r"ExecStart=@?(\S+firewall-start)", unit).group(1)
        with open(script) as f:
            text = f.read()
    except (OSError, AttributeError):
        return []
    mine = {("tcp", str(p)) for p in (machine.get("firewall") or {}).get("openTCPPorts") or []}
    mine |= {("udp", str(p)) for p in (machine.get("firewall") or {}).get("openUDPPorts") or []}
    seen, out = set(), []
    for proto, port in DPORT.findall(text):
        if (proto, port) in seen:
            continue
        seen.add((proto, port))
        who = "Your setting above" if (proto, port) in mine else PORT_NAMES.get((proto, port), "Opened by the config")
        out.append((proto, port.replace(":", "–"), who))
    return sorted(out, key=lambda p: (int(p[1].split("–")[0]), p[0]))
