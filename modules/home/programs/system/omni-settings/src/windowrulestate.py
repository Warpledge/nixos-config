"""The Window Rules page's GTK-free half, for both front ends: reading and
writing modules/wm/niri/home/core/window-rules.json, the copy of what niri got
that rules.nix writes to ~/.config/omni-settings/, and describing each rule."""

import configparser
import json
import os
import subprocess

RULES_FILE = os.path.join("modules", "wm", "niri", "home", "core", "window-rules.json")
APPLIED_FILE = os.path.join(os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config"),
                            "omni-settings", "niri-window-rules.json")

#--- Characters niri's (Rust) regex treats as special
SPECIAL = set("\\.+*?()|[]{}^$")

#--- (label, value) for the width and height choices; None is a pixel size
SIZES = [("One Third", {"proportion": 0.33333}), ("Half", {"proportion": 0.5}),
         ("Two Thirds", {"proportion": 0.66667}), ("Full", {"proportion": 1.0}),
         ("Pixels", None), ("The Window's Own", {})]

#--- (rule property, title, group, control, choices). Controls: "on" sets true,
#--- "choice" picks from the choices, "size", "opacity", "workspace", "output"
KINDS = [
    ("open-floating", "Open Floating", "Floating", "on", []),
    ("default-column-width", "Width", "Size & Position", "size", []),
    ("default-window-height", "Height", "Size & Position", "size", []),
    ("open-maximized", "Open Maximized", "Size & Position", "on", []),
    ("open-fullscreen", "Open Fullscreen", "Size & Position", "on", []),
    ("open-on-workspace", "Open on Workspace", "Placement", "workspace", []),
    ("open-on-output", "Open on Monitor", "Placement", "output", []),
    ("open-focused", "Focus When Opened", "Focus", "choice",
     [("Don't Focus", False), ("Always Focus", True)]),
    ("opacity", "Opacity", "Appearance", "opacity", []),
    ("block-out-from", "Hide From Screen Capture", "Privacy", "choice",
     [("Screenshots and Recording", "screen-capture"), ("Recording Only", "screencast")]),
    ("variable-refresh-rate", "Variable Refresh Rate", "Performance", "on", []),
]
KIND = {k[0]: k for k in KINDS}

#--- Groups for the properties only the config's own rules set
EXTRA_GROUPS = {"default-floating-position": "Size & Position", "open-maximized-to-edges": "Size & Position",
                "geometry-corner-radius": "Appearance", "clip-to-geometry": "Appearance",
                "draw-border-with-background": "Appearance", "shadow": "Appearance",
                "focus-ring": "Appearance", "border": "Appearance", "tab-indicator": "Appearance"}

#--- (group, description, icon, chip kind; the kind colours the group's tags)
GROUPS = [("Floating", "Windows that open above the tiled ones.", "focus-windows-symbolic", "accent"),
          ("Size & Position", "How big a window opens, and where.", "view-fullscreen-symbolic", "success"),
          ("Placement", "The workspace or monitor a window opens on.", "video-display-symbolic", "success"),
          ("Focus", "Whether a window takes the keyboard when it opens.", "input-keyboard-symbolic",
           "warning"),
          ("Appearance", "Opacity, corners, borders and shadows.", "applications-graphics-symbolic", "accent"),
          ("Privacy", "Blacked out in screenshots and screen recordings.", "security-high-symbolic", "error"),
          ("Performance", "Variable refresh rate while the window is shown.", "speedometer-symbolic",
           "warning"),
          ("Other", "", "applications-system-symbolic", "neutral")]
GROUP = {g[0]: g for g in GROUPS}

NOT_PROPERTIES = ("name", "note", "matches", "excludes")


#--------------------------------------------------------------------#
#-- Reading and writing
#--------------------------------------------------------------------#
def clean(value):
    """`value` without the unset (null) options and empty lists niri-flake fills in."""
    if isinstance(value, dict):
        out = {}
        for k, v in value.items():
            c = clean(v)
            if c is None or c == [] or (isinstance(v, dict) and v and c == {}):
                continue
            out[k] = c
        return out
    if isinstance(value, list):
        return [clean(v) for v in value]
    return value


def bare(rule):
    """A rule as rules.nix hands it to niri: without its name and note."""
    return clean({k: v for k, v in rule.items() if k not in ("name", "note")})


def load(path):
    try:
        with open(path) as f:
            data = json.load(f)
        return data if isinstance(data, list) else []
    except (OSError, ValueError):
        return []


def load_applied():
    """(every rule niri got, the window-rules.json that build used); the second
    is None from a build before rules.nix wrote it."""
    try:
        with open(APPLIED_FILE) as f:
            data = json.load(f)
    except (OSError, ValueError):
        return [], None
    if isinstance(data, list):
        return data, None
    return data.get("all") or [], data.get("file")


def save(path, rules):
    with open(path, "w") as f:
        f.write(json.dumps(rules, indent=2) + "\n")


def regex(text):
    """`text` matched exactly, as a niri regular expression."""
    return "^" + "".join("\\" + c if c in SPECIAL else c for c in text) + "$"


def niri(args, timeout=None):
    """`niri msg --json <args>`'s answer; None when it isn't JSON (a cancelled pick)."""
    try:
        proc = subprocess.run(["niri", "msg", "--json", *args], capture_output=True, text=True,
                              timeout=timeout)
    except FileNotFoundError:
        raise OSError("niri isn't installed")
    if proc.returncode:
        raise OSError((proc.stderr or proc.stdout).strip() or "niri msg failed")
    try:
        return json.loads(proc.stdout)
    except ValueError:
        return None


def places():
    """(workspace names, monitor names) niri has now, for Open on Workspace and Monitor."""
    try:
        workspaces = sorted({w["name"] for w in niri(["workspaces"], 5) or [] if w.get("name")},
                            key=lambda n: (len(n), n))
        outputs = sorted((niri(["outputs"], 5) or {}).keys())
    except (OSError, subprocess.TimeoutExpired):
        return [], []
    return workspaces, outputs


def listing(path):
    """(the file's rules, the rules Nix sets itself, whether the last build has
    rules other than the file's). What niri got, less the file's rules, is what
    Nix sets; {"include": ...} entries are left to rules.nix."""
    rules = load(path)
    applied, applied_file = load_applied()
    current = [bare(r) for r in rules if "include" not in r]
    built = current if applied_file is None else [bare(r) for r in applied_file if "include" not in r]
    from_nix = [clean(r) for r in applied]
    waiting = applied_file is not None and built != current
    for r in built:
        if r in from_nix:
            from_nix.remove(r)
        elif applied_file is None:
            waiting = True
    return rules, from_nix, waiting


def add_rule(rules, match, name, prop, value):
    """Sets `prop` for `match` in `rules`: one rule per window, so a second
    property for it joins the first."""
    rule = next((r for r in rules if r.get("matches") == [match] and not r.get("excludes")), None)
    if rule is None:
        rule = {"name": name, "matches": [match]}
        rules.append(rule)
    else:
        rule["name"] = name
    rule[prop] = floats(value, prop)
    return rule


def floats(value, key=None):
    """`value` with whole-number proportions and opacities as floats, which
    niri-flake's options need; JSON from the QML front end loses the `.0`."""
    if isinstance(value, dict):
        return {k: floats(v, k) for k, v in value.items()}
    if isinstance(value, list):
        return [floats(v) for v in value]
    if key in ("proportion", "opacity") and isinstance(value, int) and not isinstance(value, bool):
        return float(value)
    return value


def edited(rule, original):
    """An edited `rule` with floats fixed, in `original`'s key order (a new
    name or note first, other new keys last), keeping `original`'s own value
    wherever the edit left it equal."""
    rule = floats(rule)
    new = [k for k in rule if k not in original]
    labels = [k for k in ("name", "note") if k in new]
    order = labels + [k for k in original if k in rule] + [k for k in new if k not in labels]
    return {k: original[k] if k in original and original[k] == rule[k] else rule[k] for k in order}


#--------------------------------------------------------------------#
#-- Describing a rule
#--------------------------------------------------------------------#
def size_text(value):
    if value == {}:
        return "the window's own"
    if "fixed" in value:
        return f"{value['fixed']} px"
    p = value.get("proportion")
    for label, v in SIZES:
        if v and abs(v.get("proportion", -1) - (p or 0)) < 0.001:
            return label.lower()
    return f"{round((p or 0) * 100)}%" if p is not None else json.dumps(value)


def property_text(prop, value):
    kind = KIND.get(prop)
    if prop in ("default-column-width", "default-window-height") and isinstance(value, dict):
        return f"{kind[1]}: {size_text(value)}"
    if prop == "opacity":
        return f"Opacity {round(value * 100)}%"
    if kind and kind[3] == "choice":
        label = next((l for l, v in kind[4] if v == value), str(value))
        return f"{kind[1]}: {label}"
    if kind and kind[3] in ("workspace", "output"):
        return f"{kind[1]} {value}"
    title = kind[1] if kind else prop.replace("-", " ").capitalize()
    if value is True:
        return title
    if value is False:
        return f"{title}: off"
    if prop == "default-floating-position" and isinstance(value, dict):
        return f"Position: {value.get('x', 0)}, {value.get('y', 0)} from {value.get('relative-to', 'top-left')}"
    if isinstance(value, dict):
        value = ", ".join(f"{k.replace('-', ' ')} {v if isinstance(v, (str, int, float)) else json.dumps(v)}"
                          for k, v in value.items())
    return f"{title}: {value}"


def pretty(pattern):
    """An exact-match regex (^name$) as the plain name it matches."""
    if len(pattern) > 1 and pattern[0] == "^" and pattern[-1] == "$":
        inner, out, i = pattern[1:-1], "", 0
        while i < len(inner):
            c = inner[i]
            if c == "\\" and i + 1 < len(inner) and inner[i + 1] in SPECIAL:
                out, i = out + inner[i + 1], i + 2
                continue
            if c in SPECIAL:
                return pattern
            out, i = out + c, i + 1
        return out
    return pattern


def match_text(match):
    parts = []
    if "app-id" in match:
        parts.append(pretty(match["app-id"]))
    if "title" in match:
        parts.append(f"titled {pretty(match['title'])}")
    for k, v in match.items():
        if k not in ("app-id", "title"):
            parts.append(k.replace("-", " ") if v is True else f"{k.replace('-', ' ')} {v}")
    return ", ".join(parts) or "any window"


def tag_text(prop, value):
    """A short label for one thing a rule does, for its tag."""
    if prop in ("default-column-width", "default-window-height") and isinstance(value, dict):
        return f"{'Width' if prop == 'default-column-width' else 'Height'} {size_text(value)}"
    short = {"open-floating": ("Floating", "Tiled"), "open-maximized": ("Maximized", "Not maximized"),
             "open-fullscreen": ("Fullscreen", "Not fullscreen"), "open-focused": ("Focused", "Unfocused"),
             "variable-refresh-rate": ("VRR", "No VRR"), "clip-to-geometry": ("Clipped", "Not clipped"),
             "draw-border-with-background": ("Solid border", "No border fill")}
    if prop in short and isinstance(value, bool):
        return short[prop][0 if value else 1]
    if prop == "block-out-from":
        return "Hidden from capture" if value == "screen-capture" else "Hidden from recording"
    if prop == "opacity":
        return f"Opacity {round(value * 100)}%"
    if prop == "open-on-workspace":
        return f"Workspace {value}"
    if prop == "open-on-output":
        return f"Monitor {value}"
    if prop == "default-floating-position" and isinstance(value, dict):
        return f"At {value.get('relative-to', 'top-left')}"
    if prop == "geometry-corner-radius":
        radii = set(value.values()) if isinstance(value, dict) else {value}
        return f"Corners {radii.pop():g}" if len(radii) == 1 else "Corners"
    if prop == "shadow" and isinstance(value, dict) and set(value) == {"enable"}:
        return "Shadow" if value["enable"] else "No shadow"
    return prop.replace("-", " ").capitalize()


def tag_kind(prop):
    group = KIND[prop][2] if prop in KIND else EXTRA_GROUPS.get(prop, "Other")
    return GROUP[group][3]


def plain(pattern):
    """A pattern as the text it looks for, ignoring case flags and anchors,
    or the pattern itself when it is more than plain text."""
    inner = pattern.removeprefix("(?i)").removeprefix("^").removesuffix("$")
    text = pretty(f"^{inner}$")
    return pattern if text.startswith("^") else text


def window_name(match):
    """A match as a person would name it: the app's own name where its .desktop
    file has one, else what it matches."""
    parts = []
    if "app-id" in match:
        app = plain(match["app-id"])
        parts.append(app_name(app) or app)
    if "title" in match:
        parts.append(f"“{plain(match['title'])}”" if parts else f"Windows titled “{plain(match['title'])}”")
    if match.get("is-floating"):
        parts.append("Floating windows")
    if match.get("is-window-cast-target"):
        parts.append("The window being screencast")
    for k, v in match.items():
        if k not in ("app-id", "title", "is-floating", "is-window-cast-target"):
            parts.append(f"{k.replace('-', ' ')} {v}")
    return " ".join(parts) or "Any window"


def match_pattern(match):
    """A match's raw patterns, as niri reads them."""
    return "  ".join(f"{k}={v}" for k, v in match.items())



def rule_title(rule):
    matches = rule.get("matches") or []
    if rule.get("name"):
        return rule["name"]
    if not matches:
        return "Every Window"
    if len(matches) == 1:
        return window_name(matches[0])
    if all("app-id" in m for m in matches):
        return f"{len(matches)} Apps"
    return f"{len(matches)} Kinds of Window"


def properties(rule):
    return [(k, v) for k, v in rule.items() if k not in NOT_PROPERTIES]


def group_of(rule):
    props = [k for k, _ in properties(rule)]
    for prop, _, group, _, _ in KINDS:
        if prop in props:
            return group
    return next((EXTRA_GROUPS[p] for p in props if p in EXTRA_GROUPS), "Other")


def app_name(app_id):
    """The name an app's .desktop file gives, if it has one under its app ID."""
    if not app_id:
        return ""
    home = os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share")
    dirs = [home] + (os.environ.get("XDG_DATA_DIRS") or "/usr/local/share:/usr/share").split(":")
    for d in dirs:
        path = os.path.join(d, "applications", f"{app_id}.desktop")
        if not os.path.isfile(path):
            continue
        parser = configparser.RawConfigParser(strict=False, interpolation=None)
        parser.optionxform = str
        try:
            parser.read(path, encoding="utf-8")
            return parser.get("Desktop Entry", "Name", fallback="")
        except (configparser.Error, UnicodeDecodeError):
            return ""
    return ""

