"""What changes between two NixOS systems, and the system generations on this
computer. The root helper imports this too, so it stays free of GTK."""

import json
import os
import re
import subprocess
from dataclasses import dataclass, field

PROFILES = "/nix/var/nix/profiles"
SYSTEM_PROFILE = os.path.join(PROFILES, "system")
CURRENT = "/run/current-system"
BOOTED = "/run/booted-system"

#--- A live switch to a new one of these froze the desktop (CLAUDE.md, `nixm boot`)
CORE = {"glibc", "systemd", "niri", "niri-unstable", "xwayland-satellite"}

ANSI = re.compile(r"\x1b\[[0-9;?]*[ -/]*[@-~]")
SIZE = re.compile(r"(-?)(\d+(?:\.\d+)?) (B|KiB|MiB|GiB|TiB)")
UNITS = {"B": 1, "KiB": 1024, "MiB": 1024 ** 2, "GiB": 1024 ** 3, "TiB": 1024 ** 4}
GENERATION = re.compile(r"system-(\d+)-link")
KERNEL_VERSION = re.compile(r"-(\d+\.\d+[\w.+-]*)$")


@dataclass
class Diff:
    updated: list = field(default_factory=list)  # (name, old, new)
    added: list = field(default_factory=list)  # (name, version)
    removed: list = field(default_factory=list)  # (name, version)
    files: int = 0  # changed paths without a version: config files, scripts
    size: tuple = (None, None)  # closure size before, after (bytes)

    def core(self):
        """The CORE packages this diff updates, as "name old → new" strings."""
        return [f"{n} {o} → {v}" for n, o, v in self.updated if n in CORE]

    def as_json(self):
        return {"updated": self.updated, "added": self.added, "removed": self.removed,
                "files": self.files, "size": list(self.size)}

    @classmethod
    def from_json(cls, data):
        return cls([tuple(x) for x in data.get("updated", [])],
                   [tuple(x) for x in data.get("added", [])],
                   [tuple(x) for x in data.get("removed", [])],
                   data.get("files", 0), tuple(data.get("size", (None, None))))


def parse_size(text):
    m = SIZE.fullmatch(text.strip())
    if not m:
        return None
    sign = -1 if m.group(1) else 1
    return sign * float(m.group(2)) * UNITS[m.group(3)]


def parse_diff(text):
    """Reads `nix store diff-closures` output: `name: old → new, size`, where
    either half may be missing, ∅ is absent and ε is a path with no version."""
    diff = Diff()
    for raw in text.splitlines():
        line = ANSI.sub("", raw).strip()
        name, sep, rest = line.partition(": ")
        if not sep or not name:
            continue
        parts = rest.split(", ")
        if parts and parse_size(parts[-1]) is not None:
            parts.pop()
        rest = ", ".join(parts)
        if " → " not in rest:
            continue  # same version, different size: a rebuild
        old, new = (s.strip() for s in rest.split(" → ", 1))
        if old == "∅" and new == "ε" or old == "ε" and new == "∅" or old == new == "ε":
            diff.files += 1
        elif old == "∅":
            diff.added.append((name, new))
        elif new == "∅":
            diff.removed.append((name, old))
        elif old != new:
            diff.updated.append((name, old, new))
    return diff


def closure_sizes(*paths):
    try:
        out = subprocess.run(["nix", "path-info", "--json", "--closure-size", *paths],
                             capture_output=True, text=True, timeout=120)
        data = json.loads(out.stdout or "null")
    except (OSError, ValueError, subprocess.TimeoutExpired):
        return [None] * len(paths)
    if isinstance(data, list):  # older Nix: a list of objects with "path"
        data = {d.get("path"): d for d in data}
    if not isinstance(data, dict):
        return [None] * len(paths)
    real = {os.path.realpath(p): p for p in paths}
    sizes = {real.get(k, k): (v or {}).get("closureSize") for k, v in data.items()}
    return [sizes.get(p) for p in paths]


def diff(old, new):
    """The package changes from system `old` to system `new` (both built)."""
    try:
        out = subprocess.run(["nix", "store", "diff-closures", old, new],
                             capture_output=True, text=True, timeout=300)
    except (OSError, subprocess.TimeoutExpired):
        return Diff()
    result = parse_diff(out.stdout)
    result.size = tuple(closure_sizes(old, new))
    return result


def kernel(system):
    """The kernel version a system boots, from its kernel link."""
    try:
        target = os.readlink(os.path.join(system, "kernel"))
    except OSError:
        return ""
    m = KERNEL_VERSION.search(os.path.basename(os.path.dirname(target)))
    return m.group(1) if m else ""


def read(path):
    try:
        with open(path) as f:
            return f.read().strip()
    except OSError:
        return ""


@dataclass
class Generation:
    number: int
    path: str  # the system's store path
    when: float  # when the profile link was made
    version: str  # nixos-version
    kernel: str


def generations():
    """System generations, newest first."""
    out = []
    try:
        names = os.listdir(PROFILES)
    except OSError:
        return out
    for name in names:
        m = GENERATION.fullmatch(name)
        if not m:
            continue
        link = os.path.join(PROFILES, name)
        try:
            when = os.lstat(link).st_mtime
            path = os.path.realpath(link)
        except OSError:
            continue
        out.append(Generation(int(m.group(1)), path, when,
                              read(os.path.join(path, "nixos-version")), kernel(path)))
    return sorted(out, key=lambda g: g.number, reverse=True)


def is_system(path):
    """Whether `path` looks like a NixOS system closure (what nh checks)."""
    return all(os.path.exists(os.path.join(path, f))
               for f in ("bin/switch-to-configuration", "nixos-version", "init", "sw/bin"))


def human_size(n, signed=False):
    if n is None:
        return ""
    sign = ("+" if n > 0 else "−" if n < 0 else "") if signed else ""
    n = abs(n)
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if n < 1000 or unit == "TB":
            return f"{sign}{n:.0f} {unit}" if unit == "B" else f"{sign}{n:.1f} {unit}"
        n /= 1000
