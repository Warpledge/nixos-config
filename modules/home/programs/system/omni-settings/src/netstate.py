"""The Network tab's live state: DNS from systemd-resolved, Mullvad's tunnel,
and which blocklist holds a domain (blockers.nix writes the lists' paths)."""

import json
import re
import shutil
import subprocess

#--- Each enabled list's own hosts file, written by nixos/network/blockers.nix
BLOCKLISTS = "/etc/omni-settings/blocklists.json"
LIST_TITLES = {"ads": "Ads and trackers", "fakenews": "Fake news", "gambling": "Gambling",
               "porn": "Adult sites", "social": "Social media"}
DOMAIN = re.compile(r"^[a-zA-Z0-9_-]+([.][a-zA-Z0-9_-]+)+$")

#--- What the Tools page runs, as `nixm ping` and `nixm speedtest` do
PING = ["ping", "-c", "5", "8.8.8.8"]
SPEEDTEST = ["speedtest-cli", "--secure", "--simple"]  # Ping, Download and Upload lines


#--------------------------------------------------------------------#
#-- DNS
#--------------------------------------------------------------------#
def dns():
    """systemd-resolved's DNS-over-TLS mode and the server in use:
    {tls, server, servers}."""
    proc = subprocess.run(["resolvectl", "status", "--no-pager"], capture_output=True, text=True,
                          timeout=10, check=False)
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or "resolvectl couldn't read the DNS settings")
    tls = re.search(r"DNSOverTLS=(\S+)", proc.stdout)
    current = re.findall(r"Current DNS Server:\s*(\S+)", proc.stdout)
    servers = []
    for line in re.findall(r"DNS Servers:\s*(.+)", proc.stdout):
        servers += [s for s in line.split() if s not in servers]
    return {"tls": tls.group(1) if tls else "no", "server": current[0] if current else "",
            "servers": servers}


#--------------------------------------------------------------------#
#-- Mullvad
#--------------------------------------------------------------------#
def mullvad():
    """The tunnel's state and relay, or None without the mullvad CLI:
    {state, relay, location, entry, features}."""
    exe = shutil.which("mullvad")
    if exe is None:
        return None
    proc = subprocess.run([exe, "status", "--json"], capture_output=True, text=True, timeout=10,
                          check=False)
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or "The Mullvad daemon didn't answer")
    try:
        status = json.loads(proc.stdout)
    except ValueError as e:
        raise RuntimeError("Mullvad's status wasn't readable") from e
    details = status.get("details") or {}
    loc = details.get("location") or {}
    place = ", ".join(p for p in (loc.get("city"), loc.get("country")) if p)
    entry = loc.get("entry_hostname") or ""
    return {"state": status.get("state", ""), "relay": loc.get("hostname") or "",
            "location": place, "entry": entry,
            "entryLocation": ", ".join(p for p in (loc.get("entry_city"), loc.get("entry_country")) if p),
            "features": details.get("feature_indicators") or []}


#--------------------------------------------------------------------#
#-- Blocklist Lookup
#--------------------------------------------------------------------#
def lists():
    """{name: hosts path} for the lists this build blocks, empty when blocking is off."""
    try:
        with open(BLOCKLISTS) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def lookup(domain, allowed):
    """Which lists hold `domain`, and whether this computer blocks it now:
    {domain, lists: [title], allowed, blocked, enabled}."""
    domain = domain.strip().lower().removeprefix("https://").removeprefix("http://").split("/")[0]
    if not DOMAIN.match(domain):
        raise ValueError("Type a domain name, like example.com")
    found = []
    paths = lists()
    for name, path in paths.items():
        try:
            with open(path, errors="replace") as f:
                if any(line.split()[1:2] == [domain] for line in f if line.startswith("0.0.0.0 ")):
                    found.append(LIST_TITLES.get(name, name))
        except OSError:
            continue
    # The whitelist drops every hosts line naming an allowed domain (stevenblack.nix)
    unblocked = any(a.lower() in domain for a in allowed)
    try:
        with open("/etc/hosts", errors="replace") as f:
            blocked = any(line.split()[1:2] == [domain] for line in f if line.startswith("0.0.0.0 "))
    except OSError:
        blocked = bool(found) and not unblocked
    return {"domain": domain, "lists": found, "allowed": unblocked, "blocked": blocked,
            "enabled": bool(paths)}
