"""On-screen touchpad: a panel in the screen's bottom-right corner whose
touches drive a virtual touchpad, so libinput gives it the folio's behaviour
(tap, two-finger tap and scroll, tap-and-drag)."""

import gi

gi.require_version("Gdk", "4.0")
gi.require_version("Gtk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
from evdev import AbsInfo, UInput
from evdev import ecodes as e
from gi.repository import Gdk, Gtk
from gi.repository import Gtk4LayerShell as Layer

WIDTH, HEIGHT = 480, 300  # logical px
SCALE = 10  # device units per logical px
# Units per mm, for libinput's speed: a logical px here is ~0.175 mm on the
# Z13's panel (2560 px at scale 1.5 over ~300 mm), so the pad moves the
# pointer like a real one of its size
RES = round(SCALE / 0.175)
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


def on_event(_controller, event):
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
    for edge in (Layer.Edge.BOTTOM, Layer.Edge.RIGHT):
        Layer.set_anchor(win, edge, True)
        Layer.set_margin(win, edge, 16)
    win.set_default_size(WIDTH, HEIGHT)

    area = Gtk.Box()
    area.add_css_class("touchpad")
    area.set_size_request(WIDTH, HEIGHT)
    legacy = Gtk.EventControllerLegacy()
    legacy.connect("event", on_event)
    area.add_controller(legacy)
    win.set_child(area)

    css = Gtk.CssProvider()
    css.load_from_string(
        ".touchpad { background: alpha(@window_fg_color, 0.12);"
        " border: 1px solid alpha(@window_fg_color, 0.3); border-radius: 16px; }"
        " window { background: transparent; }"
    )
    Gtk.StyleContext.add_provider_for_display(
        Gdk.Display.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )
    win.present()


app = Gtk.Application(application_id="local.on-screen-touchpad")
app.connect("activate", activate)
try:
    app.run(None)
finally:
    pad.close()
