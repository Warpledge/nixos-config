"""Writes the steamGames user setting into Steam's own files: LaunchOptions in
each account's localconfig.vdf and the Proton build in config.vdf's
CompatToolMapping. The setting arrives as $XDG_STATE_HOME/omni-settings/
steam-games.json (gaming/steam-games.nix); what was last written is kept in
steam-games-applied.json, so a game taken out of the setting is cleared only
where Steam still holds the value written here. Steam rewrites both files when
it exits, so nothing is written while it runs; steam.nix runs this again just
before Steam starts."""

import argparse
import glob
import json
import os
import shutil
import subprocess
import sys

import vdf

STEAM_PATH = ("Software", "Valve", "Steam")
NOTIFY_SEND = "@notifySend@"  # libnotify's, filled in by steam.nix


def state_dir():
    base = os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state")
    return os.path.join(base, "omni-settings")


def read_json(path):
    try:
        with open(path) as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def steam_running():
    """Whether this user's Steam client is up (its binary, not the FHS wrapper
    script, which is also called steam)."""
    uid = os.getuid()
    for pid in os.listdir("/proc"):
        if not pid.isdigit():
            continue
        try:
            if os.stat(f"/proc/{pid}").st_uid != uid:
                continue
            with open(f"/proc/{pid}/cmdline", "rb") as f:
                argv0 = f.read().split(b"\0", 1)[0]
        except OSError:
            continue
        if argv0.endswith((b"/ubuntu12_32/steam", b"/steamrt64/steam")):
            return True
    return False


def child(node, key, create=False):
    """`node`'s entry named `key`, ignoring case as Steam does."""
    for k in node:
        if k.lower() == key.lower():
            return node[k]
    if not create:
        return None
    node[key] = vdf.VDFDict()
    return node[key]


def walk(node, path, create=False):
    for key in path:
        node = child(node, key, create) if node is not None else None
    return node


def load(path):
    with open(path, encoding="utf-8", errors="replace") as f:
        return vdf.load(f, mapper=vdf.VDFDict)


def quote(text):
    # Steam keeps newlines raw inside strings
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def dump(node, depth=0):
    """Text in Steam's own layout (two tabs between key and value), which
    vdf.dump doesn't keep, so only the changed lines differ."""
    pad = "\t" * depth
    out = []
    for key, value in node.items():
        if isinstance(value, dict):
            out += [pad + quote(key), pad + "{", *dump(value, depth + 1), pad + "}"]
        else:
            out.append(pad + quote(key) + "\t\t" + quote(str(value)))
    return out


def save(path, data):
    if not os.path.exists(path + ".omni.bak"):
        shutil.copy2(path, path + ".omni.bak")
    tmp = path + ".omni.tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write("\n".join(dump(data)) + "\n")
    os.replace(tmp, path)


def set_field(apps, app, key, value, before):
    """Sets `apps[app][key]`; None clears it, but only while it still holds
    `before`, the value this script wrote last time."""
    entry = child(apps, app, create=value is not None)
    if entry is None:
        return False
    current = child(entry, key)
    if value is None:
        if current is None or current != before:
            return False
        for k in list(entry):
            if k.lower() == key.lower():
                del entry[k]
        return True
    if current == value:
        return False
    for k in list(entry):
        if k.lower() == key.lower():
            del entry[k]
    entry[key] = value
    return True


def apply(root, wanted, applied, write=True):
    """The app ids whose values in Steam's files differ from the setting,
    written unless `write` is off."""
    games = set(wanted) | set(applied)
    touched = set()
    for path in glob.glob(os.path.join(root, "userdata", "*", "config", "localconfig.vdf")):
        data = load(path)
        top = next(iter(data.values()), None)
        apps = walk(top, STEAM_PATH + ("apps",), create=True) if top is not None else None
        if apps is None:
            continue
        changed = False
        for app in sorted(games):
            value = wanted.get(app, {}).get("launchOptions")
            if set_field(apps, app, "LaunchOptions", value, applied.get(app, {}).get("launchOptions")):
                changed = True
                touched.add(app)
        if changed and write:
            save(path, data)

    path = os.path.join(root, "config", "config.vdf")
    if os.path.exists(path):
        data = load(path)
        top = next(iter(data.values()), None)
        mapping = walk(top, STEAM_PATH + ("CompatToolMapping",), create=True) if top is not None else None
        changed = False
        for app in sorted(games) if mapping is not None else ():
            build = wanted.get(app, {}).get("proton") or None
            before = applied.get(app, {}).get("proton")
            entry = child(mapping, app)
            if build is None:
                if entry is not None and before and child(entry, "name") == before:
                    del mapping[app]
                    changed = True
                    touched.add(app)
                continue
            if entry is not None and child(entry, "name") == build:
                continue
            if entry is not None:
                del mapping[app]
            mapping[app] = vdf.VDFDict([("name", build), ("config", ""), ("priority", "250")])
            changed = True
            touched.add(app)
        if changed and write:
            save(path, data)
    return touched


def game_names(root, apps):
    """Each app's name from its appmanifest in any library, else its id."""
    dirs = [os.path.join(root, "steamapps")]
    try:
        folders = load(os.path.join(root, "steamapps", "libraryfolders.vdf"))
        for entry in (next(iter(folders.values()), None) or {}).values():
            if isinstance(entry, dict) and child(entry, "path"):
                dirs.append(os.path.join(child(entry, "path"), "steamapps"))
    except (OSError, SyntaxError, ValueError):
        pass
    names = []
    for app in sorted(apps):
        name = app
        for d in dirs:
            try:
                state = load(os.path.join(d, f"appmanifest_{app}.acf"))
                name = child(next(iter(state.values())), "name") or app
                break
            except (OSError, SyntaxError, ValueError, StopIteration, AttributeError):
                continue
        names.append(name)
    return names


def notify(summary, body):
    """A desktop notification; nothing when there's no session bus to send it on."""
    try:
        subprocess.run([NOTIFY_SEND, "--app-name=Steam", "--icon=steam", summary, body],
                       stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=10)
    except (OSError, subprocess.TimeoutExpired):
        pass


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=os.path.expanduser("~/.local/share/Steam"),
                        help="Steam's folder (for testing on a copy)")
    parser.add_argument("--pending", action="store_true",
                        help="print the app ids Steam doesn't have yet as JSON; write nothing")
    parser.add_argument("--quiet", action="store_true", help="no notifications")
    args = parser.parse_args()
    state = state_dir()
    wanted = read_json(os.path.join(state, "steam-games.json"))
    applied_path = os.path.join(state, "steam-games-applied.json")
    applied = read_json(applied_path) or {}
    # Checked against Steam's files every time, not skipped when wanted == applied:
    # Steam rewrites localconfig.vdf on exit, undoing a write made while it ran
    if wanted is None or not os.path.isdir(args.root):
        if args.pending:
            print("[]")
        return 0
    root = os.path.realpath(args.root)
    if args.pending:
        print(json.dumps(sorted(apply(root, wanted, applied, write=False))))
        return 0
    if steam_running():
        waiting = apply(root, wanted, applied, write=False)
        if waiting:
            print("steam-games-apply: Steam is running; the changes are written when it next starts")
            if not args.quiet:
                notify("Waiting for Steam to restart",
                       f"{', '.join(game_names(root, waiting))}: quit Steam and start it again, or use "
                       "Restart Steam on Omni Settings' Games page, to set the launch options.")
        return 0
    written = apply(root, wanted, applied)
    if written and not args.quiet:
        notify("Launch options set in Steam", ", ".join(game_names(root, written)))
    tmp = applied_path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(wanted, f, indent=2, sort_keys=True)
    os.replace(tmp, applied_path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
