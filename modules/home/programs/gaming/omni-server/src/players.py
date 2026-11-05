"""The whitelist, ops and bans. While the server runs these go through its own
commands, which also look up the UUID. While it's stopped the JSON files are edited
directly, with the UUID from Mojang (online mode) or computed (offline mode)."""

import hashlib
import json
import os
import tempfile
import urllib.error
import urllib.request
import uuid

import properties
import servers

FILES = {"whitelist": "whitelist.json", "ops": "ops.json", "bans": "banned-players.json",
         "ipBans": "banned-ips.json"}
ON = {"whitelist": "whitelist add {name}", "ops": "op {name}", "bans": "ban {name}"}
OFF = {"whitelist": "whitelist remove {name}", "ops": "deop {name}", "bans": "pardon {name}"}


def read_list(cfg, which):
    try:
        with open(f"{cfg['dir']}/{FILES[which]}", encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, ValueError):
        return []
    return data if isinstance(data, list) else []


def write_list(cfg, which, entries):
    target = f"{cfg['dir']}/{FILES[which]}"
    fd, tmp = tempfile.mkstemp(dir=cfg["dir"], prefix=f".{FILES[which]}.")
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(entries, f, indent=2)
    os.replace(tmp, target)


def overview(cfg):
    values = properties.read(servers.props_file(cfg))
    return {
        "whitelistOn": values.get("white-list", values.get("enforce-whitelist", "false")) == "true",
        "whitelist": read_list(cfg, "whitelist"),
        "ops": read_list(cfg, "ops"),
        "bans": read_list(cfg, "bans"),
        "ipBans": read_list(cfg, "ipBans"),
    }


def offline_uuid(name):
    digest = bytearray(hashlib.md5(f"OfflinePlayer:{name}".encode(), usedforsecurity=False).digest())
    digest[6] = (digest[6] & 0x0F) | 0x30
    digest[8] = (digest[8] & 0x3F) | 0x80
    return str(uuid.UUID(bytes=bytes(digest)))


def lookup(cfg, name):
    """The name as Mojang spells it and its UUID, or the offline ones."""
    if properties.read(servers.props_file(cfg)).get("online-mode", "true") != "true":
        return name, offline_uuid(name)
    url = f"https://api.mojang.com/users/profiles/minecraft/{name}"
    try:
        with urllib.request.urlopen(url, timeout=10) as res:
            found = json.load(res)
    except urllib.error.HTTPError as e:
        if e.code in (204, 404):
            raise servers.ServerError(f"Mojang has no player called {name}") from e
        raise servers.ServerError(f"Couldn't reach Mojang: {e}") from e
    except (OSError, ValueError) as e:
        raise servers.ServerError(f"Couldn't reach Mojang: {e}") from e
    return found["name"], str(uuid.UUID(found["id"]))


def set_listed(cfg, which, name, on):
    """Add or remove a player. Returns whether it went through a command, where the
    server writes the file a moment later."""
    if which not in ON or not servers.PLAYER.match(name or ""):
        raise servers.ServerError(f"{name} isn't a valid player name")
    status = servers.status_of(cfg)
    if status["active"]:
        if status["state"] == "outside":
            raise servers.ServerError("This server is running outside Omni Server")
        servers.send(cfg, (ON if on else OFF)[which].format(name=name))
        return True
    entries = read_list(cfg, which)
    kept = [e for e in entries if e.get("name", "").lower() != name.lower()]
    if on:
        real, player_id = lookup(cfg, name)
        entry = {"uuid": player_id, "name": real}
        if which == "ops":
            level = properties.read(servers.props_file(cfg)).get("op-permission-level", "4")
            entry["level"] = int(level) if level.isdigit() else 4
        kept.append(entry)
    write_list(cfg, which, kept)
    return False


def set_whitelist_on(cfg, on):
    status = servers.status_of(cfg)
    if status["active"]:
        servers.send(cfg, f"whitelist {'on' if on else 'off'}")
        return True
    properties.write(servers.props_file(cfg), {"white-list": "true" if on else "false"})
    return False
