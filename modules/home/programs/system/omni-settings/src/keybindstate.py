"""The Keybinds page's data: the binds the last build gave niri (the copy
wm/niri/home/core/keybinds.nix writes), the keys DMS's own shortcut editor
sets, and a launch command for a picked window's app."""

import configparser
import json
import os
import re
import shlex

CONFIG = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")
APPLIED_FILE = os.path.join(CONFIG, "omni-settings", "niri-keybinds.json")
#--- DMS's Keyboard Shortcuts page writes here; niri reads it after the config's binds
DMS_BINDS = os.path.join(CONFIG, "niri", "dms", "binds.kdl")


def load_applied():
    """{binds, actions, overrides} from the last build, or None before one wrote it."""
    try:
        with open(APPLIED_FILE) as f:
            data = json.load(f)
    except (OSError, ValueError):
        return None
    return data if isinstance(data, dict) and isinstance(data.get("binds"), list) else None


def dms_keys():
    """The keys bound in DMS's binds.kdl: each node one level inside `binds { }`."""
    try:
        with open(DMS_BINDS) as f:
            text = f.read()
    except OSError:
        return []
    keys, depth, in_binds, i, n = [], 0, False, 0, len(text)
    while i < n:
        c = text[i]
        if c == '"':
            j = i + 1
            while j < n and text[j] != '"':
                j += 2 if text[j] == "\\" else 1
            i = j + 1
        elif text.startswith("//", i):
            j = text.find("\n", i)
            i = n if j < 0 else j
        elif c == "{":
            depth += 1
            i += 1
        elif c == "}":
            depth -= 1
            in_binds = in_binds and depth > 0
            i += 1
        elif c.isspace() or c == ";":
            i += 1
        else:
            m = re.compile(r"[^\s{};\"]+").match(text, i)
            word = m.group(0)
            at_node_start = text[text.rfind("\n", 0, i) + 1 : i].strip() == "" or text[i - 1] in "{;"
            if depth == 0 and word == "binds":
                in_binds = True
            elif in_binds and depth == 1 and at_node_start:
                keys.append(word)
            i = m.end()
    return keys


#--- Exec field codes (%U, %f…) a launcher fills in, dropped from a bind's command
FIELD_CODE = re.compile(r"^%[a-zA-Z]$")


def _desktop_entry(path):
    parser = configparser.RawConfigParser(strict=False, interpolation=None)
    parser.optionxform = str
    try:
        parser.read(path, encoding="utf-8")
        return dict(parser["Desktop Entry"]) if parser.has_section("Desktop Entry") else None
    except (configparser.Error, UnicodeDecodeError):
        return None


def launch_command(app_id):
    """The command a window's .desktop file runs, as a list: the file named after
    its app ID, or one whose StartupWMClass is the app ID. [] when none is found."""
    if not app_id:
        return []
    home = os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share")
    dirs = [home] + (os.environ.get("XDG_DATA_DIRS") or "/usr/local/share:/usr/share").split(":")
    found = None
    for d in dirs:
        folder = os.path.join(d, "applications")
        exact = os.path.join(folder, f"{app_id}.desktop")
        if os.path.isfile(exact):
            found = _desktop_entry(exact)
            break
        try:
            names = sorted(f for f in os.listdir(folder) if f.endswith(".desktop"))
        except OSError:
            continue
        for name in names:
            entry = _desktop_entry(os.path.join(folder, name))
            if entry and entry.get("StartupWMClass", "").lower() == app_id.lower():
                found = entry
                break
        if found:
            break
    if not found or not found.get("Exec"):
        return []
    try:
        words = shlex.split(found["Exec"])
    except ValueError:
        return []
    return [w for w in words if not FIELD_CODE.match(w)]
