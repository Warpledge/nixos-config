"""A touchscreen gamepad: a virtual Xbox 360 controller that Steam Input can remap, drawn on
a see-through overlay that takes no input. While it runs it holds the touchscreen, so
touches reach it and not the game; touch-gestures.py lets go on SIGUSR1 and takes the
screen back once this process is gone. A virtual Xbox pad has no trackpads, so the right
pad drives the right stick and the left pad the D-pad.
Usage: gamepad <touchscreen event device> <font name> <colours file>"""

import json
import math
import os
import signal
import subprocess
import sys
import time

import cairo
import gi

gi.require_version("Gdk", "4.0")
gi.require_version("Gtk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
from gi.repository import Gdk, GLib, Gtk  # noqa: E402
from gi.repository import Gtk4LayerShell as LayerShell  # noqa: E402

import evdev  # noqa: E402
from evdev import AbsInfo, UInput  # noqa: E402
from evdev import ecodes as e  # noqa: E402

STICK_TRAVEL = 90  # logical px of finger travel for a full stick
PAD_TRAVEL = 140  # the same for the right pad
HAT_DEAD_ZONE = 0.25  # share of the D-pad's radius that presses nothing
TAP_SECONDS = 0.2  # a stick touch this short, barely moving, clicks it (L3/R3)
TAP_TRAVEL = 15
CLICK_SECONDS = 0.08
HIT_SLACK = 1.2  # how far outside a control a landing finger still counts
UI_SCALE = 1 / 1200  # sizes below are px at 1200 px on the screen's short side

# name, kind, code, label, x and y (share of the screen), radius or half-width and height
CONTROLS = [
    ("lt", "trigger", e.ABS_Z, "LT", 0.08, 0.07, (130, 50)),
    ("lb", "button", e.BTN_TL, "LB", 0.08, 0.17, (130, 50)),
    ("rt", "trigger", e.ABS_RZ, "RT", 0.92, 0.07, (130, 50)),
    ("rb", "button", e.BTN_TR, "RB", 0.92, 0.17, (130, 50)),
    ("select", "button", e.BTN_SELECT, "Select", 0.39, 0.07, (70, 40)),
    ("guide", "button", e.BTN_MODE, "Guide", 0.5, 0.07, (70, 40)),
    ("start", "button", e.BTN_START, "Start", 0.61, 0.07, (70, 40)),
    ("close", "close", None, "✕", 0.5, 0.17, 40),
    ("lstick", "stick", e.BTN_THUMBL, "", 0.1, 0.42, 130),
    ("dpad", "hat", None, "", 0.27, 0.62, 120),
    ("lpad", "hat", None, "", 0.1, 0.78, 150),
    ("rstick", "stick", e.BTN_THUMBR, "", 0.73, 0.62, 130),
    ("rpad", "pad", None, "", 0.9, 0.78, 150),
    ("y", "button", e.BTN_Y, "Y", 0.9, 0.3, 58),
    ("x", "button", e.BTN_X, "X", 0.84, 0.42, 58),
    ("b", "button", e.BTN_B, "B", 0.96, 0.42, 58),
    ("a", "button", e.BTN_A, "A", 0.9, 0.54, 58),
]
STICK_AXES = {"lstick": (e.ABS_X, e.ABS_Y), "rstick": (e.ABS_RX, e.ABS_RY)}

RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
PID_FILE = os.path.join(RUNTIME_DIR, "osk-gamepad.pid")


def new_controller():
    stick = AbsInfo(0, -32768, 32767, 16, 128, 0)
    trigger = AbsInfo(0, 0, 255, 0, 0, 0)
    hat = AbsInfo(0, -1, 1, 0, 0, 0)
    return UInput(
        {
            e.EV_KEY: [c[2] for c in CONTROLS if c[1] in ("button", "stick")],
            e.EV_ABS: [
                (e.ABS_X, stick),
                (e.ABS_Y, stick),
                (e.ABS_RX, stick),
                (e.ABS_RY, stick),
                (e.ABS_Z, trigger),
                (e.ABS_RZ, trigger),
                (e.ABS_HAT0X, hat),
                (e.ABS_HAT0Y, hat),
            ],
        },
        name="Microsoft X-Box 360 pad",
        vendor=0x045E,
        product=0x028E,
        version=0x110,
        bustype=e.BUS_USB,
    )


def read_output():
    out = subprocess.run(
        ["niri", "msg", "--json", "focused-output"],
        capture_output=True,
        text=True,
        timeout=1,
    )
    return json.loads(out.stdout)["logical"]


def on_screen(pos, t):
    # Keep in sync with on_screen in wm/touch-gestures.py
    nx, ny = pos[0] / xmax, pos[1] / ymax
    return {
        "90": (1 - ny, nx),
        "180": (1 - nx, 1 - ny),
        "270": (ny, 1 - nx),
    }.get(t, (nx, ny))


def to_px(pos):
    x, y = on_screen(pos, output["transform"])
    return x * output["width"], y * output["height"]


def scale():
    return min(output["width"], output["height"]) * UI_SCALE


def center(control):
    return control[4] * output["width"], control[5] * output["height"]


def hit(control, x, y):
    cx, cy = center(control)
    size = control[6]
    s = scale() * HIT_SLACK
    if isinstance(size, tuple):
        return abs(x - cx) <= size[0] * s and abs(y - cy) <= size[1] * s
    return math.hypot(x - cx, y - cy) <= size * s


def control_at(x, y, kinds=None):
    found = [c for c in CONTROLS if (not kinds or c[1] in kinds) and hit(c, x, y)]
    return min(
        found,
        key=lambda c: math.hypot(x - center(c)[0], y - center(c)[1]),
        default=None,
    )


def take_screen(device):
    with open(PID_FILE, "w") as pid:
        pid.write(str(os.getpid()))
    subprocess.run(
        ["pkill", "--signal", "USR1", "-f", r"touch-gestures\.py"], check=False
    )
    for _ in range(50):
        try:
            device.grab()
            return
        except OSError:
            time.sleep(0.02)
    sys.exit("gamepad: couldn't take the touchscreen")


def axis(travel, full):
    return max(-32767, min(32767, round(travel / (full * scale()) * 32767)))


def hat_value(dx, dy, radius):
    # Eight directions, by which part of the control the finger is on
    if math.hypot(dx, dy) < radius * HAT_DEAD_ZONE:
        return 0, 0
    angle = math.atan2(dy, dx)
    return round(math.cos(angle) * 1.2), round(math.sin(angle) * 1.2)


def wanted_state():
    # What every finger asks for right now; emit() sends only what changed
    keys, axes = set(clicks), {}
    knobs = {}
    hat_x = hat_y = 0
    for s, pos in slots.items():
        owner = owners.get(s)
        if not owner:
            continue
        x, y = to_px(pos)
        x0, y0 = to_px(start[s])
        kind = owner[1]
        if kind == "stick":
            ax, ay = STICK_AXES[owner[0]]
            axes[ax] = axis(x - x0, STICK_TRAVEL)
            axes[ay] = axis(y - y0, STICK_TRAVEL)
            knobs[owner[0]] = (axes[ax] / 32767, axes[ay] / 32767)
        elif kind == "pad":
            axes[e.ABS_RX] = axis(x - x0, PAD_TRAVEL)
            axes[e.ABS_RY] = axis(y - y0, PAD_TRAVEL)
        elif kind == "hat":
            cx, cy = center(owner)
            hx, hy = hat_value(x - cx, y - cy, owner[6] * scale())
            hat_x, hat_y = hat_x or hx, hat_y or hy
        else:
            # A finger on a button can slide to the next one, as on real ABXY
            now = control_at(x, y, ("button", "trigger"))
            if now:
                owners[s] = owner = now
            if owner[1] == "trigger":
                axes[owner[2]] = 255
            elif owner[1] == "button":
                keys.add(owner[2])
    axes[e.ABS_HAT0X], axes[e.ABS_HAT0Y] = hat_x, hat_y
    return keys, axes, knobs


def emit():
    global sent_keys, sent_axes, knob_at
    keys, axes, knob_at = wanted_state()
    for code in sent_keys - keys:
        pad.write(e.EV_KEY, code, 0)
    for code in keys - sent_keys:
        pad.write(e.EV_KEY, code, 1)
    for code in (
        e.ABS_X,
        e.ABS_Y,
        e.ABS_RX,
        e.ABS_RY,
        e.ABS_Z,
        e.ABS_RZ,
        e.ABS_HAT0X,
        e.ABS_HAT0Y,
    ):
        value = axes.get(code, 0)
        if sent_axes.get(code, 0) != value:
            pad.write(e.EV_ABS, code, value)
            sent_axes[code] = value
    pad.syn()
    sent_keys = keys
    area.queue_draw()


def click_stick(code):
    clicks.add(code)
    emit()

    def done():
        clicks.discard(code)
        emit()
        return GLib.SOURCE_REMOVE

    GLib.timeout_add(int(CLICK_SECONDS * 1000), done)


def finger_down(s):
    x, y = to_px(slots[s])
    owners[s] = control_at(x, y)
    landed[s] = time.monotonic()


def finger_up(s):
    owner = owners.pop(s, None)
    pos, origin = last_pos.pop(s, None), start.pop(s, None)
    held_for = time.monotonic() - landed.pop(s, 0)
    if not owner:
        return
    if owner[1] == "close":
        loop.quit()
    elif owner[1] == "stick" and pos and origin and held_for < TAP_SECONDS:
        x, y, x0, y0 = *to_px(pos), *to_px(origin)
        if math.hypot(x - x0, y - y0) < TAP_TRAVEL:
            click_stick(owner[2])


def on_touch(*_):
    global cur, output, last_output_read
    try:
        events = list(src.read())
    except BlockingIOError:
        return GLib.SOURCE_CONTINUE
    for ev in events:
        if ev.type == e.EV_ABS and ev.code == e.ABS_MT_SLOT:
            cur = ev.value
        elif ev.type == e.EV_ABS and ev.code == e.ABS_MT_TRACKING_ID:
            if ev.value < 0:
                slots.pop(cur, None)
                finger_up(cur)
            else:
                # A position unchanged since this slot's last touch isn't sent again
                slots[cur] = list(slot_pos.get(cur, (0, 0)))
        elif ev.type == e.EV_ABS and ev.code == e.ABS_MT_POSITION_X:
            x_y = slot_pos.setdefault(cur, [0, 0])
            x_y[0] = ev.value
            if cur in slots:
                slots[cur][0] = ev.value
        elif ev.type == e.EV_ABS and ev.code == e.ABS_MT_POSITION_Y:
            x_y = slot_pos.setdefault(cur, [0, 0])
            x_y[1] = ev.value
            if cur in slots:
                slots[cur][1] = ev.value
        elif ev.type == e.EV_SYN and ev.code == e.SYN_REPORT:
            if time.monotonic() - last_output_read > 1:
                last_output_read = time.monotonic()
                try:
                    output = read_output()  # the screen may have turned
                except (OSError, ValueError, subprocess.SubprocessError):
                    pass
            for s, pos in slots.items():
                last_pos[s] = list(pos)
                if s not in start:
                    start[s] = list(pos)
                    finger_down(s)
            emit()
    return GLib.SOURCE_CONTINUE


def load_colours(widget):
    # From the matugen template; the widget's own text colour before one has rendered
    try:
        with open(sys.argv[3]) as f:
            found = json.load(f)
        return {k: Gdk.RGBA() if not (c := Gdk.RGBA()).parse(v) else c for k, v in found.items()}
    except (OSError, ValueError):
        colour = widget.get_color()
        return {"fill": colour, "line": colour, "active": colour, "text": colour}


def paint(cr, colour, alpha):
    cr.set_source_rgba(colour.red, colour.green, colour.blue, alpha)


def control_active(control, keys, axes):
    if control[1] == "button":
        return control[2] in keys
    if control[1] == "trigger":
        return axes.get(control[2], 0) > 0
    return any(owner == control for owner in owners.values())


def draw_shape(cr, control, active):
    cx, cy = center(control)
    s = scale()
    size = control[6]
    if isinstance(size, tuple):
        w, h = size[0] * s, size[1] * s
        cr.new_path()
        cr.arc(cx - w + h, cy, h, math.pi / 2, 3 * math.pi / 2)
        cr.arc(cx + w - h, cy, h, 3 * math.pi / 2, math.pi / 2)
        cr.close_path()
    else:
        cr.new_path()
        cr.arc(cx, cy, size * s, 0, 2 * math.pi)
    paint(cr, colours["active"] if active else colours["fill"], 0.55 if active else 0.25)
    cr.fill_preserve()
    paint(cr, colours["line"], 0.7)
    cr.set_line_width(2)
    cr.stroke()


def draw_label(cr, control):
    cx, cy = center(control)
    cr.select_font_face(sys.argv[2])
    cr.set_font_size(30 * scale())
    extents = cr.text_extents(control[3])
    cr.move_to(cx - extents.width / 2 - extents.x_bearing, cy - extents.height / 2 - extents.y_bearing)
    paint(cr, colours["text"], 0.9)
    cr.show_text(control[3])


def draw_hat(cr, control):
    # Lines between the eight directions' four main arms
    cx, cy = center(control)
    r = control[6] * scale()
    paint(cr, colours["line"], 0.5)
    cr.set_line_width(2)
    for a in range(4):
        angle = math.pi / 4 + a * math.pi / 2
        cr.move_to(cx + math.cos(angle) * r * HAT_DEAD_ZONE, cy + math.sin(angle) * r * HAT_DEAD_ZONE)
        cr.line_to(cx + math.cos(angle) * r, cy + math.sin(angle) * r)
        cr.stroke()


def draw_knob(cr, control):
    cx, cy = center(control)
    r = control[6] * scale()
    kx, ky = knob_at.get(control[0], (0, 0))
    cr.new_path()
    cr.arc(cx + kx * r * 0.5, cy + ky * r * 0.5, r * 0.45, 0, 2 * math.pi)
    paint(cr, colours["line"], 0.5)
    cr.fill()


def on_draw(_area, cr, _w, _h):
    cr.set_operator(cairo.OPERATOR_OVER)
    keys, axes = sent_keys, sent_axes
    for control in CONTROLS:
        draw_shape(cr, control, control_active(control, keys, axes))
        if control[1] == "hat":
            draw_hat(cr, control)
        elif control[1] == "stick":
            draw_knob(cr, control)
        if control[3]:
            draw_label(cr, control)


def stop(*_):
    loop.quit()
    return GLib.SOURCE_REMOVE


def new_overlay():
    window = Gtk.Window(decorated=False)
    LayerShell.init_for_window(window)
    LayerShell.set_namespace(window, "osk-gamepad")
    LayerShell.set_layer(window, LayerShell.Layer.OVERLAY)
    LayerShell.set_exclusive_zone(window, -1)
    LayerShell.set_keyboard_mode(window, LayerShell.KeyboardMode.NONE)
    for edge in (
        LayerShell.Edge.TOP,
        LayerShell.Edge.BOTTOM,
        LayerShell.Edge.LEFT,
        LayerShell.Edge.RIGHT,
    ):
        LayerShell.set_anchor(window, edge, True)
    css = Gtk.CssProvider()
    css.load_from_string("window { background: transparent; }")
    Gtk.StyleContext.add_provider_for_display(
        Gdk.Display.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )
    drawing = Gtk.DrawingArea()
    drawing.set_draw_func(on_draw)
    window.set_child(drawing)
    window.present()
    # An empty input region: touches come from the device, and nothing blocks the game
    window.get_surface().set_input_region(cairo.Region())
    return window, drawing


Gtk.init()
src = evdev.InputDevice(sys.argv[1])
xmax = src.absinfo(e.ABS_X).max
ymax = src.absinfo(e.ABS_Y).max
output = read_output()
last_output_read = time.monotonic()
pad = new_controller()
slots = {}  # slot -> [x, y]
slot_pos = {}  # slot -> its last position, down or not
start = {}  # slot -> position when the touch landed
last_pos = {}  # slot -> latest position, kept for the lift
landed = {}  # slot -> when the touch landed
owners = {}  # slot -> the control it belongs to
clicks = set()  # stick clicks being held for CLICK_SECONDS
sent_keys, sent_axes, knob_at = set(), {}, {}
cur = src.absinfo(e.ABS_MT_SLOT).value

loop = GLib.MainLoop()
overlay, area = new_overlay()
colours = load_colours(area)
take_screen(src)
GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGTERM, stop)
GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGINT, stop)
GLib.io_add_watch(src.fd, GLib.PRIORITY_HIGH, GLib.IO_IN, on_touch)
try:
    loop.run()
finally:
    # Let go of everything, so the game isn't left walking
    for code in sent_keys:
        pad.write(e.EV_KEY, code, 0)
    for code in sent_axes:
        pad.write(e.EV_ABS, code, 0)
    pad.syn()
    pad.close()
    try:
        src.ungrab()
    except OSError:
        pass
