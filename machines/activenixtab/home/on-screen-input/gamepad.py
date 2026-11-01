"""A touchscreen gamepad: a virtual Xbox 360 controller that Steam Input can remap, drawn on
a see-through overlay that takes no input. While it runs it holds the touchscreen, so
touches reach it and not the game; touch-gestures.py lets go on SIGUSR1 and takes the
screen back once this process is gone. The right pad is a real mouse beside the
controller, which Steam Input can't remap: a virtual Xbox pad has no trackpads.
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

# The settings menu's steps; the first of each is the default
OPACITY = {"Solid": 1.0, "Medium": 0.7, "Faint": 0.45}
STICK_TRAVEL = {"Medium": 60, "Short": 40, "Long": 90}  # logical px for a full stick
MOUSE_SPEED = {"Medium": 1.5, "Slow": 1.0, "Fast": 2.5}  # pointer px per px on the pad
SIZE_LIMITS = (20, 160)  # a control's radius, or half of a pill's width and height
HAT_DEAD_ZONE = 0.25  # share of the D-pad's radius that presses nothing
TAP_SECONDS = 0.2  # a stick touch this short, barely moving, clicks it (L3/R3)
TAP_TRAVEL = 15
CLICK_SECONDS = 0.08
HIT_SLACK = 1.2  # how far outside a control a landing finger still counts

# name, kind, code, label, x, y, radius or (half-width, half-height), in logical px.
# x counts from the left edge, or from the right if negative; y up from the bottom
# Held by the sides: each thumb pivots at the edge, 400 px up, and the controls follow
# its arc, with triggers at the top of the reach and menu buttons at the far end
CONTROLS = [
    ("lt", "trigger", e.ABS_Z, "LT", 70, 650, (55, 24)),
    ("lb", "button", e.BTN_TL, "LB", 190, 650, (55, 24)),
    ("dpad", "hat", None, "", 208, 497, 92),
    ("lstick", "stick", e.BTN_THUMBL, "", 328, 370, 70),
    ("select", "button", e.BTN_SELECT, "Select", 390, 480, (45, 24)),
    ("guide", "button", e.BTN_MODE, "Guide", 390, 540, (45, 24)),
    ("rt", "trigger", e.ABS_RZ, "RT", -70, 650, (55, 24)),
    ("rb", "button", e.BTN_TR, "RB", -190, 650, (55, 24)),
    ("y", "button", e.BTN_Y, "Y", -208, 559, 30),
    ("x", "button", e.BTN_X, "X", -270, 497, 30),
    ("b", "button", e.BTN_B, "B", -146, 497, 30),
    ("a", "button", e.BTN_A, "A", -208, 435, 30),
    ("rstick", "stick", e.BTN_THUMBR, "", -328, 370, 70),
    ("rpad", "mouse", None, "", -197, 262, 80),
    ("start", "button", e.BTN_START, "Start", -390, 480, (45, 24)),
    ("close", "close", None, "✕", -390, 540, (45, 24)),
    ("edit", "settings", None, "Settings", 390, 600, (45, 24)),
]
CONTROLS = [list(c) for c in CONTROLS]  # Moving controls changes x and y
DEFAULTS = {c[0]: (c[4], c[5], c[6]) for c in CONTROLS}
STATE_DIR = os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state"))
LAYOUT_FILE = os.path.join(STATE_DIR, "osk-gamepad-layout.json")

# Labels only: Steam Input and games still see an Xbox pad. Each sits on the button in
# the same place on that controller, so Switch's A is on the right, not the bottom.
# PlayStation's face buttons are shapes, drawn by draw_symbol
STYLES = {
    "Xbox": {},
    "PlayStation": {
        "a": "cross",
        "b": "circle",
        "x": "square",
        "y": "triangle",
        "lb": "L1",
        "rb": "R1",
        "lt": "L2",
        "rt": "R2",
        "select": "Share",
        "start": "Options",
        "guide": "PS",
    },
    "Switch": {
        "a": "B",
        "b": "A",
        "x": "Y",
        "y": "X",
        "lb": "L",
        "rb": "R",
        "lt": "ZL",
        "rt": "ZR",
        "select": "−",
        "start": "+",
        "guide": "Home",
    },
}
MENU_ROW = 90  # logical px between the settings menu's rows
MENU_SIZE = (190, 40)
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


def new_mouse():
    return UInput(
        {e.EV_KEY: [e.BTN_LEFT, e.BTN_RIGHT], e.EV_REL: [e.REL_X, e.REL_Y]},
        name="On-screen gamepad mouse",
    )


def move_mouse():
    moved = False
    for s, pos in slots.items():
        owner = owners.get(s)
        if not owner or owner[1] != "mouse":
            continue
        x, y = to_px(pos)
        px, py, rx, ry = mouse_at.get(s, (x, y, 0.0, 0.0))
        rx += (x - px) * MOUSE_SPEED[settings["mouse"]]
        ry += (y - py) * MOUSE_SPEED[settings["mouse"]]
        if round(rx) or round(ry):
            mouse.write(e.EV_REL, e.REL_X, round(rx))
            mouse.write(e.EV_REL, e.REL_Y, round(ry))
            rx, ry, moved = rx - round(rx), ry - round(ry), True
        mouse_at[s] = (x, y, rx, ry)
    if moved:
        mouse.syn()


def click_mouse():
    mouse.write(e.EV_KEY, e.BTN_LEFT, 1)
    mouse.syn()

    def done():
        mouse.write(e.EV_KEY, e.BTN_LEFT, 0)
        mouse.syn()
        return GLib.SOURCE_REMOVE

    GLib.timeout_add(int(CLICK_SECONDS * 1000), done)


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


def center(control):
    x = control[4] if control[4] >= 0 else output["width"] + control[4]
    return x, output["height"] - control[5]


def shape():
    return "landscape" if output["width"] >= output["height"] else "portrait"


def apply_layout():
    # This shape's saved positions and sizes over the defaults
    saved = layouts.get(shape(), {})
    for control in CONTROLS:
        control[4], control[5], control[6] = DEFAULTS[control[0]]
        entry = saved.get(control[0])
        if entry:
            control[4], control[5] = int(entry[0]), int(entry[1])
            if len(entry) > 2:
                size = entry[2]
                control[6] = tuple(size) if isinstance(size, list) else size


def load_layout():
    try:
        with open(LAYOUT_FILE) as f:
            saved = json.load(f)
        for name, steps in (
            ("style", STYLES),
            ("opacity", OPACITY),
            ("stick", STICK_TRAVEL),
            ("mouse", MOUSE_SPEED),
        ):
            if saved.get(name) in steps:
                settings[name] = saved[name]
        if "landscape" in saved or "portrait" in saved:
            layouts.update({k: saved[k] for k in ("landscape", "portrait") if k in saved})
        else:
            # A file from before each shape had its own layout
            layouts["landscape"] = {c[0]: saved[c[0]] for c in CONTROLS if c[0] in saved}
    except (OSError, ValueError, TypeError, AttributeError):
        pass  # the built-in positions
    apply_layout()


def save_layout():
    layouts[shape()] = {c[0]: [c[4], c[5], c[6]] for c in CONTROLS}
    temp = f"{LAYOUT_FILE}.tmp"
    with open(temp, "w") as f:
        json.dump({**settings, **layouts}, f)
    os.replace(temp, LAYOUT_FILE)


def reset_positions():
    layouts.pop(shape(), None)
    apply_layout()
    save_layout()


def next_step(name, steps):
    names = list(steps)
    settings[name] = names[(names.index(settings[name]) + 1) % len(names)]
    save_layout()


def menu_items():
    # The same shape as CONTROLS, rows centred on the screen
    labels = [
        ("move", "Move controls"),
        ("style", f"Buttons: {settings['style']}"),
        ("opacity", f"Opacity: {settings['opacity']}"),
        ("stick", f"Stick travel: {settings['stick']}"),
        ("mouse", f"Mouse speed: {settings['mouse']}"),
        ("reset", "Tap again to reset" if reset_armed else "Reset positions"),
        ("back", "Close menu"),
    ]
    x = output["width"] // 2
    top = output["height"] // 2 + MENU_ROW * (len(labels) - 1) // 2
    return [
        [name, "menu", None, label, x, top - i * MENU_ROW, MENU_SIZE]
        for i, (name, label) in enumerate(labels)
    ]


def menu_tap(name):
    global mode, reset_armed
    if name == "reset" and not reset_armed:
        reset_armed = True
        return
    reset_armed = False
    if name == "move":
        mode = "move"
    elif name == "style":
        next_step("style", STYLES)
    elif name == "opacity":
        next_step("opacity", OPACITY)
    elif name == "stick":
        next_step("stick", STICK_TRAVEL)
    elif name == "mouse":
        next_step("mouse", MOUSE_SPEED)
    elif name == "reset":
        reset_positions()
    elif name == "back":
        mode = "play"


def scaled(size, factor):
    def one(v):
        return round(min(max(v * factor, SIZE_LIMITS[0]), SIZE_LIMITS[1]))

    return tuple(one(v) for v in size) if isinstance(size, tuple) else one(size)


def finger_gap(a, b):
    ax, ay = to_px(slots[a])
    bx, by = to_px(slots[b])
    return math.hypot(ax - bx, ay - by)


def drag_controls():
    if pinch and pinch["a"] in slots and pinch["b"] in slots:
        # Measured from the pinch's start, so limits don't lose the fingers' place
        factor = finger_gap(pinch["a"], pinch["b"]) / max(pinch["gap"], 1)
        pinch["control"][6] = scaled(pinch["size"], factor)
        return
    # Measured from where the finger landed, so a control doesn't jump to it
    for s, control in owners.items():
        if not control or s not in drag_from or s not in slots:
            continue
        x, y = to_px(slots[s])
        x0, y0 = to_px(start[s])
        cx = min(max(drag_from[s][0] + x - x0, 0), output["width"])
        cy = min(max(drag_from[s][1] + y - y0, 0), output["height"])
        # Counted from the nearer side, so it stays put when the screen turns
        control[4] = round(cx if cx < output["width"] / 2 else cx - output["width"])
        control[5] = round(output["height"] - cy)


def hit(control, x, y):
    cx, cy = center(control)
    size = control[6]
    if isinstance(size, tuple):
        return abs(x - cx) <= size[0] * HIT_SLACK and abs(y - cy) <= size[1] * HIT_SLACK
    return math.hypot(x - cx, y - cy) <= size * HIT_SLACK


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
    return max(-32767, min(32767, round(travel / full * 32767)))


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
    for s, pos in slots.items() if mode == "play" else ():
        owner = owners.get(s)
        if not owner:
            continue
        x, y = to_px(pos)
        x0, y0 = to_px(start[s])
        kind = owner[1]
        if kind == "stick":
            ax, ay = STICK_AXES[owner[0]]
            axes[ax] = axis(x - x0, STICK_TRAVEL[settings["stick"]])
            axes[ay] = axis(y - y0, STICK_TRAVEL[settings["stick"]])
            knobs[owner[0]] = (axes[ax] / 32767, axes[ay] / 32767)
        elif kind == "mouse":
            continue
        elif kind == "hat":
            cx, cy = center(owner)
            hx, hy = hat_value(x - cx, y - cy, owner[6])
            hat_x, hat_y = hat_x or hx, hat_y or hy
        elif kind in ("button", "trigger"):
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
    global pinch
    x, y = to_px(slots[s])
    landed[s] = time.monotonic()
    if mode == "menu":
        owners[s] = next((c for c in menu_items() if hit(c, x, y)), None)
        return
    if mode == "move" and drag_from and not pinch:
        # A second finger anywhere pinches the control the first is holding: most are
        # too small to put two fingers on
        holder = next(iter(drag_from))
        owners[s] = owners[holder]
        pinch = {
            "control": owners[holder],
            "a": holder,
            "b": s,
            "gap": finger_gap(holder, s),
            "size": owners[holder][6],
        }
        return
    owners[s] = control_at(x, y)
    if mode == "move" and owners[s]:
        drag_from[s] = center(owners[s])


def finger_up(s):
    global mode, pinch
    owner = owners.pop(s, None)
    mouse_at.pop(s, None)
    if pinch and s in (pinch["a"], pinch["b"]):
        # The finger left carries on dragging from where it is now
        other = pinch["b"] if s == pinch["a"] else pinch["a"]
        drag_from.pop(s, None)
        if other in slots:
            start[other] = list(slots[other])
            drag_from[other] = center(pinch["control"])
        pinch = None
        last_pos.pop(s, None)
        start.pop(s, None)
        landed.pop(s, None)
        save_layout()
        return
    pos, origin = last_pos.pop(s, None), start.pop(s, None)
    held_for = time.monotonic() - landed.pop(s, 0)
    dragged = drag_from.pop(s, None) is not None
    if not owner:
        return
    tap = False
    if pos and origin:
        x, y, x0, y0 = *to_px(pos), *to_px(origin)
        tap = math.hypot(x - x0, y - y0) < TAP_TRAVEL
    if dragged:
        save_layout()
    if owner[1] == "menu":
        if tap:
            menu_tap(owner[0])
    elif owner[1] == "close" and (tap or mode == "play"):
        loop.quit()
    elif owner[1] == "settings" and tap:
        mode = "play" if mode == "move" else "menu"
    elif tap and held_for < TAP_SECONDS and mode == "play":
        if owner[1] == "stick":
            click_stick(owner[2])
        elif owner[1] == "mouse":
            click_mouse()


def watch_output():
    # On a timer, not on touches: the screen can turn with nothing touching it
    global output
    try:
        before = output
        now = read_output()
    except (OSError, ValueError, subprocess.SubprocessError):
        return GLib.SOURCE_CONTINUE
    if now != before:
        was = shape()
        output = now
        if shape() != was:
            apply_layout()
        area.queue_draw()
    return GLib.SOURCE_CONTINUE


def on_touch(*_):
    global cur
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
            for s, pos in slots.items():
                last_pos[s] = list(pos)
                if s not in start:
                    start[s] = list(pos)
                    finger_down(s)
            if mode == "move":
                drag_controls()
            elif mode == "play":
                move_mouse()
            emit()
    return GLib.SOURCE_CONTINUE


def load_colours(widget):
    # From the matugen template; the widget's own text colour before one has rendered
    try:
        with open(sys.argv[3]) as f:
            found = json.load(f)
        parsed = {}
        for name, value in found.items():
            parsed[name] = Gdk.RGBA()
            parsed[name].parse(value)
        parsed.setdefault("edge", parsed["fill"])  # a file from before "edge" existed
        return parsed
    except (OSError, ValueError, KeyError):
        # Until a theme change renders the file; the inverse keeps the outline two-tone
        colour = widget.get_color()
        edge = Gdk.RGBA()
        edge.red, edge.green, edge.blue = 1 - colour.red, 1 - colour.green, 1 - colour.blue
        edge.alpha = 1
        colours = dict.fromkeys(("line", "active", "text"), colour)
        return {**colours, "fill": edge, "edge": edge}


def paint(cr, colour, alpha):
    cr.set_source_rgba(colour.red, colour.green, colour.blue, alpha)


def two_tone_stroke(cr, alpha=0.9):
    # A light line and a dark one together, so one always shows against the game
    paint(cr, colours["edge"], alpha)
    cr.set_line_width(5)
    cr.stroke_preserve()
    paint(cr, colours["line"], alpha)
    cr.set_line_width(2)
    cr.stroke()


def control_active(control, keys, axes):
    if control[1] == "button":
        return control[2] in keys
    if control[1] == "trigger":
        return axes.get(control[2], 0) > 0
    return any(owner == control for owner in owners.values())


def draw_shape(cr, control, active):
    cx, cy = center(control)
    size = control[6]
    if isinstance(size, tuple):
        w, h = size
        cr.new_path()
        cr.arc(cx - w + h, cy, h, math.pi / 2, 3 * math.pi / 2)
        cr.arc(cx + w - h, cy, h, 3 * math.pi / 2, math.pi / 2)
        cr.close_path()
    else:
        cr.new_path()
        cr.arc(cx, cy, size, 0, 2 * math.pi)
    paint(cr, colours["active"] if active else colours["fill"], 0.55 if active else 0.25)
    cr.fill_preserve()
    two_tone_stroke(cr)


def draw_symbol(cr, name, cx, cy):
    # PlayStation's face buttons
    r = 12
    cr.new_path()
    if name == "circle":
        cr.arc(cx, cy, r, 0, 2 * math.pi)
    elif name == "square":
        cr.rectangle(cx - r, cy - r, 2 * r, 2 * r)
    elif name == "triangle":
        cr.move_to(cx, cy - r)
        cr.line_to(cx + r, cy + r)
        cr.line_to(cx - r, cy + r)
        cr.close_path()
    else:
        cr.move_to(cx - r, cy - r)
        cr.line_to(cx + r, cy + r)
        cr.move_to(cx + r, cy - r)
        cr.line_to(cx - r, cy + r)
    two_tone_stroke(cr)


def label_of(control):
    if control[0] == "edit" and mode == "move":
        return "Done"
    return STYLES[settings["style"]].get(control[0], control[3])


def draw_label(cr, control):
    cx, cy = center(control)
    label = label_of(control)
    if label in ("cross", "circle", "square", "triangle"):
        draw_symbol(cr, label, cx, cy)
        return
    cr.select_font_face(sys.argv[2])
    cr.set_font_size(18)
    extents = cr.text_extents(label)
    cr.move_to(cx - extents.width / 2 - extents.x_bearing, cy - extents.height / 2 - extents.y_bearing)
    cr.text_path(label)
    paint(cr, colours["edge"], 0.9)
    cr.set_line_width(4)
    cr.stroke_preserve()
    paint(cr, colours["text"], 1)
    cr.fill()


def draw_hat(cr, control):
    # Lines between the eight directions' four main arms
    cx, cy = center(control)
    r = control[6]
    for a in range(4):
        angle = math.pi / 4 + a * math.pi / 2
        cr.move_to(cx + math.cos(angle) * r * HAT_DEAD_ZONE, cy + math.sin(angle) * r * HAT_DEAD_ZONE)
        cr.line_to(cx + math.cos(angle) * r, cy + math.sin(angle) * r)
        two_tone_stroke(cr, 0.7)


def draw_knob(cr, control):
    cx, cy = center(control)
    r = control[6]
    kx, ky = knob_at.get(control[0], (0, 0))
    cr.new_path()
    cr.arc(cx + kx * r * 0.5, cy + ky * r * 0.5, r * 0.45, 0, 2 * math.pi)
    paint(cr, colours["line"], 0.35)
    cr.fill_preserve()
    two_tone_stroke(cr, 0.7)


def on_draw(_area, cr, _w, _h):
    cr.set_operator(cairo.OPERATOR_OVER)
    keys, axes = sent_keys, sent_axes
    cr.push_group()
    for control in CONTROLS:
        draw_shape(cr, control, control_active(control, keys, axes))
        if control[1] == "hat":
            draw_hat(cr, control)
        elif control[1] == "stick":
            draw_knob(cr, control)
        if control[3]:
            draw_label(cr, control)
    cr.pop_group_to_source()
    cr.paint_with_alpha(OPACITY[settings["opacity"]])
    if mode == "menu":
        for item in menu_items():
            active = any(owner and owner[0] == item[0] for owner in owners.values())
            draw_shape(cr, item, active)
            draw_label(cr, item)


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
settings = {"style": "Xbox", "opacity": "Solid", "stick": "Medium", "mouse": "Medium"}
layouts = {}  # "landscape" or "portrait" -> control name -> [x, y, size]
pinch = None  # two fingers resizing a control in Move controls
reset_armed = False  # the first tap on Reset positions only asks for a second
load_layout()
mode = "play"  # or "menu", or "move", where a drag moves a control; only play sends input
drag_from = {}  # slot -> the center of the control it's moving, when it landed
pad = new_controller()
mouse = new_mouse()
mouse_at = {}  # slot -> last x, y and the fractions of a pointer step left over
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
GLib.timeout_add(1000, watch_output)
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
    mouse.close()
    try:
        src.ungrab()
    except OSError:
        pass
