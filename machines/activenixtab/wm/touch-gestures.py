#!/usr/bin/env python3
# Three-finger drags on the touchscreen become touchpad swipes, so niri scrolls
# columns and workspaces under the fingers. Fewer fingers pass through untouched.
# It also holds the touchpad while ~/.config/niri/touchpad-off isn't empty.
# Usage: touch-gestures <touchscreen event device>
import json
import os
import select
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


def transform():
    try:
        out = subprocess.run(
            ["niri", "msg", "--json", "focused-output"],
            capture_output=True,
            text=True,
            timeout=1,
        )
        return json.loads(out.stdout)["logical"]["transform"]
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
        timeout = 0.5
        if mode == "hold":
            timeout = max(0.0, hold_start + HOLD - time.monotonic())
        r, _, _ = select.select([src.fd], [], [], timeout)
        if not r and mode != "hold":
            continue
        if not r:
            # Held long enough with fewer than three fingers: hand it to the app
            flush()
            mode = "pass"
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
                if slots:
                    mode, hold_start, held = "hold", time.monotonic(), []
                else:
                    forward(done, fslot)
                    continue
            if mode == "hold":
                held.append((done, fslot))
                if len(slots) >= 3:
                    held = []
                    begin_gesture()
                elif not slots or moved():
                    flush()
                    mode = "pass" if slots else "idle"
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
