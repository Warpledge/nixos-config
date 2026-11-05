"""server.properties: read and edited in place, so order, comments and keys this
app doesn't know stay as they were. The GUI's form comes from SCHEMA; a key not
in it shows as plain text. Java's escaping (`motd=GT\\:New Horizons`) is undone
on read and redone on write."""

import os
import re
import tempfile

KEY_VALUE = re.compile(r"^\s*([^#!\s=:][^=:\s]*)\s*[=:]\s?(.*)$")

#--- key -> kind, group, label; `choices` is value -> label. rcon.* isn't shown: the
#--- Live stats switch manages it
SCHEMA = {
    "difficulty": {"kind": "choice", "group": "Gameplay", "label": "Difficulty", "choices": {
        "0": "Peaceful", "1": "Easy", "2": "Normal", "3": "Hard",
        "peaceful": "Peaceful", "easy": "Easy", "normal": "Normal", "hard": "Hard"}},
    "gamemode": {"kind": "choice", "group": "Gameplay", "label": "Game mode", "choices": {
        "0": "Survival", "1": "Creative", "2": "Adventure", "3": "Spectator",
        "survival": "Survival", "creative": "Creative", "adventure": "Adventure",
        "spectator": "Spectator"}},
    "force-gamemode": {"kind": "bool", "group": "Gameplay", "label": "Force game mode"},
    "hardcore": {"kind": "bool", "group": "Gameplay", "label": "Hardcore"},
    "pvp": {"kind": "bool", "group": "Gameplay", "label": "PvP"},
    "allow-flight": {"kind": "bool", "group": "Gameplay", "label": "Allow flight"},
    "spawn-animals": {"kind": "bool", "group": "Gameplay", "label": "Spawn animals"},
    "spawn-monsters": {"kind": "bool", "group": "Gameplay", "label": "Spawn monsters"},
    "spawn-npcs": {"kind": "bool", "group": "Gameplay", "label": "Spawn villagers"},
    "spawn-protection": {"kind": "int", "group": "Gameplay", "label": "Spawn protection radius"},
    "enable-command-block": {"kind": "bool", "group": "Gameplay", "label": "Command blocks"},
    "announce-player-achievements": {
        "kind": "bool", "group": "Gameplay", "label": "Announce achievements"},

    "level-name": {"kind": "text", "group": "World", "label": "World folder"},
    "level-seed": {"kind": "text", "group": "World", "label": "Seed"},
    "level-type": {"kind": "text", "group": "World", "label": "World type"},
    "generator-settings": {"kind": "text", "group": "World", "label": "Generator settings"},
    "generate-structures": {"kind": "bool", "group": "World", "label": "Generate structures"},
    "allow-nether": {"kind": "bool", "group": "World", "label": "Allow the Nether"},
    "max-build-height": {"kind": "int", "group": "World", "label": "Build height"},

    "motd": {"kind": "text", "group": "Server", "label": "Message of the day"},
    "max-players": {"kind": "int", "group": "Server", "label": "Max players"},
    "view-distance": {"kind": "int", "group": "Server", "label": "View distance"},
    "simulation-distance": {"kind": "int", "group": "Server", "label": "Simulation distance"},
    "max-tick-time": {"kind": "int", "group": "Server", "label": "Watchdog tick limit (ms)"},
    "player-idle-timeout": {"kind": "int", "group": "Server", "label": "Idle kick (minutes)"},
    "op-permission-level": {"kind": "int", "group": "Server", "label": "Op permission level"},

    "server-port": {"kind": "int", "group": "Network", "label": "Port"},
    "server-ip": {"kind": "text", "group": "Network", "label": "Bind address"},
    "online-mode": {"kind": "bool", "group": "Network", "label": "Online mode"},
    "enable-query": {"kind": "bool", "group": "Network", "label": "Query protocol"},
    "resource-pack": {"kind": "text", "group": "Network", "label": "Resource pack URL"},
    "snooper-enabled": {"kind": "bool", "group": "Network", "label": "Send usage data"},
}
GROUPS = ["Gameplay", "World", "Server", "Network", "Other"]
#--- Managed elsewhere: the whitelist on the Players page, RCON by Live stats
HIDDEN = re.compile(r"^(rcon\.|enable-rcon$|white-list$|enforce-whitelist$|broadcast-rcon)")


def unescape(text):
    return re.sub(r"\\(.)", lambda m: {"n": "\n", "t": "\t"}.get(m[1], m[1]), text)


def escape(text):
    out = text.replace("\\", "\\\\").replace("\n", "\\n").replace("\t", "\\t")
    return out.replace(":", "\\:").replace("=", "\\=")


def read(path):
    """{key: value}; empty when the server hasn't written the file yet."""
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            lines = f.read().splitlines()
    except OSError:
        return {}
    found = {}
    for line in lines:
        match = KEY_VALUE.match(line)
        if match:
            found[match[1]] = unescape(match[2])
    return found


def write(path, changes):
    """Set each key of `changes` where it is, adding new ones at the end."""
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            lines = f.read().splitlines()
    except FileNotFoundError:
        lines = []
    left = dict(changes)
    for i, line in enumerate(lines):
        match = KEY_VALUE.match(line)
        if match and match[1] in left:
            lines[i] = f"{match[1]}={escape(str(left.pop(match[1])))}"
    lines += [f"{key}={escape(str(value))}" for key, value in left.items()]
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), prefix=".server.properties.")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")
        if os.path.exists(path):
            os.chmod(tmp, os.stat(path).st_mode & 0o777)
        else:
            os.chmod(tmp, 0o600)
        os.replace(tmp, path)
    except OSError:
        os.unlink(tmp)
        raise


def form(values):
    """The Settings page's groups: [{title, rows: [{key, value, kind, label, choices}]}]."""
    rows = {g: [] for g in GROUPS}
    for key, value in values.items():
        if HIDDEN.match(key):
            continue
        spec = SCHEMA.get(key, {"kind": "text", "group": "Other", "label": key})
        row = {"key": key, "value": value, "kind": spec["kind"], "label": spec["label"]}
        if spec["kind"] == "choice":
            #--- 1.7.10 writes numbers, later versions words; offer this file's kind
            numeric = value.isdigit()
            row["choices"] = [{"value": v, "label": l} for v, l in spec["choices"].items()
                              if v.isdigit() == numeric]
        rows[spec["group"]].append(row)
    return [{"title": g, "rows": rows[g]} for g in GROUPS if rows[g]]


def check(key, value):
    """An error message for a value its kind can't hold, else None."""
    spec = SCHEMA.get(key)
    if "\n" in str(value):
        return f"{key} can't hold a line break"
    if HIDDEN.match(key):
        return f"{key} is managed elsewhere in the app"
    if not spec:
        return None
    if spec["kind"] == "bool" and str(value) not in ("true", "false"):
        return f"{spec['label']} must be true or false"
    if spec["kind"] == "int" and not re.fullmatch(r"-?\d+", str(value)):
        return f"{spec['label']} must be a whole number"
    if spec["kind"] == "choice" and str(value) not in spec["choices"]:
        return f"{spec['label']} doesn't have the choice {value}"
    return None
