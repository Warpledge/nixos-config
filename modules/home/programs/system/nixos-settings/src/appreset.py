"""Reset buttons on the app switches: put each setting the config declares
back to the value it last wrote, leaving every other setting in the app's file
as it is. Only apps whose config file stays writable are listed; the rest are
store links a rebuild already puts back."""

import json
import os
import shutil
import subprocess

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gtk  # noqa: E402

HOME = os.path.expanduser("~")
#--- user setting -> (app, its live file, the config's copy, pgrep -f pattern
#--- of a running app that rewrites the file on exit, extra warning)
#--- .db files are NeDB logs (one {"_id", "value"} per line), the rest JSON
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


def button(window, setting):
    """A reset button for `setting`'s app, or None when it has none or isn't
    set up for this user."""
    entry = APPS.get(setting.path) if setting.domain == "user" else None
    if entry is None or not os.path.isfile(os.path.join(HOME, entry[2])):
        return None
    reset = Gtk.Button(icon_name="edit-clear-all-symbolic", css_classes=["flat"], valign=Gtk.Align.CENTER,
                       tooltip_text=f"Reset {entry[0]}'s settings to the config's")
    reset.connect("clicked", lambda _: _confirm(window, *entry))
    return reset


def _confirm(window, app, live, declared, running, extra):
    dialog = Adw.AlertDialog(heading=f"Reset {app} settings?",
                             body=f"Every setting the config sets for {app} goes back to the config's "
                                  f"value, losing what was changed in {app}; settings the config "
                                  f"leaves alone stay as they are. The old file is kept as "
                                  f"{os.path.basename(live)}.old." + extra)
    dialog.add_response("cancel", "Cancel")
    dialog.add_response("reset", "Reset")
    dialog.set_response_appearance("reset", Adw.ResponseAppearance.DESTRUCTIVE)
    dialog.set_default_response("cancel")
    dialog.set_close_response("cancel")

    def chosen(_, r):
        if r != "reset":
            return
        if running and subprocess.run(["pgrep", "-f", running], capture_output=True).returncode == 0:
            window.toast(f"Close {app} first; it rewrites its settings when it quits")
            return
        path = os.path.join(HOME, live)
        try:
            text = reset_text(path, os.path.join(HOME, declared))
            if os.path.isfile(path):
                shutil.copyfile(path, path + ".old")
            with open(path, "w") as f:
                f.write(text)
        except OSError as e:
            window.toast(f"Couldn't reset {app}: {e.strerror}")
            return
        except ValueError:
            window.toast(f"Couldn't reset {app}: its settings file isn't plain JSON")
            return
        window.toast(f"{app} settings reset")
    dialog.connect("response", chosen)
    dialog.present(window)


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
