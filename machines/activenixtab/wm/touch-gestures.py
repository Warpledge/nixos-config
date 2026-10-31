#!/usr/bin/env python3
# Three-finger drags on the touchscreen become touchpad swipes, so niri scrolls
# columns and workspaces under the fingers. Fewer fingers pass through untouched.
# It also holds the touchpad while ~/.config/niri/touchpad-off isn't empty, and
# runs the optional command on a one-finger swipe up from the bottom edge.
# SIGUSR2 (osk-pad-mode) switches pad mode: touches outside the bar and the
# on-screen keyboard drive a virtual touchpad instead of the screen.
# Usage: touch-gestures <touchscreen event device> [command...]
import json
import os
import select
import signal
import subprocess
import sys
import time

import evdev
from evdev import AbsInfo, UInput
from evdev import ecodes as e

# How long a first touch is held back to see whether more fingers land
HOLD = 0.09
# Movement (device units) that commits a held-back touch to the app under it
MOVE = 40
# Edge swipe, as fractions of the screen: where it starts and how far it rises.
# A touch on the edge is held back up to EDGE_HOLD seconds to see if it rises.
EDGE = 0.03
EDGE_RISE = 0.05
EDGE_HOLD = 0.4
# Strips pad mode leaves alone (logical px); the keyboard's only while it's shown.
# KEYBOARD_STRIP matches `height` in home/on-screen-input/default.nix
BAR_STRIP = 36
KEYBOARD_STRIP = 390
edge_command = sys.argv[2:]

src = evdev.InputDevice(sys.argv[1])
caps = src.capabilities(absinfo=True)
caps.pop(e.EV_SYN, None)
ax = dict(caps[e.EV_ABS])
xmax, ymax = ax[e.ABS_X].max, ax[e.ABS_Y].max

# The touchscreen apps see while this runs
screen = UInput(
    caps,
    name=f"{src.name} (touch-gestures)",
    input_props=[e.INPUT_PROP_DIRECT],
)

# niri moves a working-area width per 1200 swipe units and a workspace per 300.
# libinput gives 1000 units per inch on a touchpad, slowed by SLOW (measured).
# One resolution for both axes keeps libinput's start-up dead zone small; the
# per-axis gains in begin_gesture() make the content follow the fingers.
SLOW = 0.235
PAD = 16383
RES = max(1, round(39.37 * SLOW * xmax / 1200))
UNIT = 39.37 * SLOW / RES  # swipe units per pad unit
pad = UInput(
    {
        e.EV_KEY: [
            e.BTN_LEFT,
            e.BTN_TOUCH,
            e.BTN_TOOL_FINGER,
            e.BTN_TOOL_DOUBLETAP,
            e.BTN_TOOL_TRIPLETAP,
            e.BTN_TOOL_QUADTAP,
        ],
        e.EV_ABS: [
            (e.ABS_X, AbsInfo(0, 0, PAD, 0, 0, RES)),
            (e.ABS_Y, AbsInfo(0, 0, PAD, 0, 0, RES)),
            (e.ABS_MT_SLOT, AbsInfo(0, 0, 3, 0, 0, 0)),
            (e.ABS_MT_TRACKING_ID, AbsInfo(0, 0, 65535, 0, 0, 0)),
            (e.ABS_MT_POSITION_X, AbsInfo(0, 0, PAD, 0, 0, RES)),
            (e.ABS_MT_POSITION_Y, AbsInfo(0, 0, PAD, 0, 0, RES)),
        ],
    },
    name="Touchscreen gestures",
    input_props=[e.INPUT_PROP_POINTER, e.INPUT_PROP_BUTTONPAD],
)
TOOLS = [e.BTN_TOOL_FINGER, e.BTN_TOOL_DOUBLETAP, e.BTN_TOOL_TRIPLETAP]
TOOLS.append(e.BTN_TOOL_QUADTAP)

# Pad mode's touchpad, at the panel's own resolution so a finger moves it its
# real distance. Large enough that a drag from its middle never hits an edge.
TP_RES = ax[e.ABS_X].resolution
TP_YGAIN = TP_RES / ax[e.ABS_Y].resolution
TP_MID = 2 * round(max(xmax, ymax * TP_YGAIN))
tp = UInput(
    {
        e.EV_KEY: [
            e.BTN_LEFT,
            e.BTN_RIGHT,
            e.BTN_TOUCH,
            e.BTN_TOOL_FINGER,
            e.BTN_TOOL_DOUBLETAP,
        ],
        e.EV_ABS: [
            (e.ABS_X, AbsInfo(0, 0, 2 * TP_MID, 0, 0, TP_RES)),
            (e.ABS_Y, AbsInfo(0, 0, 2 * TP_MID, 0, 0, TP_RES)),
            (e.ABS_MT_SLOT, AbsInfo(0, 0, 1, 0, 0, 0)),
            (e.ABS_MT_TRACKING_ID, AbsInfo(0, 0, 65535, 0, 0, 0)),
            (e.ABS_MT_POSITION_X, AbsInfo(0, 0, 2 * TP_MID, 0, 0, TP_RES)),
            (e.ABS_MT_POSITION_Y, AbsInfo(0, 0, 2 * TP_MID, 0, 0, TP_RES)),
        ],
    },
    name="On-screen touchpad",
    input_props=[e.INPUT_PROP_POINTER],
)


def niri_msg(what):
    out = subprocess.run(
        ["niri", "msg", "--json", what],
        capture_output=True,
        text=True,
        timeout=1,
    )
    return json.loads(out.stdout)


def transform():
    try:
        return niri_msg("focused-output")["logical"]["transform"]
    except Exception:
        return "Normal"


def rotate(dx, dy, t):
    # Panel deltas to screen deltas, as niri turns touch points for the output
    return {
        "_90": (-dy, dx),
        "_180": (-dx, -dy),
        "_270": (dy, -dx),
    }.get(t, (dx, dy))


slots = {}  # slot -> [x, y]
cur = 0
mode = "idle"  # idle | hold | pass | gesture | drain
held = []  # frames held back in "hold"
hold_start = 0.0
start = {}  # slot -> position when the touch landed
g = {}  # gesture state
edge = False  # the held touch landed on the bottom edge
edge_t = "Normal"  # the screen's transform when it did
pad_on = False
pad_flip = False  # set by SIGUSR2, acted on between frames
to_pad = False  # the held touch belongs to the virtual touchpad
peak = {}  # slot -> position, every finger down during the hold
tp_t = "Normal"  # the screen's transform for this pad touch
tp_fingers = {}  # source slot -> (pad slot, anchor x, anchor y)
tp_next_id = 0


def on_pad_flip(*_):
    global pad_flip
    pad_flip = True


signal.signal(signal.SIGUSR2, on_pad_flip)


screen_cache = (0.0, None)  # (when it was read, (logical output, keyboard shown))


def screen_state():
    # Cached briefly so a burst of key taps doesn't wait on niri each time
    global screen_cache
    now = time.monotonic()
    if now - screen_cache[0] > 0.5:
        try:
            logical = niri_msg("focused-output")["logical"]
            shown = any(s["namespace"] == "wvkbd" for s in niri_msg("layers"))
            screen_cache = (now, (logical, shown))
        except Exception:
            screen_cache = (now, None)
    return screen_cache[1]


def on_keyboard(pos):
    state = screen_state()
    if not state or not state[1]:
        return False
    logical = state[0]
    y = on_screen(pos, logical["transform"])[1] * logical["height"]
    return y >= logical["height"] - KEYBOARD_STRIP


def in_pad_area(pos):
    # Whether a touch landing here drives the touchpad, and the transform to use
    global tp_t
    state = screen_state()
    if not state:
        return False  # can't tell where the strips are: leave the screen working
    logical, shown = state
    tp_t = logical["transform"]
    y = on_screen(pos, tp_t)[1] * logical["height"]
    bottom = logical["height"] - (KEYBOARD_STRIP if shown else 0)
    return BAR_STRIP <= y < bottom


def tp_offset(dx, dy):
    return rotate(dx, dy * TP_YGAIN, tp_t)


def tp_frame(live):
    # Fingers in `live` (slot -> position) move the pad relative to where they
    # landed; later fingers keep their distance from the first for libinput
    global tp_next_id
    for s in [s for s in tp_fingers if s not in live]:
        tp.write(e.EV_ABS, e.ABS_MT_SLOT, tp_fingers.pop(s)[0])
        tp.write(e.EV_ABS, e.ABS_MT_TRACKING_ID, -1)
    for s, pos in live.items():
        origin = start.get(s, pos)
        if s not in tp_fingers:
            free = {0, 1} - {f[0] for f in tp_fingers.values()}
            if not free:
                continue
            ox, oy = TP_MID, TP_MID
            if tp_fingers:
                first, (_, ax0, ay0) = next(iter(tp_fingers.items()))
                dx, dy = tp_offset(
                    origin[0] - start.get(first, live[first])[0],
                    origin[1] - start.get(first, live[first])[1],
                )
                ox, oy = ax0 + dx, ay0 + dy
            tp_fingers[s] = (min(free), ox, oy)
            tp.write(e.EV_ABS, e.ABS_MT_SLOT, min(free))
            tp.write(e.EV_ABS, e.ABS_MT_TRACKING_ID, tp_next_id)
            tp_next_id = (tp_next_id + 1) % 65535
        slot, ox, oy = tp_fingers[s]
        dx, dy = tp_offset(pos[0] - origin[0], pos[1] - origin[1])
        x = min(max(round(ox + dx), 0), 2 * TP_MID)
        y = min(max(round(oy + dy), 0), 2 * TP_MID)
        tp.write(e.EV_ABS, e.ABS_MT_SLOT, slot)
        tp.write(e.EV_ABS, e.ABS_MT_POSITION_X, x)
        tp.write(e.EV_ABS, e.ABS_MT_POSITION_Y, y)
        if slot == min(f[0] for f in tp_fingers.values()):
            tp.write(e.EV_ABS, e.ABS_X, x)
            tp.write(e.EV_ABS, e.ABS_Y, y)
    n = len(tp_fingers)
    tp.write(e.EV_KEY, e.BTN_TOUCH, 1 if n else 0)
    tp.write(e.EV_KEY, e.BTN_TOOL_FINGER, 1 if n == 1 else 0)
    tp.write(e.EV_KEY, e.BTN_TOOL_DOUBLETAP, 1 if n == 2 else 0)
    tp.syn()


def let_go():
    # The hold is over with fewer than three fingers: give the touch to its owner
    global mode, held
    if not to_pad:
        flush()
        mode = "pass" if slots else "idle"
        return
    held = []
    if slots:
        mode = "pad"
        tp_frame(slots)
    else:
        # A tap shorter than the hold: replay it, it's all libinput needs
        mode = "idle"
        tp_frame(peak)
        tp_frame({})


def forward(frame, slot):
    screen.write(e.EV_ABS, e.ABS_MT_SLOT, slot)
    for ev in frame:
        screen.write(ev.type, ev.code, ev.value)
    screen.syn()


def flush():
    global held
    for frame, slot in held:
        forward(frame, slot)
    held = []


def lift_screen(active):
    for s in active:
        screen.write(e.EV_ABS, e.ABS_MT_SLOT, s)
        screen.write(e.EV_ABS, e.ABS_MT_TRACKING_ID, -1)
    screen.write(e.EV_KEY, e.BTN_TOUCH, 0)
    screen.syn()


def pad_frame(lift=False):
    fingers = sorted(slots)[:3]
    n = 0 if lift else len(fingers)
    for i in range(4):
        pad.write(e.EV_ABS, e.ABS_MT_SLOT, i)
        if i < n:
            s = fingers[i]
            if i not in g["down"]:
                pad.write(e.EV_ABS, e.ABS_MT_TRACKING_ID, g["next_id"])
                g["next_id"] = (g["next_id"] + 1) % 65535
                g["down"].add(i)
            sx, sy = start.get(s, slots[s])
            dx, dy = rotate(slots[s][0] - sx, slots[s][1] - sy, g["t"])
            x = min(max(round(g["anchor"][i][0] + dx * g["gx"]), 0), PAD)
            y = min(max(round(g["anchor"][i][1] + dy * g["gy"]), 0), PAD)
            pad.write(e.EV_ABS, e.ABS_MT_POSITION_X, x)
            pad.write(e.EV_ABS, e.ABS_MT_POSITION_Y, y)
            if i == 0:
                pad.write(e.EV_ABS, e.ABS_X, x)
                pad.write(e.EV_ABS, e.ABS_Y, y)
        elif i in g["down"]:
            pad.write(e.EV_ABS, e.ABS_MT_TRACKING_ID, -1)
            g["down"].discard(i)
    pad.write(e.EV_KEY, e.BTN_TOUCH, 1 if n else 0)
    for k, tool in enumerate(TOOLS):
        pad.write(e.EV_KEY, tool, 1 if n == k + 1 else 0)
    pad.syn()


def begin_gesture():
    global mode, g
    mode = "gesture"
    t = transform()
    # Screen width and height in panel units, as turned
    w, h = (ymax, xmax) if t in ("_90", "_270") else (xmax, ymax)
    fingers = sorted(slots)[:3]
    x0, y0 = start.get(fingers[0], slots[fingers[0]])
    anchor = []
    for s in fingers:
        x, y = start.get(s, slots[s])
        anchor.append((PAD // 2 + x - x0, PAD // 2 + y - y0))
    g = {
        "t": t,
        "gx": 1200 / w / UNIT,
        "gy": 300 / h / UNIT,
        "anchor": anchor,
        "down": set(),
        "next_id": 1,
    }
    pad_frame()


def on_screen(pos, t):
    # Panel position to where it is on the turned screen, 0-1 on each axis
    nx, ny = pos[0] / xmax, pos[1] / ymax
    return {
        "_90": (1 - ny, nx),
        "_180": (1 - nx, 1 - ny),
        "_270": (ny, 1 - nx),
    }.get(t, (nx, ny))


def rise():
    # (up, sideways) since the touch landed, for the one finger down
    s = next(iter(slots))
    if s not in start:
        return 0.0, 0.0
    x0, y0 = on_screen(start[s], edge_t)
    x1, y1 = on_screen(slots[s], edge_t)
    return y0 - y1, abs(x1 - x0)


def moved():
    return any(
        abs(slots[s][0] - start[s][0]) + abs(slots[s][1] - start[s][1]) > MOVE
        for s in slots
        if s in start
    )


TOUCHPAD_OFF = os.path.expanduser("~/.config/niri/touchpad-off")
touchpad = None  # the grabbed touchpad while it's switched off
last_scan = 0.0


def touchpad_switch():
    # A grabbed device sends nothing to niri; the folio can come and go
    global touchpad, last_scan
    try:
        off = os.path.getsize(TOUCHPAD_OFF) > 0
    except OSError:
        off = False
    if touchpad and (not off or not os.path.exists(touchpad.path)):
        try:
            touchpad.close()
        except OSError:
            pass
        touchpad = None
    if off and not touchpad and time.monotonic() - last_scan > 2:
        last_scan = time.monotonic()
        for path in evdev.list_devices():
            dev = evdev.InputDevice(path)
            if dev.name.endswith("Touchpad") and dev.path != pad.device.path:
                try:
                    dev.grab()
                    touchpad = dev
                    break
                except OSError:
                    pass
            dev.close()


src.grab()
frame = []
frame_slot = cur
try:
    while True:
        touchpad_switch()
        if pad_flip:
            pad_flip = False
            pad_on = not pad_on
            if mode == "pad":
                tp_frame({})
                mode = "drain" if slots else "idle"
        timeout = 0.5
        if mode == "hold":
            wait = EDGE_HOLD if edge else HOLD
            timeout = max(0.0, hold_start + wait - time.monotonic())
        r, _, _ = select.select([src.fd], [], [], timeout)
        if not r and mode != "hold":
            continue
        if not r:
            # Held long enough with fewer than three fingers: hand it on
            let_go()
            continue
        for ev in src.read():
            if ev.type == e.EV_ABS and ev.code == e.ABS_MT_SLOT:
                cur = ev.value
            elif ev.type == e.EV_ABS and ev.code == e.ABS_MT_TRACKING_ID:
                if ev.value < 0:
                    slots.pop(cur, None)
                    start.pop(cur, None)
                else:
                    slots[cur] = [0, 0]
                    start.pop(cur, None)
            elif ev.type == e.EV_ABS and ev.code == e.ABS_MT_POSITION_X:
                if cur in slots:
                    slots[cur][0] = ev.value
            elif ev.type == e.EV_ABS and ev.code == e.ABS_MT_POSITION_Y:
                if cur in slots:
                    slots[cur][1] = ev.value
            if ev.type != e.EV_SYN:
                frame.append(ev)
                continue
            if ev.code != e.SYN_REPORT:
                continue

            for s, pos in slots.items():
                start.setdefault(s, list(pos))
            done, frame = frame, []
            fslot, frame_slot = frame_slot, cur

            if mode == "idle":
                if slots and on_keyboard(next(iter(slots.values()))):
                    # Keys need every finger, at once: no hold and no gesture
                    mode = "keys"
                    forward(done, fslot)
                    continue
                if slots:
                    mode, hold_start, held = "hold", time.monotonic(), []
                    edge = False
                    pos = next(iter(slots.values()))
                    if edge_command and len(slots) == 1:
                        edge_t = transform()
                        edge = on_screen(pos, edge_t)[1] > 1 - EDGE
                    to_pad = pad_on and in_pad_area(pos)
                    peak = {}
                else:
                    forward(done, fslot)
                    continue
            if mode == "hold":
                held.append((done, fslot))
                peak.update({s: list(pos) for s, pos in slots.items()})
                up, side = rise() if edge and len(slots) == 1 else (0.0, 0.0)
                if len(slots) >= 3:
                    held = []
                    begin_gesture()
                elif up >= EDGE_RISE:
                    held = []
                    subprocess.Popen(edge_command)
                    mode = "drain"
                elif not slots or (moved() and not (edge and up > side)):
                    let_go()
            elif mode == "keys":
                forward(done, fslot)
                if not slots:
                    mode = "idle"
            elif mode == "pad":
                if len(slots) >= 3:
                    tp_frame({})
                    begin_gesture()
                else:
                    tp_frame(slots)
                    if not slots:
                        mode = "idle"
            elif mode == "pass":
                if len(slots) >= 3:
                    lift_screen([s for s in slots if s in start])
                    begin_gesture()
                else:
                    forward(done, fslot)
                    if not slots:
                        mode = "idle"
            elif mode == "gesture":
                if len(slots) >= 3:
                    pad_frame()
                else:
                    # End the swipe before libinput turns it into a scroll
                    pad_frame(lift=True)
                    mode = "drain" if slots else "idle"
            elif mode == "drain" and not slots:
                mode = "idle"
finally:
    src.ungrab()
