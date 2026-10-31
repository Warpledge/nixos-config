"""The Launch Options page's upscaling picker: a window picked in niri, the game
behind it, its engine and size, and the nix-vn or nix-rpgm launch option for it
(the vn-setup and rpgm-setup skills' steps)."""

import configparser
import glob
import json
import os
import re

import protonstate
import steamstate
import windowrulestate

#--- Wine's window frame: a few px wider and up to ~40 px taller than the game
FRAME_W, FRAME_H = 12, 40
COMMON = re.compile(r"(.*/steamapps/common/[^/]+)")


def _read(path):
    try:
        with open(path, "rb") as f:
            return f.read()
    except OSError:
        return b""


def _argv(pid):
    return [a.decode(errors="replace") for a in _read(f"/proc/{pid}/cmdline").split(b"\0") if a]


def _environ(pid):
    pairs = (e.decode(errors="replace").partition("=") for e in _read(f"/proc/{pid}/environ").split(b"\0"))
    return {k: v for k, _, v in pairs if k}


def _exe_name(arg):
    return re.split(r"[\\/]", arg)[-1].lower()


#--------------------------------------------------------------------#
#-- The game's process and folder
#--------------------------------------------------------------------#
def game_pid(window):
    """The game's own process. X11 windows (Proton's) come through
    xwayland-satellite, so niri's pid is the satellite's: find the process by
    the window's app id, the exe's name in lower case."""
    pid, app = window.get("pid"), (window.get("app_id") or "").lower()
    if pid and "xwayland" not in _read(f"/proc/{pid}/comm").decode(errors="replace"):
        return pid
    found = []
    for path in glob.glob("/proc/[0-9]*/cmdline"):
        p = int(path.split("/")[2])
        argv = _argv(p)
        if argv and app and _exe_name(argv[0]) in (app, app + ".exe"):
            found.append(p)
    return max(found) if found else None  # the newest, when a launcher shares the name


def windows_path(pid, path):
    """A Wine path as a Linux one: Z: is /, other drives through the prefix."""
    m = re.match(r"^([A-Za-z]):[\\/](.*)$", path)
    if not m:
        return path
    rest = m.group(2).replace("\\", "/")
    if m.group(1).lower() == "z":
        return "/" + rest
    prefix = _environ(pid).get("WINEPREFIX") or os.path.join(_environ(pid).get("STEAM_COMPAT_DATA_PATH", ""), "pfx")
    return os.path.join(os.path.realpath(os.path.join(prefix, "dosdevices", m.group(1).lower() + ":")), rest)


def game_dir(pid):
    """The folder holding the game's exe, else the process's working folder."""
    argv = _argv(pid)
    if argv:
        exe = windows_path(pid, argv[0])
        if os.path.isfile(exe):
            return os.path.dirname(exe)
    try:
        return os.readlink(f"/proc/{pid}/cwd")
    except OSError:
        return ""


#--------------------------------------------------------------------#
#-- Engine
#--------------------------------------------------------------------#
def _ini_library(folder):
    for name in ("Game.ini", "game.ini"):
        text = _read(os.path.join(folder, name)).decode(errors="replace")
        m = re.search(r"^\s*Library\s*=\s*(\S+)", text, re.M | re.I)
        if m:
            return m.group(1).upper()
    return ""


def _mv_window(folder):
    for name in ("package.json", "www/package.json"):
        try:
            win = json.loads(_read(os.path.join(folder, name)) or b"null")["window"]
            return int(win["width"]), int(win["height"])
        except (ValueError, KeyError, TypeError):
            continue
    return None


def engine(folder):
    """{name, rpgm, size: (w, h) or None, note}: the rpgm-setup skill's table."""
    has = lambda *pats: any(glob.glob(os.path.join(folder, p)) for p in pats)  # noqa: E731
    lib = _ini_library(folder)
    if has("RPG_RT.exe", "*.lmu"):
        return {"name": "RPG Maker 2000/2003", "rpgm": True, "size": (320, 240),
                "note": "EasyRPG (gaming.easyrpg) runs these natively and scales them itself."}
    if lib.startswith("RGSS1") or has("Data/*.rxdata"):
        return {"name": "RPG Maker XP", "rpgm": True, "size": (640, 480), "note": ""}
    if lib.startswith("RGSS2") or has("Data/*.rvdata"):
        return {"name": "RPG Maker VX", "rpgm": True, "size": (544, 416), "note": ""}
    if lib.startswith("RGSS3") or has("Data/*.rvdata2", "Game.rgss3a"):
        return {"name": "RPG Maker VX Ace", "rpgm": True, "size": (544, 416), "note": ""}
    if has("js/rmmz_core.js", "www/js/rmmz_core.js", "js/rpg_core.js", "www/js/rpg_core.js"):
        mz = has("js/rmmz_core.js", "www/js/rmmz_core.js")
        return {"name": "RPG Maker MZ" if mz else "RPG Maker MV", "rpgm": True,
                "size": _mv_window(folder) or (816, 624), "note": ""}
    if has("Data.wolf", "data.dts", "Data/*.wolf"):
        return {"name": "WOLF RPG Editor", "rpgm": False, "size": None, "note": ""}
    if has("nscript.dat", "*.nsa"):
        return {"name": "NScripter", "rpgm": False, "size": (800, 600), "note": ""}
    if has("System40.ini"):
        ini = configparser.ConfigParser(strict=False)
        try:
            ini.read_string("[s]\n" + _read(os.path.join(folder, "System40.ini")).decode(errors="replace"))
            width = ini.get("s", "ViewWidth", fallback="")
        except configparser.Error:
            width = ""
        return {"name": "System 4", "rpgm": False, "size": None,
                "note": "System 4 games run on xsystem4 instead: nix-vn-<size> xsystem4 \"<game folder>\" "
                        f"# %command%{f', sized from ViewWidth {width}' if width else ''}."}
    if has("renpy", "*.rpa"):
        return {"name": "Ren'Py", "rpgm": False, "size": None,
                "note": "A native Linux Ren'Py build renders at the window's size and gains nothing here."}
    return {"name": "", "rpgm": False, "size": None, "note": ""}


#--------------------------------------------------------------------#
#-- The launch option
#--------------------------------------------------------------------#
def fits(measured, size):
    """Whether a window measured with Wine's frame holds a game of `size`."""
    (mw, mh), (w, h) = measured, size
    return w <= mw <= w + FRAME_W and h <= mh <= h + FRAME_H


def preset_for(command, size, measured):
    """The `command`-<suffix> preset for `size`, else one the measured window fits."""
    presets = [(n, tuple(int(x) for x in r.split("x"))) for n, r in protonstate.presets(command)]
    if size:
        exact = next((n for n, s in presets if s == size), None)
        if exact:
            return exact
    return next((n for n, s in presets if measured and fits(measured, s)), None)


def suggest(eng, measured, fullscreen):
    """(wrapper, why) for the engine and the measured window."""
    if eng["rpgm"]:
        fitted = preset_for("nix-rpgm", None, measured)
        default = preset_for("nix-rpgm", eng["size"], None)
        if fitted and fitted != default and not fullscreen:
            return fitted, "Matches the window, which the game resized from the engine's own size."
        return "nix-rpgm", f"Reads the size from the engine ({eng['size'][0]}x{eng['size'][1]})."
    if fullscreen:
        return None, ""
    preset = preset_for("nix-vn", eng["size"], measured)
    if preset:
        return preset, "Matches the game's own resolution."
    if eng["size"]:
        w, h = eng["size"]
    else:
        w, h = measured
    return f"nix-vn -r {w}x{h}", "No preset fits, so the size is given; it may include Wine's frame."


def steam_game(folder):
    m = COMMON.match(folder or "")
    if not m:
        return None
    game = next((g for g in steamstate.games() if os.path.realpath(g["dir"]) == os.path.realpath(m.group(1))), None)
    if not game:
        return None
    current = steamstate.current().get(game["id"], {})
    return {"id": game["id"], "name": game["name"], "launch": current.get("launchOptions", "")}


def pick():
    """A window picked in niri and what to run it with; None when the pick was cancelled."""
    window = windowrulestate.niri(["pick-window"])
    if not isinstance(window, dict):
        return None
    app = window.get("app_id") or ""
    size = (window.get("layout") or {}).get("window_size") or [0, 0]
    measured = (int(size[0]), int(size[1]))
    out = {"title": window.get("title") or app, "appId": app, "size": f"{measured[0]}x{measured[1]}",
           "dir": "", "engine": "", "note": "", "alert": "", "wrapper": "", "why": "", "steam": None}
    if "gamescope" in app.lower():
        out["alert"] = "That's gamescope's window: the game already runs in it. Pick the game without it."
        return out
    pid = game_pid(window)
    folder = game_dir(pid) if pid else ""
    eng = engine(folder) if folder else {"name": "", "rpgm": False, "size": None, "note": ""}
    outputs = windowrulestate.niri(["outputs"]) or {}
    screens = [(o["logical"]["width"], o["logical"]["height"])
               for o in (outputs.values() if isinstance(outputs, dict) else outputs) if o.get("logical")]
    fullscreen = any(measured[0] >= w and measured[1] >= h - FRAME_H for w, h in screens)
    wrapper, why = suggest(eng, measured, fullscreen)
    out.update(dir=folder, engine=eng["name"], note=eng["note"], wrapper=wrapper or "", why=why,
               steam=steam_game(folder))
    if not wrapper:
        out["alert"] = ("The window fills the screen, so its own size can't be read. Switch the game to "
                        "windowed (Alt+Enter or its settings) and pick it again.")
    elif not folder:
        out["note"] = out["note"] or "Couldn't find the game's folder, so the size comes from the window."
    return out
