"""Search's nixpkgs index, through nix-search-tv. It keeps its own index of
search.nixos.org's unstable channel in ~/.cache/nix-search-tv, made again once
a week, so the list can be a few days off this system's flake.lock. `print`
lists every name and `preview` gives one package's details."""

import json
import os
import re
import subprocess
import time

import system

TOOL = "nix-search-tv"
PREFIX = "nixpkgs/ "  # print also lists Home Manager, NixOS and NUR entries
SHOWN = 50  # results listed at once
NAMES_FOR = 86400  # seconds cached_names keeps a list, so a week's index refresh shows
ANSI = re.compile(r"\x1b\[[0-9;]*m")
TITLE = re.compile(r"^(\S+) \(([^)]*)\)(.*)$")  # "name (version)", then "(broken)" if so
#--- Categories Install offers before any are in use; a new name can be typed too
STARTER = ["Media", "Gaming", "Development", "Graphics", "Office", "Internet", "Utilities"]


def names():
    """Every nixpkgs attribute name in nix-search-tv's index."""
    out = subprocess.run([TOOL, "print"], capture_output=True, text=True, timeout=600, check=True)
    return sorted(line[len(PREFIX):] for line in out.stdout.splitlines() if line.startswith(PREFIX))


def cached_names():
    """names(), kept in a file for NAMES_FOR, as each search is a new process."""
    path = os.path.join(system.runtime_dir(), "package-names.json")
    try:
        if time.time() - os.path.getmtime(path) < NAMES_FOR:
            with open(path) as f:
                return json.load(f)
    except (OSError, ValueError):
        pass
    found = names()
    tmp = f"{path}.{os.getpid()}"
    with open(tmp, "w") as f:
        json.dump(found, f)
    os.replace(tmp, path)
    return found


def preview(attr):
    """A package's details from `nix-search-tv preview`: version, description,
    about, homepage, licence, unfree and the program it runs."""
    out = subprocess.run([TOOL, "preview", PREFIX + attr], capture_output=True, text=True, timeout=30)
    blocks = [b.splitlines() for b in ANSI.sub("", out.stdout).strip().split("\n\n") if b.strip()]
    info = {"version": "", "description": "", "about": "", "homepage": [], "licenses": [],
            "unfree": False, "broken": False, "program": ""}
    if not blocks:
        return info
    head = blocks[0]
    m = TITLE.match(head[0].strip())
    if m:
        info["version"] = m.group(2)
        info["broken"] = "broken" in m.group(3)
    info["description"] = " ".join(l.strip() for l in head[1:])
    for block in blocks[1:]:
        title, values = block[0].strip(), [l.strip() for l in block[1:] if l.strip()]
        if title == "homepage":
            info["homepage"] = values
        elif title.startswith("license"):
            info["licenses"] = values
            info["unfree"] = "unfree" in title
        elif title == "main program":
            info["program"] = next((v.strip("│ ").removeprefix("$ ") for v in values if "$" in v), "")
        elif title in ("platforms", "outputs"):
            continue
        elif not info["about"]:
            info["about"] = " ".join(l.strip() for l in block)
    return info


def search(index, query):
    """Names holding every word of `query`, best first: the name itself, then
    its start (or its last part's, for `python313Packages.x`), then anywhere."""
    q = query.strip().lower()
    words = q.split()
    if not words:
        return []
    hits = []
    for name in index:
        low = name.lower()
        if not all(w in low for w in words):
            continue
        last = low.rsplit(".", 1)[-1]
        rank = 0 if low == q else 1 if low.startswith(q) or last.startswith(q) else 2
        hits.append((rank, low.count("."), len(low), name))
    hits.sort()
    return [h[3] for h in hits]


def flat(groups):
    """Every package name in a userPackages set, over all its categories."""
    return [name for names in groups.values() for name in names]


def category_of(groups, attr):
    return next((cat for cat, names in groups.items() if attr in names), None)
