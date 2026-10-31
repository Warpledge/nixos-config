"""On-screen touchpad: the whole screen minus the keyboard strip and the top
bar acts as one giant touchpad — only while pad mode is on, which the PAD key
on wvkbd (F13, bound in niri) or the bar button toggles. Finger movement maps
relatively (the pointer moves by the finger's motion, never jumping to it),
so libinput gives it the folio's behaviour: tap, two-finger tap and scroll,
tap-and-drag. Hidden and inert otherwise."""

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

# Screen strips the pad never covers: the keyboard (bottom) and the bar (top)
MARGIN_BOTTOM = int(os.environ.get("OSK_PAD_BOTTOM", "360"))
MARGIN_TOP = int(os.environ.get("OSK_PAD_TOP", "36"))
SCALE = 10  # device units per logical px
# Units per mm, for libinput's speed: a logical px here is ~0.156 mm on the
# Z13's panel (2560 px at scale 4/3 over ~300 mm), so the pad moves the
# pointer like a real one of its size
RES = round(SCALE / 0.156)
SLOTS = 2  # a third finger belongs to touch-gestures.py, not to the pad

TOOLS = [
    e.BTN_TOOL_FINGER,
    e.BTN_TOOL_DOUBLETAP,
    e.BTN_TOOL_TRIPLETAP,
    e.BTN_TOOL_QUADTAP,
    e.BTN_TOOL_QUINTTAP,
]


def make_pad(width, height):
    """(Re)declare the virtual touchpad at the window's current size."""
    return UInput(
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
                (e.ABS_X, AbsInfo(0, 0, width * SCALE, 0, 0, RES)),
                (e.ABS_Y, AbsInfo(0, 0, height * SCALE, 0, 0, RES)),
                (e.ABS_MT_SLOT, AbsInfo(0, 0, SLOTS - 1, 0, 0, 0)),
                (e.ABS_MT_TRACKING_ID, AbsInfo(0, 0, 65535, 0, 0, 0)),
                (e.ABS_MT_POSITION_X, AbsInfo(0, 0, width * SCALE, 0, 0, RES)),
                (e.ABS_MT_POSITION_Y, AbsInfo(0, 0, height * SCALE, 0, 0, RES)),
            ],
        },
        name="On-screen touchpad",
        input_props=[e.INPUT_PROP_POINTER],
    )


pad = None
pad_size = (0, 0)
slots = {}  # GdkEventSequence -> (slot, anchor x, anchor y, begin x, begin y)
next_id = 0
last = None  # where the last gesture ended, in pad units; the pointer stays


def clamp(v, top):
    return max(0, min(top, round(v)))


def send(slot, x, y, down):
    global next_id
    pad.write(e.EV_ABS, e.ABS_MT_SLOT, slot)
    if down is True:
        pad.write(e.EV_ABS, e.ABS_MT_TRACKING_ID, next_id)
        next_id = (next_id + 1) % 65535
    if down is False:
        pad.write(e.EV_ABS, e.ABS_MT_TRACKING_ID, -1)
    else:
        px, py = int(x), int(y)
        pad.write(e.EV_ABS, e.ABS_MT_POSITION_X, px)
        pad.write(e.EV_ABS, e.ABS_MT_POSITION_Y, py)
        first = [s[0] for s in slots.values()]
        if first and slot == min(first):
            pad.write(e.EV_ABS, e.ABS_X, px)
            pad.write(e.EV_ABS, e.ABS_Y, py)
    n = len(slots)
    pad.write(e.EV_KEY, e.BTN_TOUCH, 1 if n else 0)
    for i, tool in enumerate(TOOLS):
        pad.write(e.EV_KEY, tool, 1 if n == i + 1 else 0)
    pad.syn()


def on_event(controller, _event):
    # PyGObject hands the signal's GdkEvent over as None; the controller has it
    global last
    event = controller.get_current_event()
    if event is None or pad is None:
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
    wx, wy = pad_size
    if kind == Gdk.EventType.TOUCH_BEGIN:
        free = [s for s in range(SLOTS) if s not in (v[0] for v in slots.values())]
        if not free:
            return True  # a third finger: leave it to touch-gestures.py
        if not slots:
            # The pad picks the pointer up where the last gesture left it
            ax, ay = last if last else (wx * SCALE / 2, wy * SCALE / 2)
        else:
            # Later fingers keep their start offsets from the first one, so
            # libinput still sees the two-finger gestures it knows
            (slot0, ax0, ay0, x0, y0) = next(iter(slots.values()))
            ax, ay = ax0 + (x - x0) * SCALE, ay0 + (y - y0) * SCALE
        ax = clamp(ax, wx * SCALE)
        ay = clamp(ay, wy * SCALE)
        slots[seq] = (free[0], ax, ay, x, y)
        send(slots[seq][0], ax, ay, True)
    elif seq in slots:
        slot, ax, ay, x0, y0 = slots.pop(seq)
        px = clamp(ax + (x - x0) * SCALE, wx * SCALE)
        py = clamp(ay + (y - y0) * SCALE, wy * SCALE)
        if kind == Gdk.EventType.TOUCH_UPDATE:
            slots[seq] = (slot, ax, ay, x0, y0)
            send(slot, px, py, None)
        else:
            send(slot, px, py, False)
            if not slots:
                last = (px, py)
    return True


def activate(app):
    win = Gtk.ApplicationWindow(application=app)
    Layer.init_for_window(win)
    Layer.set_namespace(win, "on-screen-touchpad")
    Layer.set_layer(win, Layer.Layer.OVERLAY)
    # Never takes keyboard focus, so typing still goes to the focused window
    Layer.set_keyboard_mode(win, Layer.KeyboardMode.NONE)
    # All edges, with the keyboard and the bar left free
    for edge in (
        Layer.Edge.TOP,
        Layer.Edge.BOTTOM,
        Layer.Edge.LEFT,
        Layer.Edge.RIGHT,
    ):
        Layer.set_anchor(win, edge, True)
    Layer.set_margin(win, Layer.Edge.BOTTOM, MARGIN_BOTTOM)
    Layer.set_margin(win, Layer.Edge.TOP, MARGIN_TOP)
    Layer.set_exclusive_zone(win, -1)

    cover = Gtk.Overlay()
    area = Gtk.Box()
    area.add_css_class("touchpad")
    hint = Gtk.Label(label="touchpad mode · PAD ends it")
    hint.add_css_class("hint")
    hint.set_halign(Gtk.Align.START)
    hint.set_valign(Gtk.Align.START)
    hint.set_can_target(False)  # touches pass through the hint to the pad
    cover.set_child(area)
    cover.add_overlay(hint)
    legacy = Gtk.EventControllerLegacy()
    legacy.connect("event", on_event)
    area.add_controller(legacy)
    win.set_child(cover)

    display = Gdk.Display.get_default()
    base = Gtk.CssProvider()
    # Until matugen has written STYLE, the GTK theme's own colours
    base.load_from_string(
        "window { background: transparent; }"
        " .touchpad { background: alpha(@window_bg_color, 0.12);"
        " border: 2px solid alpha(@window_fg_color, 0.35); }"
        " .hint { margin: 12px; padding: 4px 10px; border-radius: 10px;"
        " background: alpha(@window_bg_color, 0.7);"
        " color: alpha(@window_fg_color, 0.9); font-weight: bold; }"
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

    # Anchoring all edges is not a size: GTK asks for the child's natural size,
    # which is 0x0. So the pad area carries an explicit size request for the
    # screen minus the margins, set before mapping and re-checked every second
    # (the only way it changes while niri lives is rotation).
    def check_size(*_):
        global pad, pad_size
        mon = display.get_monitors()
        if mon:
            geo = mon[0].get_geometry()
            area.set_size_request(
                geo.width, max(1, geo.height - MARGIN_TOP - MARGIN_BOTTOM)
            )
        a = area.get_allocation()
        if a.width > 1 and a.height > 1 and (a.width, a.height) != pad_size:
            if pad:
                pad.close()
            pad_size = (a.width, a.height)
            pad = make_pad(a.width, a.height)
        return GLib.SOURCE_CONTINUE

    check_size()
    GLib.timeout_add_seconds(1, check_size)
    # On mapping, the allocation lands before the next tick would notice
    area.connect(
        "map",
        lambda *_: GLib.idle_add(lambda: (check_size(), False)[1]),
    )

    # SIGUSR1 (from raise-watch.py) remaps the window: a new layer surface,
    # stacked above overlays opened since
    def restack():
        if win.get_mapped():
            win.set_visible(False)
            win.present()
        return GLib.SOURCE_CONTINUE

    # SIGUSR2 (from osk-pad-mode) switches pad mode; off means no surface at
    # all, so every touch goes to the windows below untouched
    def toggle():
        if win.get_mapped():
            for (slot, *_rest) in slots.values():
                send(slot, 0, 0, False)
            slots.clear()
            win.set_visible(False)
        else:
            check_size()  # first-frame size, not one tick late
            win.present()
        return GLib.SOURCE_CONTINUE

    GLibUnix.signal_add(GLib.PRIORITY_DEFAULT, signal.SIGUSR1, restack)
    GLibUnix.signal_add(GLib.PRIORITY_DEFAULT, signal.SIGUSR2, toggle)
    # Pad mode starts off: no surface, so the screen is untouched
    win.set_visible(False)


app = Gtk.Application(application_id="local.on-screen-touchpad")
app.connect("activate", activate)
try:
    app.run(None)
finally:
    if pad:
        pad.close()
