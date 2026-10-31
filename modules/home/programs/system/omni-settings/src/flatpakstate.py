"""The Flatpak apps and runtimes installed, the apps switched off here, update
checks, and the flatpak commands each action runs."""

import json
import os
import re
import shutil
import subprocess
from dataclasses import asdict, dataclass

FLATSEAL = "com.github.tchx84.Flatseal"
FLATHUB_REPO = "https://dl.flathub.org/repo/flathub.flatpakrepo"
APP_ID = re.compile(r"^[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+)+$")
INSTALLATIONS = ("user", "system")
COLUMNS = "application,name,version,branch,origin,installation,size,ref,runtime"
NOISE = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]|[█▉▊▋▌▍▎▏▒░▓]+")
SIZE = re.compile(r"([\d.]+)\s*([kMGT]?)B")
#--- Apps switched off here: {"<installation>:<id>": Ref fields}
OFF_FILE = os.path.join(os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state"),
                        "omni-settings", "flatpaks-off.json")


@dataclass
class Ref:
    kind: str  # app or runtime
    id: str
    name: str
    version: str
    branch: str
    origin: str  # the remote it came from
    installation: str  # user or system
    size: str
    ref: str  # id/arch/branch
    runtime: str = ""  # an app's runtime, id/arch/branch

    @property
    def key(self):
        return f"{self.installation}:{self.id}"


@dataclass
class Listing:
    apps: list
    runtimes: list
    remotes: dict  # (installation, name) -> url; "" when disabled, as a bundle's is
    off: list  # apps switched off here and not installed again since

    def bundle(self, ref):
        """Whether `ref` came from a downloaded file rather than a source it can
        be installed from again."""
        return not self.remotes.get((ref.installation, ref.origin))

    def installations(self):
        """The installations holding anything, user first."""
        used = {r.installation for r in self.apps + self.runtimes}
        return [i for i in INSTALLATIONS if i in used]


def binary():
    return shutil.which("flatpak")


def _flatpak(*args, timeout=60):
    return subprocess.run([binary(), *args], capture_output=True, text=True, timeout=timeout)


def size_bytes(text):
    """Bytes in one of flatpak's sizes, like "23.6 MB" (powers of 1000)."""
    m = SIZE.search(text or "")
    return int(float(m.group(1)) * 1000 ** " kMGT".index(m.group(2) or " ")) if m else 0


def clean(raw):
    """One line of flatpak's output without its colours and progress bars."""
    return " ".join(NOISE.sub(" ", raw).split())


#--------------------------------------------------------------------#
#-- Reading
#--------------------------------------------------------------------#
def load_off():
    try:
        with open(OFF_FILE) as f:
            data = json.load(f)
        return data if isinstance(data, dict) else {}
    except (OSError, ValueError):
        return {}


def save_off(off):
    os.makedirs(os.path.dirname(OFF_FILE), exist_ok=True)
    with open(OFF_FILE + ".tmp", "w") as f:
        json.dump(off, f, indent=1)
    os.replace(OFF_FILE + ".tmp", OFF_FILE)


def mark_off(ref):
    off = load_off()
    off[ref.key] = asdict(ref)
    save_off(off)


def forget(key):
    off = load_off()
    off.pop(key, None)
    save_off(off)


def listing():
    apps, runtimes = [], []
    for kind, into in (("app", apps), ("runtime", runtimes)):
        for line in _flatpak("list", f"--{kind}", f"--columns={COLUMNS}").stdout.splitlines():
            f = line.split("\t")  # a runtime's empty last column is left off
            if len(f) >= 8:
                f += [""] * (9 - len(f))
                into.append(Ref(kind, f[0], f[1] or f[0], f[2], f[3], f[4], f[5], f[6], f[7], f[8]))
    remotes = {}
    for line in _flatpak("remotes", "--show-disabled", "--columns=name,url,options").stdout.splitlines():
        name, url, options = (line.split("\t") + ["", ""])[:3]
        options = options.split(",")
        for inst in INSTALLATIONS:
            if inst in options:
                remotes[(inst, name)] = "" if "disabled" in options else url
    off = load_off()
    installed = {a.key for a in apps}
    if any(k in installed for k in off):  # installed again some other way
        off = {k: v for k, v in off.items() if k not in installed}
        save_off(off)
    off_refs = []
    for v in off.values():
        try:
            off_refs.append(Ref(**v))
        except TypeError:
            continue
    key = lambda r: r.name.casefold()  # noqa: E731
    return Listing(sorted(apps, key=key), sorted(runtimes, key=lambda r: r.id), remotes, sorted(off_refs, key=key))


def updates(installations):
    """The names of the refs with a newer version on their remote."""
    found, errors = [], []
    for inst in installations:
        res = _flatpak("remote-ls", "--updates", f"--{inst}", "--columns=name,application", timeout=180)
        if res.returncode != 0:
            errors.append((res.stderr or res.stdout).strip().splitlines()[-1:] or ["flatpak failed"])
        for line in res.stdout.splitlines():
            name, app = (line.split("\t") + [""])[:2]
            found.append(name or app)
    if errors and not found:
        raise RuntimeError(errors[0][0].removeprefix("error: "))
    return found


#--------------------------------------------------------------------#
#-- Commands
#--------------------------------------------------------------------#
def uninstall(ref):
    return [[binary(), "uninstall", f"--{ref.installation}", "-y", "--noninteractive", ref.id]]


def reinstall(ref):
    return [[binary(), "install", f"--{ref.installation}", "-y", "--noninteractive", ref.origin, f"app/{ref.ref}"]]


def search(text):
    """[{id, name, description, version}] on Flathub matching `text`, from the
    appstream data flatpak keeps locally (refreshed by its updates)."""
    proc = _flatpak("search", "--columns=application,name,description,version,remotes", text)
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or "flatpak search failed")
    out, seen = [], set()
    for line in proc.stdout.splitlines():
        cells = line.split("\t") + [""] * 5
        app, name, description, version, remotes = (c.strip() for c in cells[:5])
        if APP_ID.match(app) and "flathub" in remotes.split(",") and app not in seen:
            seen.add(app)
            out.append({"id": app, "name": name or app, "description": description, "version": version})
    return out


def install_flathub(app_id):
    """Into the user's installation, adding the user's flathub remote if it's missing."""
    return [[binary(), "remote-add", "--user", "--if-not-exists", "flathub", FLATHUB_REPO],
            [binary(), "install", "--user", "-y", "--noninteractive", "flathub", app_id]]


def runtime_source(lst, ref):
    """The remote to install `ref`'s missing runtime from, or None."""
    inst = ref.installation
    if lst.remotes.get((inst, "flathub")):
        return "flathub"
    return next((n for (i, n), url in lst.remotes.items() if i == inst and url), None)


def install_runtime(ref, remote):
    return [[binary(), "install", f"--{ref.installation}", "-y", "--noninteractive", remote,
             f"runtime/{ref.runtime}"]]


def update_all(lst):
    return [[binary(), "update", f"--{i}", "-y", "--noninteractive"] for i in lst.installations()]


def remove_unused(lst):
    return [[binary(), "uninstall", f"--{i}", "--unused", "-y", "--noninteractive"] for i in lst.installations()]


def repair(lst):
    #--- The system installation's files belong to root
    pkexec = "/run/wrappers/bin/pkexec" if os.path.exists("/run/wrappers/bin/pkexec") else "pkexec"
    return [([binary()] if i == "user" else [pkexec, binary()]) + ["repair", f"--{i}"]
            for i in lst.installations()]
