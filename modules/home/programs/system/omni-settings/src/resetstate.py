"""Reset buttons on the app switches: put each setting the config declares
back to the value it last wrote, leaving every other setting in the app's file
as it is. Only apps whose config file stays writable are listed; the rest are
store links a rebuild already puts back."""

import json
import os
import shutil
import subprocess

HOME = os.path.expanduser("~")

#--- App switches with a reset (SettingRow.qml): user setting -> (app, its live file,
#--- the config's copy, pgrep -f pattern of a running app that rewrites the file
#--- on exit, extra warning). .db files are NeDB logs (one {"_id", "value"} per
#--- line), the rest JSON
APPS = {
    ("editors", "zed"): ("Zed", ".config/zed/settings.json",
                         ".config/zed/declarative-settings.json", None, ""),
    ("fileBrowsers", "duxFiles"): ("Dux Files", ".config/dfiles/ui-settings.json",
                                   ".local/state/dfiles-declared/ui-settings.json", None, ""),
    ("media", "freetube"): ("FreeTube", ".config/FreeTube/settings.db", ".config/FreeTube/hm_settings.db",
                            "freetube/resources/app.asar",
                            " Channels blocked in FreeTube but not yet synced to the config are "
                            "unblocked too."),
}


def available(path):
    """APPS' entry for user setting `path`, when the config wrote its copy for this user."""
    entry = APPS.get(path)
    return entry if entry and os.path.isfile(os.path.join(HOME, entry[2])) else None


def reset(path):
    """Resets the app of user setting `path`, keeping the old file as .old;
    ValueError with what to tell the user when it can't."""
    app, live, declared, running, _ = APPS[path]
    if running and subprocess.run(["pgrep", "-f", running], capture_output=True).returncode == 0:
        raise ValueError(f"Close {app} first; it rewrites its settings when it quits")
    live = os.path.join(HOME, live)
    try:
        text = reset_text(live, os.path.join(HOME, declared))
        if os.path.isfile(live):
            shutil.copyfile(live, live + ".old")
        with open(live, "w") as f:
            f.write(text)
    except OSError as e:
        raise ValueError(f"Couldn't reset {app}: {e.strerror}") from e
    except ValueError as e:
        raise ValueError(f"Couldn't reset {app}: its settings file isn't plain JSON") from e


def reset_text(live, declared):
    """The live file's text with the declared values put back."""
    with open(declared) as f:
        want = f.read()
    try:
        with open(live) as f:
            have = f.read()
    except FileNotFoundError:
        return want
    if live.endswith(".db"):
        return _reset_nedb(have, want)
    data = json.loads(have) if have.strip() else {}
    for path, value in _leaves(json.loads(want)):
        node = data
        for key in path[:-1]:
            if not isinstance(node.get(key), dict):
                node[key] = {}
            node = node[key]
        node[path[-1]] = value
    return json.dumps(data, indent=2) + "\n"


def _leaves(obj, path=()):
    """(key path, value) for each leaf; arrays and empty objects count as one,
    as in lib/mutable-merge.jq."""
    if isinstance(obj, dict) and obj:
        for key, value in obj.items():
            yield from _leaves(value, path + (key,))
    elif path:
        yield path, obj


def _reset_nedb(have, want):
    """Folds the log (a later line with the same _id wins), sets the declared
    _ids and writes one line per setting."""
    docs = {}
    for text in (have, want):
        for line in text.splitlines():
            if not line.strip():
                continue
            doc = json.loads(line)
            if doc.get("$$deleted"):
                docs.pop(doc.get("_id"), None)
            elif "_id" in doc:
                docs[doc["_id"]] = doc
    return "".join(json.dumps(d, separators=(",", ":"), ensure_ascii=False) + "\n" for d in docs.values())
