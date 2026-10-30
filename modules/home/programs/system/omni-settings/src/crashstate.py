"""The Gaming tab's Crashes page and each game's crashes in its editor: the
user's crashes from systemd-coredump's journal entries, a crash tied to a Steam
game when its command line runs from that game's folder, and a report to copy
for troubleshooting (coredumpctl info, the game's launch options and its
Proton log)."""

import datetime
import json
import os
import re
import subprocess

import steamstate

COREDUMP = "fc2e22bc6ee647b6b90729ab34a250b1"  # systemd-coredump's MESSAGE_ID
FIELDS = "COREDUMP_PID,COREDUMP_EXE,COREDUMP_COMM,COREDUMP_CMDLINE,COREDUMP_SIGNAL_NAME,COREDUMP_TIMESTAMP"
WINE = re.compile(r"wine|\.exe\b", re.IGNORECASE)
LOG_LINES = 200


def text(value):
    """A journal field, which comes as a list of bytes when it isn't plain text."""
    if isinstance(value, list):
        return bytes(value).decode(errors="replace")
    return value or ""


def journal(days):
    try:
        out = subprocess.run(["journalctl", f"MESSAGE_ID={COREDUMP}", f"COREDUMP_UID={os.getuid()}",
                              f"--since=-{days}d", "-o", "json", f"--output-fields={FIELDS}",
                              "--no-pager"], capture_output=True, text=True, timeout=20).stdout
    except (OSError, subprocess.TimeoutExpired):
        return []
    entries = []
    for line in out.splitlines():
        try:
            entries.append(json.loads(line))
        except ValueError:
            continue
    return entries


def crashes(days=30, app=None):
    """[{pid, time, name, signal, exe, app, game}], games first, newest first."""
    folders = {}
    for g in steamstate.games():
        folders[os.path.basename(g["dir"]).lower()] = g
    out = []
    for e in journal(days):
        exe, cmdline = text(e.get("COREDUMP_EXE")), text(e.get("COREDUMP_CMDLINE"))
        where = (cmdline + " " + exe).replace("\\\\", "/").replace("\\", "/").lower()
        game = None
        for m in re.finditer(r"steamapps/common/([^/]+)", where):
            game = folders.get(m.group(1))
            if game:
                break
        if app and (not game or game["id"] != app):
            continue
        stamp = int(text(e.get("COREDUMP_TIMESTAMP")) or 0) // 1_000_000
        # A Wine process is named after the .exe it ran, not wine-preloader
        windows = re.findall(r"([^/\s'$]+\.exe)\b", where)
        name = text(e.get("COREDUMP_COMM")) or os.path.basename(exe)
        out.append({"pid": text(e.get("COREDUMP_PID")), "time": stamp,
                    "when": datetime.datetime.fromtimestamp(stamp).strftime("%a %d %b, %H:%M"),
                    "name": game["name"] if game else windows[-1] if windows else name,
                    "signal": text(e.get("COREDUMP_SIGNAL_NAME")), "exe": exe,
                    "app": game["id"] if game else "", "game": bool(game) or bool(WINE.search(where))})
    return sorted(out, key=lambda c: (not c["game"], -c["time"]))[:100]


def report(pid, app, launch):
    """The text Copy for Troubleshooting puts on the clipboard."""
    parts = []
    try:
        info = subprocess.run(["coredumpctl", "info", str(int(pid)), "--no-pager"],
                              capture_output=True, text=True, timeout=30).stdout
    except (OSError, ValueError, subprocess.TimeoutExpired):
        info = ""
    parts.append(info.strip() or f"coredumpctl has nothing for PID {pid}")
    if app:
        steam = steamstate.current().get(app, {})
        parts.append(f"Launch options: {launch or steam.get('launchOptions') or '(none)'}\n"
                     f"Proton: {steam.get('proton') or 'Steam default'}")
        log = os.path.expanduser(f"~/steam-{app}.log")
        try:
            with open(log, errors="replace") as f:
                lines = f.readlines()[-LOG_LINES:]
            parts.append(f"Last {len(lines)} lines of {log}:\n" + "".join(lines).rstrip())
        except OSError:
            parts.append(f"No Proton log: add PROTON_LOG=1 to the launch options to get {log}")
    return "\n\n".join(parts)
