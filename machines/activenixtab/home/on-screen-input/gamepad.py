"""A touchscreen gamepad: a virtual Xbox 360 controller that Steam Input can remap. While
it runs it holds the touchscreen, so touches reach it and not the game; touch-gestures.py
lets go on SIGUSR1 and takes the screen back once this process is gone. For now the left
half is the left stick, the right half the right stick, and the top right corner closes.
Usage: gamepad <touchscreen event device>"""

import json
import os
import signal
import subprocess
import sys
import time

import evdev
from evdev import AbsInfo, UInput
from evdev import ecodes as e

STICK_RADIUS = 90  # logical px of finger travel for a full stick
CLOSE_CORNER = 0.12  # share of the screen's width and height

RUNTIME_DIR = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
PID_FILE = os.path.join(RUNTIME_DIR, "osk-gamepad.pid")


def new_controller():
    stick = AbsInfo(0, -32768, 32767, 16, 128, 0)
    trigger = AbsInfo(0, 0, 255, 0, 0, 0)
    hat = AbsInfo(0, -1, 1, 0, 0, 0)
    return UInput(
        {
            e.EV_KEY: [
                e.BTN_A,
                e.BTN_B,
                e.BTN_X,
                e.BTN_Y,
                e.BTN_TL,
                e.BTN_TR,
                e.BTN_SELECT,
                e.BTN_START,
                e.BTN_MODE,
                e.BTN_THUMBL,
                e.BTN_THUMBR,
            ],
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


def logical_output():
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


def axis(travel):
    return max(-32767, min(32767, round(travel / STICK_RADIUS * 32767)))


def sticks_frame():
    # The newest finger on each side drives its stick, measured from where it landed
    values = {e.ABS_X: 0, e.ABS_Y: 0, e.ABS_RX: 0, e.ABS_RY: 0}
    for s, pos in slots.items():
        x, y = on_screen(pos, output["transform"])
        x0, y0 = on_screen(start[s], output["transform"])
        codes = (e.ABS_X, e.ABS_Y) if x0 < 0.5 else (e.ABS_RX, e.ABS_RY)
        values[codes[0]] = axis((x - x0) * output["width"])
        values[codes[1]] = axis((y - y0) * output["height"])
    for code, value in values.items():
        pad.write(e.EV_ABS, code, value)
    pad.syn()


def closes(pos):
    x, y = on_screen(pos, output["transform"])
    return x > 1 - CLOSE_CORNER and y < CLOSE_CORNER


def stop(*_):
    sys.exit(0)


signal.signal(signal.SIGTERM, stop)
signal.signal(signal.SIGINT, stop)

src = evdev.InputDevice(sys.argv[1])
xmax = src.absinfo(e.ABS_X).max
ymax = src.absinfo(e.ABS_Y).max
output = logical_output()
pad = new_controller()
slots = {}  # slot -> [x, y]
start = {}  # slot -> position when the touch landed
closing = set()  # fingers that landed on the close corner
cur = src.absinfo(e.ABS_MT_SLOT).value
last_output_read = time.monotonic()

take_screen(src)
try:
    for ev in src.read_loop():
        if ev.type == e.EV_ABS and ev.code == e.ABS_MT_SLOT:
            cur = ev.value
        elif ev.type == e.EV_ABS and ev.code == e.ABS_MT_TRACKING_ID:
            if ev.value < 0:
                slots.pop(cur, None)
                start.pop(cur, None)
                if cur in closing:
                    sys.exit(0)
            else:
                slots[cur] = None
        elif ev.type == e.EV_ABS and ev.code == e.ABS_MT_POSITION_X:
            if cur in slots:
                slots[cur] = [ev.value, (slots[cur] or [0, 0])[1]]
        elif ev.type == e.EV_ABS and ev.code == e.ABS_MT_POSITION_Y:
            if cur in slots:
                slots[cur] = [(slots[cur] or [0, 0])[0], ev.value]
        elif ev.type == e.EV_SYN and ev.code == e.SYN_REPORT:
            if time.monotonic() - last_output_read > 1:
                output = logical_output()  # the screen may have turned
                last_output_read = time.monotonic()
            for s in [s for s, pos in slots.items() if pos is None]:
                del slots[s]
            for s, pos in slots.items():
                if s not in start:
                    start[s] = list(pos)
                    if closes(pos):
                        closing.add(s)
            sticks_frame()
finally:
    # Let go of everything, so the game isn't left walking
    for code in (e.ABS_X, e.ABS_Y, e.ABS_RX, e.ABS_RY):
        pad.write(e.EV_ABS, code, 0)
    pad.syn()
    pad.close()
    try:
        src.ungrab()
    except OSError:
        pass
