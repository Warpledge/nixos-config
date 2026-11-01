"""omni-face-preview <device>: the IR camera for Omni Settings' Face Auth page.

Writes the latest frame to $XDG_RUNTIME_DIR/omni-settings/ir-preview.jpg and prints
each frame's darkness as a line of JSON. Keeps nothing once it stops.
"""

import ctypes
import json
import os
import signal
import sys
import time

import cv2
import numpy as np

PR_SET_PDEATHSIG = 1
INTERVAL = 0.2  # seconds between frames


def darkness(gray):
    """How Howdy's compare.py measures a frame: the darkest of 8 histogram bins, in percent."""
    hist = cv2.calcHist([gray], [0], None, [8], [0, 256])
    total = np.sum(hist)
    return float(hist[0][0] / total * 100) if total else 100.0


def main(device):
    #--- Stop with Omni Settings, however it ends
    ctypes.CDLL(None).prctl(PR_SET_PDEATHSIG, signal.SIGTERM)
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))

    folder = os.path.join(os.environ["XDG_RUNTIME_DIR"], "omni-settings")
    os.makedirs(folder, mode=0o700, exist_ok=True)
    os.chmod(folder, 0o700)
    frame_path = os.path.join(folder, "ir-preview.jpg")

    camera = cv2.VideoCapture(device, cv2.CAP_V4L2)
    if not camera.isOpened():
        print(json.dumps({"error": f"Couldn't open {device}"}), flush=True)
        return 1
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    try:
        while True:
            ok, frame = camera.read()
            if not ok:
                print(json.dumps({"error": "The camera stopped sending frames"}), flush=True)
                return 1
            gray = clahe.apply(cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY))
            cv2.imwrite(frame_path + ".tmp.jpg", gray)
            os.replace(frame_path + ".tmp.jpg", frame_path)
            print(json.dumps({"darkness": round(darkness(gray), 1)}), flush=True)
            time.sleep(INTERVAL)
    finally:
        camera.release()
        for path in (frame_path, frame_path + ".tmp.jpg"):
            if os.path.exists(path):
                os.remove(path)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
