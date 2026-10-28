"""On-screen touchpad: a panel in the screen's bottom-right corner whose
touches drive a virtual touchpad, so libinput gives it the folio's behaviour
(tap, two-finger tap and scroll, tap-and-drag)."""

import os
import signal

import gi

gi.require_version("Gdk", "4.0")
gi.require_version("Gtk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
from evdev import AbsInfo, UInput
from evdev import ecodes as e
from gi.repository import Gdk, Gio, GLib, GLibUnix, Gtk
from gi.repository import Gtk4LayerShell as Layer

STYLE = os.path.expanduser("~/.config/on-screen-touchpad/style.css")

WIDTH, HEIGHT = map(int, os.environ.get("TOUCHPAD_SIZE", "480x300").split("x"))
SCALE = 10  # device units per logical px
# Units per mm, for libinput's speed: a logical px here is ~0.156 mm on the
# Z13's panel (2560 px at scale 4/3 over ~300 mm), so the pad moves the
# pointer like a real one of its size
RES = round(SCALE / 0.156)
SLOTS = 5

pad = UInput(
    {
        e.EV_KEY: [
            e.BTN_LEFT,
            e.BTN_RIGHT,
            e.BTN_TOUCH,
            e.BTN_TOOL_FINGER,
            e.BTN_TOOL_DOUBLETAP,
            e.BTN_TOOL_TRIPLETAP,
            e.BTN_TOOL_QUADTAP,
            e.BTN_TOOL_QUINTTAP,
        ],
        e.EV_ABS: [
            (e.ABS_X, AbsInfo(0, 0, WIDTH * SCALE, 0, 0, RES)),
            (e.ABS_Y, AbsInfo(0, 0, HEIGHT * SCALE, 0, 0, RES)),
            (e.ABS_MT_SLOT, AbsInfo(0, 0, SLOTS - 1, 0, 0, 0)),
            (e.ABS_MT_TRACKING_ID, AbsInfo(0, 0, 65535, 0, 0, 0)),
            (e.ABS_MT_POSITION_X, AbsInfo(0, 0, WIDTH * SCALE, 0, 0, RES)),
            (e.ABS_MT_POSITION_Y, AbsInfo(0, 0, HEIGHT * SCALE, 0, 0, RES)),
        ],
    },
    name="On-screen touchpad",
    input_props=[e.INPUT_PROP_POINTER],
)
TOOLS = [
    e.BTN_TOOL_FINGER,
    e.BTN_TOOL_DOUBLETAP,
    e.BTN_TOOL_TRIPLETAP,
    e.BTN_TOOL_QUADTAP,
    e.BTN_TOOL_QUINTTAP,
]

slots = {}  # GdkEventSequence -> slot
next_id = 0


def clamp(v, top):
    return max(0, min(top, round(v * SCALE)))


def send(slot, x, y, down):
    global next_id
    pad.write(e.EV_ABS, e.ABS_MT_SLOT, slot)
    if down is True:
        pad.write(e.EV_ABS, e.ABS_MT_TRACKING_ID, next_id)
        next_id = (next_id + 1) % 65535
    if down is False:
        pad.write(e.EV_ABS, e.ABS_MT_TRACKING_ID, -1)
    else:
        px, py = clamp(x, WIDTH * SCALE), clamp(y, HEIGHT * SCALE)
        pad.write(e.EV_ABS, e.ABS_MT_POSITION_X, px)
        pad.write(e.EV_ABS, e.ABS_MT_POSITION_Y, py)
        if slot == min(slots.values()):
            pad.write(e.EV_ABS, e.ABS_X, px)
            pad.write(e.EV_ABS, e.ABS_Y, py)
    n = len(slots)
    pad.write(e.EV_KEY, e.BTN_TOUCH, 1 if n else 0)
    for i, tool in enumerate(TOOLS):
        pad.write(e.EV_KEY, tool, 1 if n == i + 1 else 0)
    pad.syn()


def on_event(controller, _event):
    # PyGObject hands the signal's GdkEvent over as None; the controller has it
    event = controller.get_current_event()
    if event is None:
        return False
    kind = event.get_event_type()
    if kind not in (
        Gdk.EventType.TOUCH_BEGIN,
        Gdk.EventType.TOUCH_UPDATE,
        Gdk.EventType.TOUCH_END,
        Gdk.EventType.TOUCH_CANCEL,
    ):
        return False
    seq = event.get_event_sequence()
    _, x, y = event.get_position()
    if kind == Gdk.EventType.TOUCH_BEGIN:
        free = [s for s in range(SLOTS) if s not in slots.values()]
        if not free:
            return True
        slots[seq] = free[0]
        send(slots[seq], x, y, True)
    elif seq in slots:
        if kind == Gdk.EventType.TOUCH_UPDATE:
            send(slots[seq], x, y, None)
        else:
            slot = slots.pop(seq)
            send(slot, x, y, False)
    return True


def activate(app):
    win = Gtk.ApplicationWindow(application=app)
    Layer.init_for_window(win)
    Layer.set_namespace(win, "on-screen-touchpad")
    Layer.set_layer(win, Layer.Layer.OVERLAY)
    # Never takes keyboard focus, so typing still goes to the focused window
    Layer.set_keyboard_mode(win, Layer.KeyboardMode.NONE)
    # In the space wvkbd leaves at its right, not above its exclusive zone
    for edge in (Layer.Edge.BOTTOM, Layer.Edge.RIGHT):
        Layer.set_anchor(win, edge, True)
    Layer.set_exclusive_zone(win, -1)
    win.set_default_size(WIDTH, HEIGHT)

    area = Gtk.Box()
    area.add_css_class("touchpad")
    area.set_size_request(WIDTH, HEIGHT)
    legacy = Gtk.EventControllerLegacy()
    legacy.connect("event", on_event)
    area.add_controller(legacy)
    win.set_child(area)

    display = Gdk.Display.get_default()
    base = Gtk.CssProvider()
    # Until matugen has written STYLE, the GTK theme's own colours
    base.load_from_string(
        "window { background: transparent; }"
        " .touchpad { background: alpha(@window_bg_color, 0.92);"
        " border: 2px solid alpha(@window_fg_color, 0.5); border-radius: 16px; }"
    )
    Gtk.StyleContext.add_provider_for_display(
        display, base, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )

    # The pad's colours, rendered by DMS's matugen; reloaded on a theme change
    theme = Gtk.CssProvider()
    Gtk.StyleContext.add_provider_for_display(
        display, theme, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )

    def load_theme(*_):
        if os.path.exists(STYLE):
            theme.load_from_path(STYLE)

    load_theme()
    monitor = Gio.File.new_for_path(STYLE).monitor_file(Gio.FileMonitorFlags.NONE)
    monitor.connect("changed", load_theme)
    win.monitor = monitor  # keeps it alive

    # SIGUSR1 (from raise-watch.py) remaps the window: a new layer surface,
    # stacked above overlays opened since
    def restack():
        win.set_visible(False)
        win.set_visible(True)
        return GLib.SOURCE_CONTINUE

    GLibUnix.signal_add(GLib.PRIORITY_DEFAULT, signal.SIGUSR1, restack)
    win.present()


app = Gtk.Application(application_id="local.on-screen-touchpad")
app.connect("activate", activate)
try:
    app.run(None)
finally:
    pad.close()
