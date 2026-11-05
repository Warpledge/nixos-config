"""Add-ons: data-only folders holding an `addon.json`, built in or imported, that give a
server panels, quick commands and a live backup command when its folder matches. The
format is in this app's CLAUDE.md. Nothing here runs code from an add-on."""

import glob
import json
import os
import re
import shutil
import tempfile

HOME = os.path.expanduser("~")
BUILT_IN = f"{os.path.dirname(os.path.abspath(__file__))}/addons"
LOCAL = os.environ.get("XDG_CONFIG_HOME", f"{HOME}/.config") + "/omni-server/addons"
ID = re.compile(r"^[a-z0-9][a-z0-9-]{0,63}$")
PLACEHOLDER = re.compile(r"\{(\w+)\}")
#--- A value fills one argument of a command, so none of these may hold a space
DIMENSION = re.compile(r"^[A-Za-z0-9_.:/-]{1,80}$")
TOKEN = re.compile(r"^\S{1,200}$")
INT = re.compile(r"^-?\d{1,9}$")
ROW_LIMIT = 200
READ_LIMIT = 1 << 20


class AddonError(Exception):
    pass


#--------------------------------------------------------------------#
#-- Checking a manifest
#--------------------------------------------------------------------#


def version_key(text):
    parts = str(text or "").split(".")
    return tuple(int(p) for p in parts) if all(p.isdigit() for p in parts) else None


def check_requires(where, requires, problems):
    if not isinstance(requires, dict):
        problems.append(f"{where} must be an object")
        return
    for key in ("jars", "files"):
        names = requires.get(key, [])
        if not isinstance(names, list) or not all(isinstance(n, str) for n in names):
            problems.append(f"{where}.{key} must be a list of names")
        elif any("/" in n or ".." in n for n in names):
            problems.append(f"{where}.{key} can't hold a path")
    limits = requires.get("minecraft", {})
    if not isinstance(limits, dict) or not all(version_key(v) for v in limits.values()):
        problems.append(f"{where}.minecraft must hold version numbers")


def check_form(where, panel, problems):
    fields = panel.get("fields", [])
    if not isinstance(fields, list):
        problems.append(f"{where}.fields must be a list")
        return
    known = set()
    for field in fields:
        if not isinstance(field, dict) or not re.fullmatch(r"\w+", str(field.get("id", ""))):
            problems.append(f"{where} has a field without a plain id")
            continue
        known.add(field["id"])
        if field.get("type") not in ("int", "choice", "dimension", "text"):
            problems.append(f"{where}.{field['id']} has an unknown type")
        if field.get("type") == "choice" and not field.get("options"):
            problems.append(f"{where}.{field['id']} needs options")
    actions = panel.get("actions", [])
    if not isinstance(actions, list) or not actions:
        problems.append(f"{where} needs actions")
        return
    for action in actions:
        command = action.get("command") if isinstance(action, dict) else None
        if not isinstance(command, str) or not command.strip() or not action.get("label"):
            problems.append(f"{where} has an action without a label and command")
        elif unknown := set(PLACEHOLDER.findall(command)) - known:
            problems.append(f"{where} uses unknown fields: {sorted(unknown)}")


def check_table(where, panel, problems):
    if not isinstance(panel.get("command"), str) or not panel["command"].strip():
        problems.append(f"{where} needs a command")
    try:
        rows = re.compile(str(panel.get("rows", "")))
    except re.error as e:
        problems.append(f"{where}.rows doesn't compile: {e}")
        return
    columns = panel.get("columns", [])
    if not rows.groupindex or not isinstance(columns, list) or not columns:
        problems.append(f"{where} needs named groups in rows, and columns")
    elif any(c.get("key") not in rows.groupindex for c in columns if isinstance(c, dict)):
        problems.append(f"{where} has a column that rows doesn't capture")


def problems_in(manifest):
    if not isinstance(manifest, dict):
        return ["addon.json must be an object"]
    problems = []
    if not ID.match(str(manifest.get("id", ""))):
        problems.append("id must be lower-case letters, digits and dashes")
    if not manifest.get("name"):
        problems.append("name is missing")
    match = manifest.get("match")
    check_requires("match", match, problems)
    if isinstance(match, dict) and not (match.get("jars") or match.get("files")):
        problems.append("match needs jars or files")
    for suggestion in manifest.get("suggests", []):
        if not str(suggestion.get("url", "")).startswith("https://"):
            problems.append("a suggested mod's url must start with https://")
    ids = set()
    for panel in manifest.get("panels", []):
        where = f"panel {panel.get('id')}"
        if not re.fullmatch(r"[\w-]+", str(panel.get("id", ""))) or panel["id"] in ids:
            problems.append(f"{where} needs a unique plain id")
        ids.add(panel.get("id"))
        check_requires(f"{where}.requires", panel.get("requires", {}), problems)
        if panel.get("type") == "form":
            check_form(where, panel, problems)
        elif panel.get("type") == "table":
            check_table(where, panel, problems)
        else:
            problems.append(f"{where} has an unknown type")
    for item in manifest.get("quickCommands", []):
        steps = item.get("steps") if isinstance(item, dict) else None
        if not item.get("name") or not steps or not all(s.get("command") for s in steps):
            problems.append("a quick command needs a name and steps")
    if "backup" in manifest and not str(manifest["backup"].get("command", "")).strip():
        problems.append("backup needs a command")
    for setting in manifest.get("settings", []):
        if not setting.get("key") or "value" not in setting:
            problems.append("a recommended setting needs a key and a value")
    return problems


#--------------------------------------------------------------------#
#-- Finding add-ons
#--------------------------------------------------------------------#


def read(folder):
    """A folder's manifest, or a stand-in carrying what's wrong with it."""
    name = os.path.basename(folder.rstrip("/"))
    try:
        with open(f"{folder}/addon.json", encoding="utf-8") as f:
            manifest = json.loads(f.read(READ_LIMIT))
    except (OSError, ValueError) as e:
        return {"id": name, "name": name, "problems": [f"Can't read addon.json: {e}"]}
    try:
        problems = problems_in(manifest)
    except (AttributeError, TypeError, KeyError) as e:
        problems = [f"addon.json has the wrong shape: {e}"]
    if problems:
        return {"id": name, "name": str(manifest.get("name", name)) if isinstance(manifest, dict) else name,
                "problems": problems}
    return manifest


def available():
    """Every add-on; an imported one replaces a built-in with the same id."""
    found = {}
    for root, local in ((BUILT_IN, False), (LOCAL, True)):
        for folder in sorted(glob.glob(f"{root}/*/")):
            manifest = read(folder)
            found[manifest["id"]] = {**manifest, "local": local}
    return sorted(found.values(), key=lambda a: a["name"].lower())


def find(addon_id):
    for addon in available():
        if addon["id"] == addon_id and not addon.get("problems"):
            return addon
    raise AddonError(f"No add-on called {addon_id}")


def commands_of(manifest):
    """Everything an add-on can send, for the import preview."""
    found = []
    for panel in manifest.get("panels", []):
        found += [a["command"] for a in panel.get("actions", [])]
        found += [panel[k] for k in ("status", "command") if panel.get(k)]
    for item in manifest.get("quickCommands", []):
        found += [s["command"] for s in item["steps"]]
    if manifest.get("backup"):
        found.append(manifest["backup"]["command"])
    return list(dict.fromkeys(found))


def import_folder(folder):
    """Only addon.json is copied: an add-on holds nothing else that this app reads."""
    manifest = read(folder)
    if manifest.get("problems"):
        raise AddonError("; ".join(manifest["problems"]))
    target = f"{LOCAL}/{manifest['id']}"
    os.makedirs(target, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=target, prefix=".tmp")
    os.close(fd)
    shutil.copyfile(f"{folder}/addon.json", tmp)
    os.replace(tmp, f"{target}/addon.json")
    return manifest


#--------------------------------------------------------------------#
#-- Matching a server's folder
#--------------------------------------------------------------------#


def has_jar(folder, pattern):
    return bool(glob.glob(f"{glob.escape(folder)}/mods/{pattern}")
                or glob.glob(f"{glob.escape(folder)}/mods/*/{pattern}"))


def unmet(requires, folder, minecraft):
    """What a server lacks for `requires`, in words; empty when it's satisfied."""
    needs = []
    limits = (requires or {}).get("minecraft", {})
    have = version_key(minecraft)
    if limits.get("min") and (not have or have < version_key(limits["min"])):
        needs.append(f"Minecraft {limits['min']} or later")
    if limits.get("max") and (not have or have > version_key(limits["max"])):
        needs.append(f"Minecraft {limits['max']} or earlier")
    for name in (requires or {}).get("files", []):
        if not os.path.exists(f"{folder}/{name}"):
            needs.append(name)
    for pattern in (requires or {}).get("jars", []):
        if not has_jar(folder, pattern):
            needs.append(f"mods/{pattern}")
    return needs


def matches(addon, cfg):
    return not addon.get("problems") and not unmet(addon["match"], cfg["dir"], cfg.get("minecraft"))


def enabled(cfg):
    """A switched-on add-on stops counting when its mod or file leaves the folder."""
    return [a for a in available() if a["id"] in cfg.get("addons", []) and matches(a, cfg)]


def live_backup(cfg):
    """The command that backs up a running server, from the first add-on offering one."""
    for addon in enabled(cfg):
        backup = addon.get("backup")
        if backup and not unmet(backup.get("requires"), cfg["dir"], cfg.get("minecraft")):
            return backup
    return None


def detected(folder):
    """A built-in add-on's launch details for this folder. Imported ones don't get this:
    a launch target can load code into the JVM."""
    for root in sorted(glob.glob(f"{BUILT_IN}/*/")):
        block = read(root).get("detect")
        if block and all(os.path.exists(f"{folder}/{name}") for name in block["files"]):
            return {k: block[k] for k in ("kind", "label", "java", "launch", "tps", "minecraft")}
    return None


#--------------------------------------------------------------------#
#-- Switching and using one
#--------------------------------------------------------------------#


def switch(cfg, addon, on):
    """Quick commands are copied in, tagged, so the person can edit them like any other."""
    ids = [i for i in cfg.get("addons", []) if i != addon["id"]]
    quick = cfg.get("quick", [])
    if on:
        ids.append(addon["id"])
        names = {q["name"] for q in quick}
        quick = quick + [{"icon": "bolt", "pinned": False, "confirm": False, **item, "addon": addon["id"]}
                         for item in addon.get("quickCommands", []) if item["name"] not in names]
    else:
        quick = [q for q in quick if q.get("addon") != addon["id"]]
    cfg.update(addons=ids, quick=quick)


def panel_of(cfg, addon_id, panel_id):
    for addon in enabled(cfg):
        if addon["id"] == addon_id:
            for panel in addon.get("panels", []):
                if panel["id"] == panel_id:
                    return panel
    raise AddonError("That add-on or panel isn't on for this server")


def check_value(field, value):
    value = str(value).strip()
    label = field.get("label", field["id"])
    kind = field["type"]
    if kind == "int":
        if not INT.match(value):
            raise AddonError(f"{label} must be a whole number")
        low, high = field.get("min"), field.get("max")
        if (low is not None and int(value) < low) or (high is not None and int(value) > high):
            raise AddonError(f"{label} must be between {low} and {high}")
    elif kind == "choice" and value not in [str(o) for o in field["options"]]:
        raise AddonError(f"{label} isn't one of the choices")
    elif kind == "dimension" and not DIMENSION.match(value):
        raise AddonError(f"{label} must be a dimension id, with no spaces")
    elif kind == "text" and not TOKEN.match(value):
        raise AddonError(f"{label} must be one word")
    return value


def filled_command(panel, action_label, values):
    for action in panel.get("actions", []):
        if action["label"] == action_label:
            checked = {f["id"]: check_value(f, values.get(f["id"], f.get("default", "")))
                       for f in panel.get("fields", []) if "{" + f["id"] + "}" in action["command"]}
            return PLACEHOLDER.sub(lambda m: checked[m[1]], action["command"])
    raise AddonError(f"No action called {action_label}")


def parse_rows(panel, text):
    """A table panel's rows, largest `sort` column first. Its reply may have no line
    breaks, so `rows` is run across the whole text."""
    rows = [m.groupdict() for m in re.finditer(panel["rows"], text)]
    key = panel.get("sort")
    if key:
        rows.sort(key=lambda r: -int(r[key]) if str(r[key]).lstrip("-").isdigit() else 0)
    return rows[:ROW_LIMIT]
