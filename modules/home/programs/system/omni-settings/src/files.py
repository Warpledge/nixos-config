"""The files a rebuild would write, beyond the packages: /etc from the system and
each person's home-manager files (`~/.config` and the rest). A preview reads
both trees in the store, so the run page shows what they would hold after
Apply. The root helper imports this too, so it stays free of GTK."""

import difflib
import hashlib
import os
import re

CURRENT = "/run/current-system"
STORE = "/nix/store/"
HOME_UNIT = re.compile(r"^home-manager-(.+)\.service$")
GENERATION = re.compile(r"/nix/store/[a-z0-9]+-home-manager-generation")
#--- The files read for a text diff, and how much of every diff is kept
TEXT_LIMIT = 200_000
TEXT_LINES = 120
TOTAL_LINES = 2000
#--- Symlinked /etc trees whose thousands of files say nothing a person can use:
#--- the package list already covers the profile, and terminfo, zoneinfo and
#--- kbd's maps are data a timezone or keymap change rewrites whole
NOISE = {"profiles", "terminfo", "zoneinfo", "kbd"}


def in_store(path):
    """Whether `path` resolves inside the store. The helper runs this as root, so
    a link out of the store (an /etc entry naming /run, an out-of-store
    home-manager link) is compared by its target and never read."""
    return os.path.realpath(path).startswith(STORE)


def digest(path):
    """A hash of the file's contents, so two store paths holding the same text match."""
    if not in_store(path):
        return "outside:" + os.path.realpath(path)
    h = hashlib.sha256()
    try:
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(1 << 16), b""):
                h.update(chunk)
        return h.hexdigest()
    except OSError:
        try:  # a link to nothing: its target is all there is to compare
            return "link:" + os.readlink(path)
        except OSError:
            return ""


def tree(root):
    """{relative path: digest} for the files under `root`, following links."""
    found, seen = {}, set()
    for base, dirs, names in os.walk(root, followlinks=True):
        real = os.path.realpath(base)
        if real in seen:
            dirs[:] = []
            continue
        seen.add(real)
        dirs[:] = [d for d in dirs if d not in NOISE and in_store(os.path.join(base, d))]
        for name in names:
            path = os.path.join(base, name)
            found[os.path.relpath(path, root)] = path
    return {rel: digest(path) for rel, path in found.items()}


def text_diff(before, after, budget):
    """A short unified diff of two files' text; [] for binaries, big files and
    files the two systems name differently."""
    lines = []
    if budget <= 0 or not (in_store(before) and in_store(after)):
        return lines
    try:
        if max(os.path.getsize(before), os.path.getsize(after)) > TEXT_LIMIT:
            return lines
        with open(before, "rb") as f:
            old = f.read().decode("utf-8")
        with open(after, "rb") as f:
            new = f.read().decode("utf-8")
    except (OSError, UnicodeDecodeError):
        return lines
    for line in difflib.unified_diff(old.splitlines(), new.splitlines(), lineterm="", n=2):
        if line.startswith(("---", "+++")):
            continue
        lines.append(line)
        if len(lines) >= min(TEXT_LINES, budget):
            break
    return lines


def group(title, prefix, old_root, new_root, budget):
    """One tree's changes as {title, items}; items are {path, status, diff}."""
    old, new = tree(old_root), tree(new_root)
    items = []
    for path in sorted(set(old) | set(new)):
        if path in old and path in new and old[path] == new[path]:
            continue
        status = "added" if path not in old else "removed" if path not in new else "changed"
        lines = []
        if status == "changed":
            lines = text_diff(os.path.join(old_root, path), os.path.join(new_root, path), budget)
            budget -= len(lines)
        items.append({"path": prefix + path, "status": status, "diff": lines})
    return {"title": title, "items": items}


def users(system):
    """The names with a home-manager unit in a system's /etc."""
    try:
        names = os.listdir(os.path.join(system, "etc/systemd/system"))
    except OSError:
        return []
    return sorted(m.group(1) for m in map(HOME_UNIT.match, names) if m)


def generation(system, user):
    """The home-manager generation a system's unit for `user` would activate."""
    unit = os.path.join(system, "etc/systemd/system", f"home-manager-{user}.service")
    try:
        with open(unit) as f:
            for line in f:
                if line.startswith("ExecStart="):
                    found = GENERATION.search(line)
                    return found.group(0) if found else None
    except OSError:
        return None
    return None


def changes(old=CURRENT, new=None):
    """{groups, changed, added, removed} for /etc and each person's files, the
    built system `new` against the running one."""
    groups = [group("/etc", "/etc/", os.path.join(old, "etc"), os.path.join(new, "etc"), TOTAL_LINES)]
    for user in users(new):
        before, after = generation(old, user), generation(new, user)
        if before and after:
            groups.append(group(f"~ ({user})", "~/", os.path.join(before, "home-files"),
                                os.path.join(after, "home-files"), TOTAL_LINES))
    counts = {"changed": 0, "added": 0, "removed": 0}
    left = TOTAL_LINES
    for g in groups:
        for item in g["items"]:
            counts[item["status"]] += 1
            item["diff"] = item["diff"][:max(0, left)]
            left -= len(item["diff"])
    counts["groups"] = [g for g in groups if g["items"]]
    return counts
