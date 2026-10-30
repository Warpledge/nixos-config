"""The Gaming tab's Games page: Steam's installed games, the launch options
and Proton build Steam holds for each now, and the compatibility tools a game
can be set to. The user's own choices are their steamGames setting, which
steam-games-apply (nixos/gaming/steam-games-apply.py) writes into Steam."""

import glob
import os
import re

import protonstate

STEAM = protonstate.STEAM
STEAM_PATH = ("software", "valve", "steam")
TOKEN = re.compile(r'"((?:\\.|[^"\\])*)"|([{}])')
COMPAT_NAME = re.compile(r'"compat_tools"\s*\{\s*"([^"]+)"')
#--- Installs that aren't games but ship no toolmanifest.vdf (Steamworks Common Redistributables)
NOT_GAMES = {"228980"}


def parse(text):
    """Steam's text VDF as nested dicts, keys lower-cased as Steam reads them."""
    root, stack, key = {}, [], None
    node = root
    for m in TOKEN.finditer(text):
        if m.group(2) == "{":
            child = node.setdefault((key or "").lower(), {})
            stack.append(node)
            node, key = child, None
        elif m.group(2) == "}":
            node, key = (stack.pop() if stack else root), None
        elif key is None:
            key = m.group(1).replace('\\"', '"').replace("\\\\", "\\")
        else:
            node[key.lower()] = m.group(1).replace('\\"', '"').replace("\\\\", "\\")
            key = None
    return root


def read(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            return parse(f.read())
    except OSError:
        return {}


def walk(node, *path):
    for key in path:
        node = node.get(key, {}) if isinstance(node, dict) else {}
    return node


def libraries():
    """Each Steam library's steamapps folder, Steam's own first."""
    out = [os.path.join(STEAM, "steamapps")]
    folders = walk(read(os.path.join(STEAM, "steamapps", "libraryfolders.vdf")), "libraryfolders")
    for entry in folders.values():
        path = entry.get("path") if isinstance(entry, dict) else None
        if path and os.path.realpath(os.path.join(path, "steamapps")) not in map(os.path.realpath, out):
            out.append(os.path.join(path, "steamapps"))
    return [p for p in out if os.path.isdir(p)]


def games():
    """[{id, name, dir}] for each installed game, by name; Proton, the runtimes
    and redistributables ship a toolmanifest.vdf and are left out."""
    out = {}
    for lib in libraries():
        for manifest in glob.glob(os.path.join(lib, "appmanifest_*.acf")):
            state = walk(read(manifest), "appstate")
            app, name, folder = state.get("appid"), state.get("name"), state.get("installdir")
            if not (app and name and folder) or app in out or app in NOT_GAMES:
                continue
            path = os.path.join(lib, "common", folder)
            if os.path.exists(os.path.join(path, "toolmanifest.vdf")):
                continue
            out[app] = {"id": app, "name": name, "dir": path}
    return sorted(out.values(), key=lambda g: g["name"].lower())


def icon(app):
    """A picture of the game from Steam's library cache, or ""."""
    folder = os.path.join(STEAM, "appcache", "librarycache", app)
    # Newer Steam keeps each picture in a hashed subfolder
    for name in ("header.jpg", "library_header.jpg", "library_600x900.jpg", "library_capsule.jpg",
                 "logo.png"):
        found = glob.glob(os.path.join(folder, name)) or glob.glob(os.path.join(folder, "*", name))
        if found:
            return found[0]
    flat = os.path.join(STEAM, "appcache", "librarycache", f"{app}_header.jpg")
    return flat if os.path.exists(flat) else ""


def current():
    """{app: {launchOptions, proton}} as Steam holds them now: launch options
    from every account's localconfig.vdf, the first one set winning."""
    out = {}
    for path in glob.glob(os.path.join(STEAM, "userdata", "*", "config", "localconfig.vdf")):
        apps = walk(read(path), "userlocalconfigstore", *STEAM_PATH, "apps")
        for app, entry in apps.items():
            if isinstance(entry, dict) and entry.get("launchoptions"):
                out.setdefault(app, {}).setdefault("launchOptions", entry["launchoptions"])
    mapping = walk(read(os.path.join(STEAM, "config", "config.vdf")),
                   "installconfigstore", *STEAM_PATH, "compattoolmapping")
    for app, entry in mapping.items():
        if app != "0" and isinstance(entry, dict) and entry.get("name"):
            out.setdefault(app, {})["proton"] = entry["name"]
    return out


def valve_name(title):
    """Steam's internal name for one of Valve's Proton installs: Proton 9.0 is
    proton_9, Proton 5.13 proton_513."""
    if title == "Proton Experimental" or title == "Proton - Experimental":
        return "proton_experimental"
    if title == "Proton Hotfix":
        return "proton_hotfix"
    m = re.fullmatch(r"Proton (\d+)\.(\d+)", title)
    if not m:
        return None
    return f"proton_{m.group(1)}" if m.group(2) == "0" else f"proton_{m.group(1)}{m.group(2)}"


def tools():
    """[{name, title}] for each build Steam can run a game with: name is what
    CompatToolMapping holds, title what Steam shows."""
    out, seen = [], set()
    folders = [os.path.join(os.path.expanduser("~"), ".steam", "root", "compatibilitytools.d"),
               os.path.join(STEAM, "compatibilitytools.d")]
    folders += [p for p in os.environ.get("STEAM_EXTRA_COMPAT_TOOLS_PATHS", "").split(":") if p]
    for folder in folders:
        for vdf in glob.glob(os.path.join(folder, "*", "compatibilitytool.vdf")):
            try:
                with open(vdf, errors="replace") as f:
                    text = f.read()
            except OSError:
                continue
            m = COMPAT_NAME.search(text)
            if m and m.group(1) not in seen:
                seen.add(m.group(1))
                out.append({"name": m.group(1),
                            "title": protonstate.display_name(os.path.dirname(vdf)) or m.group(1)})
    for lib in libraries():
        for manifest in glob.glob(os.path.join(lib, "appmanifest_*.acf")):
            title = walk(read(manifest), "appstate").get("name", "")
            name = valve_name(title)
            if name and name not in seen:
                seen.add(name)
                out.append({"name": name, "title": title})
    # Numbers compared as numbers, so Proton 11.0 sorts above 10.0
    return sorted(out, key=lambda t: [int(p) if p.isdigit() else p
                                      for p in re.split(r"(\d+)", t["title"].lower())], reverse=True)


#--------------------------------------------------------------------#
#-- For the QML Front End
#--------------------------------------------------------------------#
def page():
    """The Games page: the games with their icon and Steam's values, the builds,
    the default build and the builder's option groups."""
    now = current()
    return {"games": [dict(g, icon=icon(g["id"]), steam=now.get(g["id"], {})) for g in games()],
            "tools": tools(), "default": protonstate.steam_default() or "",
            "groups": protonstate.builder_groups()}
