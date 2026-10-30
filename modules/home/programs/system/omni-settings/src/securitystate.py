"""The Security tab's live state: each AppArmor profile's mode and what it
would have blocked since boot, and the user's own SSH keys."""

import glob
import json
import os
import re
import shutil
import subprocess

#--- Each loaded profile's mode, written by nixos/security/apparmor/default.nix
PROFILES = "/etc/omni-settings/apparmor.json"
#--- Where `include <abstractions/…>` resolves: the system's own, then upstream's
INCLUDES = ["/etc/apparmor.d", os.environ.get("OMNI_SETTINGS_APPARMOR_INCLUDES", "")]
ALLOWED = 'apparmor="ALLOWED"'
LINES = 40  # log lines kept per profile


#--------------------------------------------------------------------#
#-- AppArmor
#--------------------------------------------------------------------#
def profiles():
    """{name: mode} as the running system loaded them, or None without AppArmor."""
    try:
        with open(PROFILES) as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def allowed_lines():
    """{profile: [log line]} of what complain mode let through since boot; the newest
    LINES per profile. A child profile (mpv//null-…) counts for its parent."""
    proc = subprocess.run(["journalctl", "-b", "-g", ALLOWED, "-o", "cat", "--no-pager"],
                          capture_output=True, text=True, timeout=30, check=False)
    # journalctl exits 1 when nothing matches
    if proc.returncode not in (0, 1):
        raise RuntimeError(proc.stderr.strip() or "Couldn't read the journal")
    out = {}
    for line in proc.stdout.splitlines():
        m = re.search(r'profile="([^"]+)"', line)
        if m:
            out.setdefault(m.group(1).split("//")[0], []).append(line)
    return out


def apparmor():
    """[{name, mode, count, lines}] for each profile, or None without AppArmor."""
    modes = profiles()
    if modes is None:
        return None
    logged = allowed_lines()
    return [{"name": name, "mode": mode, "count": len(logged.get(name, [])),
             "lines": logged.get(name, [])[-LINES:]} for name, mode in sorted(modes.items())]


def compile_check(name):
    """Compiles the loaded profile `name` without loading it; raises with the parser's
    message when it fails. Its mode doesn't change the parse, so this is what boot loads."""
    modes = profiles() or {}
    if name not in modes:
        raise ValueError(f"No AppArmor profile named {name}")
    parser = shutil.which("apparmor_parser")
    if parser is None:
        raise RuntimeError("apparmor_parser isn't on the backend's PATH")
    cmd = [parser, "-Q", "-K"]
    for path in INCLUDES:
        if path:
            cmd += ["-I", path]
    proc = subprocess.run(cmd + [os.path.join("/etc/apparmor.d", name)], capture_output=True,
                          text=True, timeout=60, check=False)
    if proc.returncode != 0:
        raise ValueError(proc.stderr.strip() or f"{name} didn't compile")
    return True


#--------------------------------------------------------------------#
#-- SSH Keys
#--------------------------------------------------------------------#
def ssh_dir():
    return os.path.expanduser("~/.ssh")


def ssh_keys():
    """The user's public keys: [{file, type, bits, fingerprint, comment, key}]."""
    out = []
    for path in sorted(glob.glob(os.path.join(ssh_dir(), "*.pub"))):
        try:
            with open(path) as f:
                key = f.read().strip()
        except OSError:
            continue
        proc = subprocess.run(["ssh-keygen", "-l", "-f", path], capture_output=True, text=True,
                              timeout=10, check=False)
        # "256 SHA256:abc… user@host (ED25519)"
        m = re.match(r"(\d+)\s+(\S+)\s+(.*?)\s*\((\S+)\)$", proc.stdout.strip())
        if not m:
            continue
        out.append({"file": os.path.basename(path), "bits": int(m.group(1)), "fingerprint": m.group(2),
                    "comment": m.group(3), "type": m.group(4), "key": key})
    return out


def key_path(file):
    """The path of one of ssh_keys()'s files, refusing anything outside ~/.ssh."""
    if not file or "/" in file or not file.endswith(".pub"):
        raise ValueError("bad key file")
    path = os.path.join(ssh_dir(), file)
    if not os.path.isfile(path):
        raise ValueError(f"{file} isn't in ~/.ssh")
    return path


def github_add(file, title):
    """Adds a public key to the gh user's GitHub account."""
    gh = shutil.which("gh")
    if gh is None:
        raise RuntimeError("GitHub CLI (gh) isn't installed")
    proc = subprocess.run([gh, "ssh-key", "add", key_path(file), "--title", title],
                          capture_output=True, text=True, timeout=60, check=False,
                          stdin=subprocess.DEVNULL)
    if proc.returncode != 0:
        detail = (proc.stderr or proc.stdout).strip()
        if "admin:public_key" in detail:
            detail = "gh needs permission to add keys: run `gh auth refresh -s admin:public_key`"
        elif "already" in detail.lower():
            detail = "GitHub already has this key"
        raise ValueError(detail or "gh couldn't add the key")
    return True


def generate_command(comment):
    """The terminal command that makes a new ed25519 key, asking for its passphrase there."""
    path = os.path.join(ssh_dir(), "id_ed25519")
    n = 2
    while os.path.exists(path):
        path = os.path.join(ssh_dir(), f"id_ed25519_{n}")
        n += 1
    return ["xdg-terminal-exec", "ssh-keygen", "-t", "ed25519", "-C", comment, "-f", path]
