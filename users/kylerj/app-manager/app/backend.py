"""What the window asks of the system: the nixpkgs index, the user profile,
the declarations in packages.json, and whether the config still evaluates.

Everything runs a command and returns its text, so a failure is shown, never
raised at the window."""

import json
import os
import re
import shutil
import socket
import subprocess
import urllib.parse
from pathlib import Path

HOME = Path.home()
REPO = Path(os.environ.get("KY_CONFIG") or HOME / "nixos-config")
MANIFEST = REPO / "users/kylerj/app-manager/packages.json"
GROUP = "Apps"  # the one group packages.json keeps, the shape userPackages uses
MINE = ("machines/activenixtab/", "users/kylerj/")

#--- Filled in by the build, so the window needs no PATH of its own; running
#--- the checkout's copy instead falls back to whatever is installed
NIX = "@nix@/bin/nix"
SEARCH = "@search@/bin/nix-search-tv"
if NIX.startswith("@"):
    NIX = shutil.which("nix") or "nix"
if SEARCH.startswith("@"):
    SEARCH = shutil.which("nix-search-tv") or "nix-search-tv"

_nixpkgs = None


def run(args, timeout=900):
    """(ok, stdout, stderr) with the text as printed. A bad exit is not raised:
    the caller shows what nix said."""
    proc = subprocess.run(args, cwd=REPO, capture_output=True, text=True, timeout=timeout)
    return proc.returncode == 0, proc.stdout, proc.stderr


def hostname():
    return socket.gethostname().split(".")[0]


def nixpkgs_ref():
    """The flake's own nixpkgs, so an install lands on store paths the system
    already uses instead of a second copy fetched from the registry."""
    global _nixpkgs
    if _nixpkgs:
        return _nixpkgs
    lock = json.loads((REPO / "flake.lock").read_text())
    node = lock["nodes"][lock["root"]]["inputs"]["nixpkgs"]
    if not isinstance(node, str):
        # a `follows` needs the lock walked; the registry is the safe fallback
        _nixpkgs = "nixpkgs"
        return _nixpkgs
    locked = lock["nodes"][node]["locked"]
    if locked.get("repo") != "nixpkgs":
        _nixpkgs = f"github:{locked['owner']}/{locked['repo']}/{locked['rev']}"
        return _nixpkgs
    nar = urllib.parse.quote(locked["narHash"], safe="")
    _nixpkgs = f"github:NixOS/nixpkgs/{locked['rev']}?narHash={nar}"
    return _nixpkgs


#-- Search --------------------------------------------------------------#
_names = None


def names():
    """Every nixpkgs attribute name, from the index nix-search-tv keeps."""
    global _names
    if _names is None:
        ok, out, err = run([SEARCH, "print"])
        if not ok:
            raise RuntimeError((err.strip() or "nix-search-tv didn't run").splitlines()[-1])
        _names = [
            line[len("nixpkgs/ "):]
            for line in out.splitlines()
            if line.startswith("nixpkgs/ ")
        ]
    return _names


def search(query, limit=60):
    """Names holding every word of the query, shortest first so `vlc` comes
    before `vlc-plugins-all`."""
    words = query.lower().split()
    if not words:
        return []
    hits = [name for name in names() if all(word in name.lower() for word in words)]
    hits.sort(key=lambda name: (len(name), name))
    return hits[:limit]


def preview(attr):
    ok, out, err = run([SEARCH, "preview", attr], timeout=120)
    return out.strip() if ok else (err.strip() or "No details.")


def validate(attr):
    """(ok, text): whether `attr` still evaluates in the system's nixpkgs."""
    ok, out, err = run([NIX, "eval", "--raw", f"{nixpkgs_ref()}#{attr}.name"], timeout=600)
    if ok:
        return True, out.strip()
    if "does not provide attribute" in err:
        return False, "nixpkgs has no such package."
    tail = [line.strip() for line in err.strip().splitlines() if line.strip()]
    return False, (tail[-1][:300] if tail else "nixpkgs has no such package.")


#-- The profile ---------------------------------------------------------#
REV = re.compile(r"[/-]([0-9a-f]{40})\b")


def locked():
    """(rev, narHash) of the nixpkgs the system is built from."""
    lock = json.loads((REPO / "flake.lock").read_text())
    node = lock["nodes"][lock["root"]]["inputs"]["nixpkgs"]
    if not isinstance(node, str):
        return None, None
    entry = lock["nodes"][node]["locked"]
    return entry.get("rev"), entry.get("narHash")


def installed():
    """{profile key: {attr, rev, stale}} for what was installed without a
    rebuild. stale means it came from an older nixpkgs than the system's."""
    ok, out, _ = run([NIX, "profile", "list", "--json"], timeout=120)
    if not ok:
        return {}
    current, _ = locked()
    found = {}
    for key, item in (json.loads(out).get("elements") or {}).items():
        attr = item.get("attrPath") or key
        parts = attr.split(".")
        # legacyPackages.x86_64-linux.kdePackages.kate -> kdePackages.kate
        if len(parts) > 2 and parts[0] == "legacyPackages":
            attr = ".".join(parts[2:])
        match = REV.search(item.get("originalUrl") or "")
        rev = match.group(1) if match else None
        # a store-path install has no source to update from
        found[key] = {"attr": attr, "rev": rev, "stale": rev is not None and rev != current}
    return found


def install(attr):
    """(ok, text). Leaves the store to nix; nothing in the config changes."""
    ok, out, err = run([NIX, "profile", "add", f"{nixpkgs_ref()}#{attr}"], timeout=1800)
    return ok, (f"Installed {attr}." if ok else brief(err, out))


def uninstall(key):
    ok, out, err = run([NIX, "profile", "remove", key], timeout=300)
    return ok, (f"Removed {key}." if ok else brief(err, out))


def update(key, info):
    """Reinstall one app at the system's nixpkgs. A profile entry added from a
    locked flake ref can't be upgraded, so it is removed and added again; the
    old one goes back if the new one fails."""
    ok, out, err = run([NIX, "profile", "remove", key], timeout=300)
    if not ok:
        return False, brief(err, out)
    ok, out, err = run([NIX, "profile", "add", f"{nixpkgs_ref()}#{info['attr']}"], timeout=1800)
    if ok:
        return True, f"Updated {info['attr']}."
    text = brief(err, out)
    if info["rev"]:
        run([NIX, "profile", "add", f"github:NixOS/nixpkgs/{info['rev']}#{info['attr']}"], timeout=1800)
        return False, f"{info['attr']} stayed as it was.\n{text}"
    return False, f"{info['attr']} was removed and couldn't be put back.\n{text}"


def update_all():
    """(ok, text) for every app older than the system's nixpkgs."""
    stale = [(key, info) for key, info in installed().items() if info["stale"]]
    if not stale:
        return True, "Every app is at the system's nixpkgs."
    updated, failed = 0, []
    for key, info in stale:
        ok, text = update(key, info)
        if ok:
            updated += 1
        else:
            failed.append(text)
    if failed:
        return False, f"Updated {updated}, {len(failed)} didn't:\n" + "\n".join(failed)
    return True, f"Updated {updated} apps."


#-- Declarations --------------------------------------------------------#
def declared():
    """{group: [attr]} as packages.json holds it; an empty file reads as none."""
    try:
        data = json.loads(MANIFEST.read_text())
    except (OSError, ValueError):
        return {}
    if not isinstance(data, dict):
        return {}
    return {group: [str(name) for name in items] for group, items in data.items()}


def declared_attrs():
    return [attr for attrs in declared().values() for attr in attrs]


def write_declared(groups):
    """Sorted, indented and stable, so the file reads well in git."""
    MANIFEST.write_text(json.dumps(groups, indent=2, sort_keys=True) + "\n")


def keep(attr):
    """Declare an app for good. It stays installed until the next rebuild, so
    nothing disappears if the rebuild waits."""
    ok, text = validate(attr)
    if not ok:
        return False, text
    groups = declared()
    if attr in declared_attrs():
        return True, f"{attr} is already kept."
    groups.setdefault(GROUP, []).append(attr)
    write_declared(groups)
    return True, f"Kept {attr}. It becomes part of the system on the next rebuild."


def unkeep(attr):
    groups = declared()
    if attr not in declared_attrs():
        return True, f"{attr} wasn't kept."
    for group, attrs in groups.items():
        groups[group] = [name for name in attrs if name != attr]
    write_declared({group: attrs for group, attrs in groups.items() if attrs})
    return True, f"{attr} is no longer kept. A rebuild drops it from the system."


def tidy():
    """Remove the profile copies of apps that are kept, which the next rebuild
    provides from the system instead."""
    kept = set(declared_attrs())
    gone = [key for key, info in installed().items() if info["attr"] in kept]
    for key in gone:
        ok, text = uninstall(key)
        if not ok:
            return False, text
    return True, (f"Cleaned up {len(gone)}." if gone else "Nothing to clean up.")


#-- What a failed rebuild blames ----------------------------------------#
def brief(*streams):
    """The last few lines of a command's output, which is the part that says
    what went wrong."""
    lines = [line for text in streams for line in text.strip().splitlines() if line.strip()]
    return "\n".join(lines[-12:])


def interesting(text):
    """Only the lines naming Ky's own files, plus nix's own error lines, so a
    traceback through Warpledge's modules doesn't bury the cause."""
    lines = [line.rstrip() for line in text.splitlines()]
    keep = [
        line for line in lines
        if any(mine in line for mine in MINE) or line.strip().startswith("error:")
    ]
    seen, out = set(), []
    for line in keep:
        if line not in seen:
            seen.add(line)
            out.append(line)
    return out[-60:] or lines[-20:]


def check():
    """A list of paragraphs: declarations nixpkgs no longer has, then whatever
    evaluating the system says."""
    notes = []
    for attr in declared_attrs():
        ok, text = validate(attr)
        if not ok:
            notes.append(f"packages.json lists '{attr}', which nixpkgs no longer has.\n{text}")
    ok, _, err = run(
        [NIX, "eval", "--raw",
         f".#nixosConfigurations.{hostname()}.config.system.build.toplevel.drvPath"],
        timeout=1800,
    )
    if ok and not notes:
        notes.append("The config evaluates. Nothing to fix.")
    elif not ok:
        notes.append("The config doesn't evaluate. These lines name your own files:")
        notes.extend(interesting(err))
    return notes
