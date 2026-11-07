"""The Drives page: block devices from lsblk, SMART health from the file
nixos/services/hardware/drive-health.nix writes, and session mounts through
udisks. Nothing here formats, partitions or unlocks a drive."""

import json
import os
import re
import shutil
import subprocess

HEALTH_FILE = "/run/drive-health/health.json"
COLUMNS = "NAME,PATH,TYPE,SIZE,FSTYPE,UUID,LABEL,FSAVAIL,FSUSE%,MOUNTPOINTS,MODEL,HOTPLUG"
#--- Keep in sync with drive-mounts.nix and drives.mounts' check in lib/settings.nix
FILESYSTEMS = ("ext4", "btrfs", "xfs", "vfat", "exfat", "ntfs")
#--- Mount points the page never touches; a folder under one counts too
SYSTEM_MOUNTS = ("/", "/boot", "/nix", "/home", "/var", "/etc", "/usr", "[SWAP]")


#--------------------------------------------------------------------#
#-- Reading
#--------------------------------------------------------------------#
def lsblk():
    proc = subprocess.run(["lsblk", "-J", "-b", "-o", COLUMNS], capture_output=True, text=True,
                          timeout=20, check=False)
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or "lsblk failed")
    return json.loads(proc.stdout).get("blockdevices", [])


def crypttab(path="/etc/crypttab"):
    """The real device of each line in crypttab."""
    out = set()
    try:
        with open(path) as f:
            for line in f:
                fields = line.split()
                if len(fields) >= 2 and not fields[0].startswith("#"):
                    out.add(os.path.realpath(fields[1]))
    except OSError:
        pass
    return out


def fstab_points(path="/etc/fstab"):
    """Mount points fstab already claims, mounted or not."""
    out = []
    try:
        with open(path) as f:
            for line in f:
                fields = line.split()
                if len(fields) >= 2 and not fields[0].startswith("#"):
                    out.append(fields[1])
    except OSError:
        pass
    return out


def health():
    try:
        with open(HEALTH_FILE) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def is_system(point):
    return any(point == s or (s != "/" and point.startswith(s + "/")) for s in SYSTEM_MOUNTS)


def refusal(vol, encrypted, locked):
    """Why the page won't mount or unmount this volume, or "" when it will."""
    points = [p for p in vol.get("mountpoints") or [] if p]
    if encrypted or vol.get("fstype") == "crypto_LUKS" or vol["path"] in locked:
        return "Encrypted drives are managed in the machine's hardware files"
    if vol.get("fstype") not in FILESYSTEMS:
        return "No filesystem this page can mount"
    if any(is_system(p) for p in points):
        return "The system runs from this"
    return ""


def volumes(node, locked, encrypted=False):
    """`node`'s filesystems and its children's, flattened; everything under a LUKS
    container counts as encrypted."""
    inside = encrypted or node.get("fstype") == "crypto_LUKS" or node.get("type") == "crypt"
    kids = node.get("children") or []
    out = []
    #--- An open LUKS container shows as the volume inside it
    if not kids or node.get("fstype") not in (None, "", "crypto_LUKS"):
        points = [p for p in node.get("mountpoints") or [] if p]
        reason = refusal(node, inside, locked)
        label = node.get("label") or ""
        out.append({"name": node["name"], "path": node["path"], "size": node.get("size") or 0,
                    "fstype": node.get("fstype") or "", "uuid": node.get("uuid") or "", "label": label,
                    "mounted": min(points, key=len) if points else "", "free": node.get("fsavail"),
                    "used": int((node.get("fsuse%") or "0").rstrip("%")) if points else None,
                    "encrypted": inside, "refused": reason,
                    "suggest": "/mnt/" + (re.sub(r"[^A-Za-z0-9._-]", "-", label).lstrip(".-") or node["name"])})
    for k in kids:
        out += volumes(k, locked, inside)
    return out


def drives():
    """Each disk with its health and volumes, and the mount points already claimed."""
    locked = crypttab()
    read = health()
    known = read.get("drives") or {}
    disks = []
    claimed = set(fstab_points())
    for d in lsblk():
        if d.get("type") != "disk" or d["name"].startswith("zram"):
            continue
        vols = volumes(d, locked)
        claimed.update(v["mounted"] for v in vols if v["mounted"])
        disks.append({"name": d["name"], "path": d["path"], "model": (d.get("model") or d["name"]).strip(),
                      "size": d.get("size") or 0, "removable": bool(d.get("hotplug")),
                      "health": known.get(d["path"]), "volumes": vols})
    return {"disks": disks, "claimed": sorted(claimed), "checked": read.get("checked")}


#--------------------------------------------------------------------#
#-- Session Mounts
#--------------------------------------------------------------------#
def find(path):
    """The volume at `path`, read fresh so the check can't act on a stale page."""
    locked = crypttab()
    for d in lsblk():
        for v in volumes(d, locked):
            if v["path"] == path:
                return v
    return None


def act(path, mount):
    """Mounts or unmounts `path` through udisks after re-checking it; ValueError
    says why it was refused or failed."""
    vol = find(path) if isinstance(path, str) else None
    if vol is None:
        raise ValueError("That drive isn't here any more")
    if vol["refused"]:
        raise ValueError(vol["refused"])
    if mount == bool(vol["mounted"]):
        raise ValueError("Already mounted" if mount else "Already unmounted")
    exe = shutil.which("udisksctl")
    if exe is None:
        raise ValueError("udisks isn't installed on this computer")
    try:
        proc = subprocess.run([exe, "mount" if mount else "unmount", "-b", vol["path"]],
                              capture_output=True, text=True, timeout=120, check=False)
    except subprocess.TimeoutExpired:
        raise ValueError("udisks didn't answer in time") from None
    if proc.returncode != 0:
        raise ValueError(proc.stderr.strip() or "udisks refused")
    return proc.stdout.strip()
