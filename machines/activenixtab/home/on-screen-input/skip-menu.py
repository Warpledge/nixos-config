"""A touch menu for autocorrect's skip list: add the app that has focus, or remove any app
already there. autocorrect.py rereads the file for each correction, so changes apply at
once. Opened by osk-skip-menu; opening it again closes it."""

import json
import os
import subprocess

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
from gi.repository import GLib, Gtk  # noqa: E402
from gi.repository import Gtk4LayerShell as LayerShell  # noqa: E402

CONFIG_DIR = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
SKIP_FILE = os.path.join(CONFIG_DIR, "osk-autocorrect-skip")  # autocorrect.py reads this
BUILT_IN = ("kitty", "ghostty", "foot", "alacritty", "konsole", "keepassxc")  # SKIP_APPS there


def focused_app():
    try:
        out = subprocess.run(
            ["niri", "msg", "--json", "focused-window"],
            capture_output=True,
            text=True,
            timeout=1,
        )
        return (json.loads(out.stdout) or {}).get("app_id") or ""
    except (OSError, ValueError, subprocess.SubprocessError):
        return ""


def read_list():
    try:
        with open(SKIP_FILE) as f:
            return [line.strip() for line in f if line.strip()]
    except OSError:
        return []


def write_list(apps):
    os.makedirs(CONFIG_DIR, exist_ok=True)
    temp = f"{SKIP_FILE}.tmp"
    with open(temp, "w") as f:
        f.writelines(f"{app}\n" for app in apps)
    os.replace(temp, SKIP_FILE)


def skipped(app, apps):
    # The same matching as safe_to_correct in autocorrect.py
    return any(s.lower() in app.lower() for s in (*BUILT_IN, *apps))


def add(_button, app):
    write_list([*read_list(), app])
    refresh()


def remove(_button, app):
    write_list([a for a in read_list() if a != app])
    refresh()


def row_button(label, handler=None, app=None, sensitive=True):
    button = Gtk.Button(label=label, sensitive=sensitive)
    button.set_size_request(-1, 64)  # big enough for a thumb
    if handler:
        button.connect("clicked", handler, app)
    return button


def refresh():
    apps = read_list()
    while child := box.get_first_child():
        box.remove(child)
    title = Gtk.Label(label="Autocorrect skips these apps")
    title.add_css_class("title-4")
    box.append(title)
    if not current_app:
        box.append(row_button("No app has focus", sensitive=False))
    elif skipped(current_app, apps):
        box.append(row_button(f"{current_app} is skipped", sensitive=False))
    else:
        box.append(row_button(f"Skip {current_app}", add, current_app))
    if not apps:
        box.append(Gtk.Label(label="Nothing added yet"))
    for app in apps:
        row = Gtk.Box(spacing=12)
        name = Gtk.Label(label=app, hexpand=True, xalign=0)
        row.append(name)
        row.append(row_button("Remove", remove, app))
        box.append(row)
    close = row_button("Close")
    close.connect("clicked", lambda _b: loop.quit())
    box.append(close)


current_app = focused_app()  # before anything else can change it
Gtk.init()
loop = GLib.MainLoop()
window = Gtk.Window(decorated=False)
LayerShell.init_for_window(window)
LayerShell.set_namespace(window, "osk-skip-menu")
LayerShell.set_layer(window, LayerShell.Layer.OVERLAY)
LayerShell.set_keyboard_mode(window, LayerShell.KeyboardMode.NONE)
LayerShell.set_anchor(window, LayerShell.Edge.TOP, True)
LayerShell.set_margin(window, LayerShell.Edge.TOP, 80)  # clear of the bar, above the keyboard
box = Gtk.Box(
    orientation=Gtk.Orientation.VERTICAL,
    spacing=12,
    margin_top=16,
    margin_bottom=16,
    margin_start=16,
    margin_end=16,
)
box.set_size_request(480, -1)
window.set_child(box)
window.connect("close-request", lambda _w: loop.quit())
refresh()
window.present()
GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, 15, lambda: loop.quit())
loop.run()
