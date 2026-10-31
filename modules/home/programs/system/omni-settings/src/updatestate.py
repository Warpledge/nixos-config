"""Pinned Versions on the Maintenance page and `nixm check-updates`: what upstream has released since the
versions the config pins by hand (lib/upstream.json, plus the machine's own
machines/<name>/upstream.json), flake inputs locked to a version tag, and
whether the packages in docs/nixpkgs/disabled-packages.md build again on
nixos-unstable. Read-only: nothing here changes a pin. Results are kept for an
hour in the runtime directory, since each backend call is a new process."""

import concurrent.futures
import json
import os
import re
import subprocess
import time
import urllib.error

import backend
import gitstate
import system

KEEP = 3600
VERSION = re.compile(r'version\s*=\s*"([^"]+)"')
REV = re.compile(r'rev\s*=\s*"([0-9a-f]{40})"|/([0-9a-f]{40})/')
UNSTABLE_DATE = re.compile(r"unstable-(\d{4}-\d\d-\d\d)")
TAG = re.compile(r"^v?\d+(\.\d+)+$")
DISABLED_DOC = "docs/nixpkgs/disabled-packages.md"
KINDS = ["disabled", "release", "nightly", "input", "commit", "local"]


def _cache_path():
    return os.path.join(system.runtime_dir(), "upstream.json")


def _read(path):
    try:
        with open(path) as f:
            return f.read()
    except OSError:
        return None


def _bare(tag, prefix=""):
    tag = tag[len(prefix):] if prefix and tag.startswith(prefix) else tag
    return tag[1:] if tag[:1] == "v" and tag[1:2].isdigit() else tag


def _row(kind, e, current="", latest="", status="ok", note="", link=""):
    return {"kind": kind, "name": e["name"], "current": current, "latest": latest,
            "status": status, "note": note, "link": link or f"https://github.com/{e['repo']}",
            "file": e.get("file", "")}


def _why(error):
    if isinstance(error, urllib.error.HTTPError):
        return "GitHub's hourly limit is used up" if error.code in (403, 429) else f"GitHub: {error.code}"
    return str(error).splitlines()[0] if str(error) else type(error).__name__


#--------------------------------------------------------------------#
#-- What to check
#--------------------------------------------------------------------#
def manifest(flake, machine):
    """lib/upstream.json with the machine's own list added, kind by kind."""
    out = {}
    for rel in ("lib/upstream.json", f"machines/{machine}/upstream.json"):
        text = _read(os.path.join(flake, rel))
        for kind, entries in (json.loads(text) if text else {}).items():
            out.setdefault(kind, []).extend(entries)
    return out


def wanted(cfg, kinds):
    """The manifest's entries whose file exists and whose app toggle is on here."""
    state = backend.load(cfg)
    machine, user = state.resolved, state.resolved["users"].get(cfg.user, {})
    toggle_of = {path: key for key, path in backend.toggle_modules(cfg.flake).items()}

    def on(settings, key):
        for part in key:
            settings = settings.get(part) if isinstance(settings, dict) else None
        return bool(settings)

    out = {}
    for kind, entries in kinds.items():
        for e in entries:
            path = os.path.join(cfg.flake, e["file"])
            if not os.path.isfile(path):
                continue
            if "machineToggle" in e and not on(machine, e["machineToggle"].split(".")):
                continue
            if path in toggle_of and not on(user, toggle_of[path]):
                continue
            out.setdefault(kind, []).append(e)
    return out


#--------------------------------------------------------------------#
#-- Checks, one row each
#--------------------------------------------------------------------#
def release(cfg, e):
    current = (VERSION.search(_read(os.path.join(cfg.flake, e["file"])) or "") or [None, ""])[1]
    rel = gitstate.github(f"repos/{e['repo']}/releases/latest")
    latest = _bare(rel["tag_name"], e.get("tagPrefix", ""))
    return _row("release", e, current, latest, "ok" if latest == current else "update",
                link=rel.get("html_url", ""))


def nightly(cfg, e):
    """A rolling release: compares the date its files were last replaced with the
    date in the pinned `-unstable-YYYY-MM-DD` version."""
    text = _read(os.path.join(cfg.flake, e["file"])) or ""
    found = UNSTABLE_DATE.search((VERSION.search(text) or [None, ""])[1])
    current = found[1] if found else ""
    rel = gitstate.github(f"repos/{e['repo']}/releases/tags/{e.get('tag', 'nightly')}")
    latest = max([a["updated_at"] for a in rel.get("assets", [])] or [rel["published_at"]])[:10]
    status = "unknown" if not current else "update" if latest > current else "ok"
    return _row("nightly", e, current, latest, status, link=rel.get("html_url", ""))


def commit(cfg, e):
    found = REV.search(_read(os.path.join(cfg.flake, e["file"])) or "")
    rev = found and (found[1] or found[2])
    if not rev:
        return _row("commit", e, status="error", note=f"no commit hash found in {e['file']}")
    branch = e.get("branch") or gitstate.github(f"repos/{e['repo']}")["default_branch"]
    ahead = gitstate.github(f"repos/{e['repo']}/compare/{rev}...{branch}")["ahead_by"]
    return _row("commit", e, rev[:7], f"{branch} +{ahead}" if ahead else branch,
                "update" if ahead else "ok", link=f"https://github.com/{e['repo']}/compare/{rev}...{branch}")


def local(_cfg, e):
    """A ~/.local/opt bundle: its version from a file it ships, else the
    `.version` file written when it was installed."""
    folder = os.path.expanduser(e["dir"])
    current = ""
    if e.get("versionJson"):
        rel, key = e["versionJson"]
        try:
            current = str(json.loads(_read(os.path.join(folder, rel)) or "{}").get(key, ""))
        except ValueError:
            pass
    if not current:
        current = (_read(os.path.join(folder, ".version")) or "").strip()
    rel = gitstate.github(f"repos/{e['repo']}/releases/latest")
    latest = _bare(rel["tag_name"], e.get("tagPrefix", ""))
    if not current:
        return _row("local", e, "", latest, "unknown", link=rel.get("html_url", ""),
                    note=f"installed version unknown: write it to {e['dir']}/.version")
    return _row("local", e, _bare(current), latest, "ok" if latest == _bare(current) else "update",
                link=rel.get("html_url", ""))


def tagged_inputs(flake):
    """The flake's own inputs locked to a version tag on GitHub (moku, tsunagu)."""
    lock = json.loads(_read(os.path.join(flake, "flake.lock")) or "{}")
    nodes = lock.get("nodes", {})
    out = []
    for name, ref in nodes.get(lock.get("root", "root"), {}).get("inputs", {}).items():
        orig = nodes.get(ref if isinstance(ref, str) else "", {}).get("original", {})
        if orig.get("type") == "github" and TAG.match(orig.get("ref", "")):
            out.append({"name": name, "repo": f"{orig['owner']}/{orig['repo']}", "file": "flake.nix",
                        "ref": orig["ref"]})
    return out


def tagged(_cfg, e):
    rel = gitstate.github(f"repos/{e['repo']}/releases/latest")
    current, latest = _bare(e["ref"]), _bare(rel["tag_name"])
    return _row("input", e, current, latest, "ok" if latest == current else "update",
                link=rel.get("html_url", ""))


#--------------------------------------------------------------------#
#-- Disabled packages
#--------------------------------------------------------------------#
def disabled_names(flake):
    """The first column of the table in disabled-packages.md."""
    names = []
    for line in (_read(os.path.join(flake, DISABLED_DOC)) or "").splitlines():
        cells = [c.strip().strip("`") for c in line.strip().strip("|").split("|")]
        if line.startswith("|") and cells[0] and cells[0] != "Package" and not cells[0].startswith("---"):
            names.append(cells[0])
    return names


def disabled(_cfg, e):
    """Fixed once Hydra has built it at nixos-unstable's head; Hydra skips unfree
    packages, so those can only be tried with `nixm dryrun`."""
    ref = f"github:NixOS/nixpkgs/{e['rev']}#{e['name']}"
    out = subprocess.run(["nix", "eval", "--json", ref, "--apply",
                          "p: {unfree = p.meta.unfree or false; "
                          "out = if p.meta.unfree or false then \"\" else p.outPath;}"],
                         capture_output=True, text=True, timeout=600, stdin=subprocess.DEVNULL)
    if out.returncode != 0:
        err = next((ln for ln in out.stderr.splitlines() if "error:" in ln), out.stderr.strip())
        return _row("disabled", e, status="error", note=err.strip()[:200], link=e["link"])
    got = json.loads(out.stdout)
    if got["unfree"]:
        return _row("disabled", e, status="unknown", note="unfree: try it with `nixm dryrun`",
                    link=e["link"])
    built = subprocess.run(["nix", "path-info", "--store", "https://cache.nixos.org", got["out"]],
                           capture_output=True, timeout=60, stdin=subprocess.DEVNULL).returncode == 0
    return _row("disabled", e, latest=e["rev"][:7], status="update" if built else "ok",
                note="builds on nixos-unstable: turn it back on" if built
                else "not built on nixos-unstable yet", link=e["link"])


#--------------------------------------------------------------------#
#-- All of it
#--------------------------------------------------------------------#
def check(cfg):
    entries = wanted(cfg, manifest(cfg.flake, cfg.machine))
    jobs = []
    for kind, fn in (("release", release), ("nightly", nightly), ("commit", commit), ("local", local)):
        jobs += [(kind, fn, e) for e in entries.get(kind, [])
                 if kind != "local" or os.path.isdir(os.path.expanduser(e["dir"]))]
    jobs += [("input", tagged, e) for e in tagged_inputs(cfg.flake)]
    names = disabled_names(cfg.flake)
    if names:
        try:
            rev = gitstate.github("repos/NixOS/nixpkgs/branches/nixos-unstable")["commit"]["sha"]
        except (OSError, ValueError, KeyError):
            rev = "nixos-unstable"  # unpinned: nix resolves the branch itself
        jobs += [("disabled", disabled,
                  {"name": n, "repo": "NixOS/nixpkgs", "file": DISABLED_DOC, "rev": rev,
                   "link": f"https://hydra.nixos.org/job/nixpkgs/trunk/{n}.x86_64-linux"})
                 for n in names]

    def one(job):
        kind, fn, e = job
        try:
            return fn(cfg, e)
        except (OSError, ValueError, KeyError, subprocess.TimeoutExpired) as error:
            return _row(kind, e, status="error", note=_why(error), link=e.get("link", ""))

    with concurrent.futures.ThreadPoolExecutor(8) as pool:
        rows = list(pool.map(one, jobs))
    rows.sort(key=lambda r: (KINDS.index(r["kind"]), r["status"] != "update", r["name"].lower()))
    return rows


def run(cfg, force=False, cached_only=False):
    """{checked: epoch, rows}; a check younger than an hour is handed back as it is."""
    try:
        cached = json.loads(_read(_cache_path()) or "null")
    except ValueError:
        cached = None
    if cached and (cached_only or (not force and time.time() - cached["checked"] < KEEP)):
        return cached
    if cached_only:
        return {"checked": None, "rows": []}
    result = {"checked": time.time(), "rows": check(cfg)}
    with open(_cache_path(), "w") as f:
        json.dump(result, f)
    return result
