"""omni-server-backend: what the QML calls. One JSON reply per command; `--serve` answers
Backend.qml's JSON lines on stdin from forked children, as Omni Settings' api.py does.
`watch` is the long-running one: it streams a server's state and console on stderr."""

import json
import os
import select
import selectors
import shutil
import socket
import subprocess
import sys
import time

import addons
import backups
import history
import logparse
import mods
import players
import properties
import servers

COMMANDS = {}
WATCH_STATUS = 2
QUERY_WAIT = 12
QUICK_ICONS = ("bolt", "save", "campaign", "archive", "schedule", "speed", "group", "light_mode",
               "cloud_off", "restart_alt", "terminal", "star", "shield", "swords", "park", "bedtime")


def command(fn):
    COMMANDS[fn.__name__] = fn
    return fn


def require(args):
    return servers.load(args.get("id"))


#--------------------------------------------------------------------#
#-- Servers
#--------------------------------------------------------------------#


def summary(cfg):
    status = servers.status_of(cfg)
    values = properties.read(servers.props_file(cfg))
    return {
        "id": cfg["id"], "name": cfg["name"], "dir": cfg["dir"], "kind": cfg["kind"], "label": cfg["label"],
        "java": cfg["java"], "port": values.get("server-port", "25565"), "status": status,
        "tag": "".join(w[0] for w in cfg["name"].split()[:3] if w).upper()[:3] or "MC",
    }


@command
def servers_list(_args):
    return {"servers": [summary(c) for c in servers.all_servers()]}


@command
def pick_folder(_args):
    try:
        res = subprocess.run(["zenity", "--file-selection", "--directory", "--title=Choose the server's folder"],
                             capture_output=True, text=True, check=False)
    except OSError as e:
        raise servers.ServerError(f"Couldn't open the folder picker: {e}") from e
    return {"folder": res.stdout.strip() if res.returncode == 0 else ""}


@command
def add(args):
    return {"server": summary(servers.add(args.get("dir", ""), args.get("name")))}


@command
def remove(args):
    servers.remove(args.get("id"))
    return {}


@command
def rename(args):
    cfg = require(args)
    name = str(args.get("name", "")).strip()
    if not name:
        raise servers.ServerError("Enter a name")
    cfg["name"] = name
    servers.save(cfg)
    return {"server": summary(cfg)}


@command
def start(args):
    servers.start(require(args))
    return {}


@command
def stop(args):
    servers.stop(require(args))
    return {}


@command
def restart(args):
    servers.restart(require(args))
    return {}


@command
def kill(args):
    servers.kill(require(args))
    return {}


@command
def send(args):
    servers.send(require(args), args.get("text", ""))
    return {}


#--------------------------------------------------------------------#
#-- Live state
#--------------------------------------------------------------------#


def emit(message):
    print(json.dumps(message), file=sys.stderr, flush=True)


def past_console(server_id):
    """The last run's console, for a server that's stopped."""
    base = f"{servers.state_dir(server_id)}/console.log"
    file = base if os.path.exists(base) else f"{base}.1"
    try:
        with open(file, "rb") as f:
            f.seek(0, os.SEEK_END)
            f.seek(max(0, f.tell() - 262144))
            lines = f.read().decode("utf-8", errors="replace").splitlines()[-1000:]
    except OSError:
        return []
    return [logparse.parse_line(line) for line in lines]


def connect_monitor(server_id):
    sock = socket.socket(socket.AF_UNIX)
    try:
        sock.connect(servers.monitor_socket(server_id))
    except OSError:
        sock.close()
        return None
    return sock


def watch(args):
    """Stream until killed: {"type": "status"} from systemd, and the monitor's own "hello",
    "state" and "lines" while one is up. A stopped server gets its last console once."""
    cfg = require(args)
    selector = selectors.DefaultSelector()
    sock, pending, gave_past, next_status = None, b"", False, 0
    while True:
        now = time.time()
        if now >= next_status:
            next_status = now + WATCH_STATUS
            emit({"type": "status", "status": servers.status_of(cfg), "pending": servers.pending_properties(cfg["id"])})
            if not sock:
                sock = connect_monitor(cfg["id"])
                if sock:
                    selector.register(sock, selectors.EVENT_READ)
                elif not gave_past:
                    gave_past = True
                    emit({"type": "past", "lines": past_console(cfg["id"])})
        if not sock:
            time.sleep(0.25)
            continue
        if not selector.select(0.25):
            continue
        chunk = sock.recv(1 << 20)
        if not chunk:
            selector.unregister(sock)
            sock.close()
            sock, pending, gave_past = None, b"", True
            emit({"type": "gone"})
            continue
        *lines, pending = (pending + chunk).split(b"\n")
        for line in lines:
            sys.stderr.buffer.write(line + b"\n")
        sys.stderr.buffer.flush()


@command
def series(args):
    cfg = require(args)
    file = f"{servers.state_dir(cfg['id'])}/history.db"
    return {"points": history.series(file, args.get("field"), args.get("range"))}


def monitor_request(cfg, message):
    sock = connect_monitor(cfg["id"])
    if not sock:
        raise servers.ServerError("The server isn't running")
    #--- The hello it sends first needn't be read: closing right after is fine
    sock.sendall((json.dumps(message) + "\n").encode())
    select.select([sock], [], [], 0.2)
    sock.close()


def monitor_query(cfg, text):
    """A read-only command's reply through the monitor's RCON connection; None with RCON off."""
    sock = connect_monitor(cfg["id"])
    if not sock:
        raise servers.ServerError("The server isn't running")
    deadline = time.time() + QUERY_WAIT
    pending = b""
    try:
        sock.sendall((json.dumps({"cmd": "query", "command": text}) + "\n").encode())
        #--- Console lines arrive here too, so only the deadline ends the wait
        while time.time() < deadline:
            if not select.select([sock], [], [], deadline - time.time())[0]:
                break
            chunk = sock.recv(1 << 20)
            if not chunk:
                break
            *lines, pending = (pending + chunk).split(b"\n")
            for line in lines:
                message = json.loads(line)
                if message.get("type") == "reply":
                    return message["text"] if message["ok"] else None
    finally:
        sock.close()
    raise servers.ServerError("The monitor didn't answer. If the app was just updated, "
                              "the monitor picks that up at the server's next start.")


#--------------------------------------------------------------------#
#-- Quick commands
#--------------------------------------------------------------------#


@command
def quick_save(args):
    cfg = require(args)
    quick = []
    for item in args.get("quick", []):
        steps = [{"command": " ".join(str(s.get("command", "")).splitlines()).strip(),
                  "delay": max(0, int(s.get("delay") or 0))} for s in item.get("steps", [])]
        steps = [s for s in steps if s["command"]]
        name = str(item.get("name", "")).strip()
        if not name or not steps:
            raise servers.ServerError("Each quick command needs a name and a command")
        quick.append({"name": name, "icon": item.get("icon") if item.get("icon") in QUICK_ICONS else "bolt",
                      "pinned": bool(item.get("pinned")), "confirm": bool(item.get("confirm")), "steps": steps})
        if item.get("addon"):
            quick[-1]["addon"] = str(item["addon"])
    cfg["quick"] = quick
    servers.save(cfg)
    return {"quick": quick}


@command
def quick_icons(_args):
    return {"icons": QUICK_ICONS}


@command
def quick_run(args):
    cfg = require(args)
    filled = []
    answers = args.get("answers") or {}
    for step in args.get("steps", []):
        text = str(step.get("command", ""))
        for key, value in answers.items():
            text = text.replace("{" + key + "}", " ".join(str(value).splitlines()))
        filled.append({"command": text, "delay": step.get("delay") or 0})
    monitor_request(cfg, {"cmd": "run", "name": args.get("name", ""), "steps": filled})
    return {}


@command
def quick_cancel(args):
    monitor_request(require(args), {"cmd": "cancel", "id": args.get("run")})
    return {}


#--------------------------------------------------------------------#
#-- Settings
#--------------------------------------------------------------------#


def memory_mb():
    try:
        with open("/proc/meminfo", encoding="ascii") as f:
            return int(f.readline().split()[1]) // 1024
    except (OSError, ValueError, IndexError):
        return 16384


@command
def settings_get(args):
    cfg = require(args)
    values = properties.read(servers.props_file(cfg))
    pending = servers.pending_properties(cfg["id"])
    return {
        "exists": os.path.exists(servers.props_file(cfg)),
        "groups": properties.form({**values, **{k: v for k, v in pending.items() if k in values or k in properties.SCHEMA}}),
        "pending": sorted(k for k in pending if not properties.HIDDEN.match(k)),
        "rcon": {**values, **pending}.get("enable-rcon") == "true",
        "eula": servers.eula_accepted(cfg),
        "startup": {k: cfg.get(k) for k in ("java", "heapMb", "preset", "extraFlags", "launch", "command", "restartOnCrash", "minecraft")},
        "boot": servers.status_of(cfg)["boot"],
        "javas": sorted(servers.javas(), key=int),
        "memoryMb": memory_mb(),
        "detected": servers.detect(cfg["dir"]),
    }


@command
def properties_set(args):
    cfg = require(args)
    changes = args.get("changes") or {}
    for key, value in changes.items():
        problem = properties.check(key, value)
        if problem:
            raise servers.ServerError(problem)
    return {"held": servers.save_properties(cfg, {k: str(v) for k, v in changes.items()})}


@command
def dim_filter(args):
    cfg = require(args)
    cfg["dimThreshold"] = max(0.0, float(args.get("threshold", 1)))
    servers.save(cfg)
    return {}


@command
def rcon_set(args):
    return {"held": servers.enable_rcon(require(args), bool(args.get("on")))}


@command
def eula_accept(args):
    servers.accept_eula(require(args))
    return {}


@command
def startup_set(args):
    cfg = require(args)
    changes = args.get("changes") or {}
    allowed = {"java", "heapMb", "preset", "extraFlags", "launch", "command", "restartOnCrash", "minecraft"}
    if set(changes) - allowed:
        raise servers.ServerError(f"Can't set {sorted(set(changes) - allowed)}")
    if "heapMb" in changes:
        heap = int(changes["heapMb"])
        if not 512 <= heap <= memory_mb():
            raise servers.ServerError("Heap must fit in this machine's memory")
        changes["heapMb"] = heap
    if "java" in changes:
        java = str(changes["java"])
        if not (java in servers.javas() or (java.startswith("/") and os.access(java, os.X_OK))):
            raise servers.ServerError(f"No Java at {java}")
        changes["java"] = java
    if "minecraft" in changes:
        changes["minecraft"] = str(changes["minecraft"]).strip()
        if changes["minecraft"] and not addons.version_key(changes["minecraft"]):
            raise servers.ServerError("Minecraft version must look like 1.20.1")
    for key in ("extraFlags", "launch", "command"):
        if key in changes and "\n" in str(changes[key]):
            raise servers.ServerError(f"{key} can't hold a line break")
    cfg.update(changes)
    servers.launch_argv(cfg) if cfg.get("launch") or cfg.get("command") else None
    servers.save(cfg)
    if "restartOnCrash" in changes:
        servers.set_restart_policy(cfg)
    return {}


@command
def boot_set(args):
    servers.set_boot(require(args), bool(args.get("on")))
    return {}


@command
def dim_rename(args):
    cfg = require(args)
    names = cfg.setdefault("dimNames", {})
    name = str(args.get("name", "")).strip()
    if name:
        names[str(args.get("dim"))] = name
    else:
        names.pop(str(args.get("dim")), None)
    servers.save(cfg)
    return {}


#--------------------------------------------------------------------#
#-- Players, backups, mods, schedule
#--------------------------------------------------------------------#


@command
def players_get(args):
    return players.overview(require(args))


@command
def player_set(args):
    return {"live": players.set_listed(require(args), args.get("list"), args.get("name"), bool(args.get("on")))}


@command
def whitelist_set(args):
    return {"live": players.set_whitelist_on(require(args), bool(args.get("on")))}


@command
def backups_get(args):
    cfg = require(args)
    return backups.listing(cfg)


@command
def backup_create(args):
    return backups.create(require(args))


@command
def backup_restore(args):
    return backups.restore(require(args), args.get("name"))


@command
def backup_delete(args):
    backups.delete(require(args), args.get("name"))
    return {}


@command
def set_aside_delete(args):
    backups.delete_set_aside(require(args), args.get("name"))
    return {}


@command
def disk(args):
    cfg = require(args)
    usage = shutil.disk_usage(cfg["dir"])
    return {"free": usage.free, "total": usage.total}


@command
def mods_get(args):
    cfg = require(args)
    return {"mods": mods.listing(cfg), "crashes": mods.crashes(cfg)}


@command
def mods_pick(_args):
    try:
        res = subprocess.run(["zenity", "--file-selection", "--multiple", "--separator=\n",
                              "--file-filter=Mods (*.jar) | *.jar", "--title=Choose mods to add"],
                             capture_output=True, text=True, check=False)
    except OSError as e:
        raise servers.ServerError(f"Couldn't open the file picker: {e}") from e
    return {"files": res.stdout.splitlines() if res.returncode == 0 else []}


@command
def mods_add(args):
    return mods.add(require(args), args.get("files") or [])


@command
def mod_toggle(args):
    mods.toggle(require(args), args.get("file"), bool(args.get("on")))
    return {}


@command
def crash_read(args):
    return {"text": mods.read_crash(require(args), args.get("name"))}


@command
def schedule_set(args):
    cfg = require(args)
    incoming = args.get("schedule") or {}
    times = sorted({t for t in incoming.get("times", []) if isinstance(t, str) and len(t) == 5
                    and t[2] == ":" and t[:2].isdigit() and t[3:].isdigit() and int(t[:2]) < 24 and int(t[3:]) < 60})
    warnings = sorted({int(w) for w in incoming.get("warnings", []) if 0 < int(w) <= 86400}, reverse=True)
    cfg["schedule"] = {"enabled": bool(incoming.get("enabled")), "times": times, "warnings": warnings,
                       "message": " ".join(str(incoming.get("message", "")).splitlines())[:200]
                       or servers.DEFAULT_SCHEDULE["message"]}
    servers.save(cfg)
    return {"schedule": cfg["schedule"]}


@command
def server_get(args):
    cfg = require(args)
    return {"quick": cfg.get("quick", []), "schedule": cfg.get("schedule") or dict(servers.DEFAULT_SCHEDULE),
            "dimThreshold": cfg.get("dimThreshold", 1), "server": summary(cfg),
            "addonSuggestions": [a["name"] for a in addons.available() if addons.matches(a, cfg)
                                 and a["id"] not in cfg.get("addons", [])
                                 and a["id"] not in cfg.get("addonsSeen", [])]}


#--------------------------------------------------------------------#
#-- Add-ons
#--------------------------------------------------------------------#


def addon_view(addon, cfg):
    needs = addon.get("problems") or addons.unmet(addon["match"], cfg["dir"], cfg.get("minecraft"))
    on = not needs and addon["id"] in cfg.get("addons", [])
    panels = []
    for panel in addon.get("panels", []) if on else []:
        missing = addons.unmet(panel.get("requires"), cfg["dir"], cfg.get("minecraft"))
        panels.append({**panel, "needs": missing})
    current = properties.read(servers.props_file(cfg))
    settings = [{**s, "current": current.get(s["key"], "")} for s in addon.get("settings", [])] if on else []
    return {"id": addon["id"], "name": addon["name"], "description": addon.get("description", ""),
            "local": addon.get("local", False), "problems": addon.get("problems", []),
            "needs": needs, "on": on, "suggests": addon.get("suggests", []), "panels": panels,
            "settings": settings}


@command
def addons_get(args):
    cfg = require(args)
    return {"addons": [addon_view(a, cfg) for a in addons.available()]}


@command
def addons_seen(args):
    """The Add-ons tab was opened, so what matches now stops being suggested."""
    cfg = require(args)
    cfg["addonsSeen"] = [a["id"] for a in addons.available() if addons.matches(a, cfg)]
    servers.save(cfg)
    return {}


@command
def addon_set(args):
    cfg = require(args)
    addon = addons.find(args.get("addon"))
    on = bool(args.get("on"))
    if on and not addons.matches(addon, cfg):
        needs = addons.unmet(addon["match"], cfg["dir"], cfg.get("minecraft"))
        raise servers.ServerError(f"{addon['name']} needs {', '.join(needs)}")
    addons.switch(cfg, addon, on)
    servers.save(cfg)
    return {"quick": cfg["quick"]}


@command
def addon_pick(_args):
    try:
        res = subprocess.run(["zenity", "--file-selection", "--directory", "--title=Choose an add-on folder"],
                             capture_output=True, text=True, check=False)
    except OSError as e:
        raise servers.ServerError(f"Couldn't open the file picker: {e}") from e
    folder = res.stdout.strip() if res.returncode == 0 else ""
    if not folder:
        return {"dir": ""}
    manifest = addons.read(folder)
    return {"dir": folder, "name": manifest["name"], "problems": manifest.get("problems", []),
            "commands": addons.commands_of(manifest) if not manifest.get("problems") else []}


@command
def addon_import(args):
    return {"name": addons.import_folder(args.get("dir", ""))["name"]}


@command
def addon_query(args):
    """A panel's status or table command. `console` sends it there instead, for a server
    with RCON off: the reply shows in the console, not on the panel."""
    cfg = require(args)
    panel = addons.panel_of(cfg, args.get("addon"), args.get("panel"))
    text = panel.get("status") or panel.get("command")
    if not text:
        raise servers.ServerError("This panel has nothing to read")
    if args.get("console"):
        servers.send(cfg, text)
        return {}
    reply = monitor_query(cfg, text)
    if reply is None:
        return {"rcon": False}
    return {"rcon": True, "text": reply, "rows": addons.parse_rows(panel, reply) if panel.get("rows") else []}


@command
def addon_action(args):
    cfg = require(args)
    panel = addons.panel_of(cfg, args.get("addon"), args.get("panel"))
    servers.send(cfg, addons.filled_command(panel, args.get("action"), args.get("values") or {}))
    return {}


#--------------------------------------------------------------------#
#-- Console from a terminal
#--------------------------------------------------------------------#


def console(name):
    """`omni-server console <name>`: the live console over SSH or in a terminal; each
    line typed goes to the server, and Ctrl+C only leaves this view."""
    wanted = name.lower()
    match = [c for c in servers.all_servers() if wanted in (c["id"], c["name"].lower())]
    if not match:
        names = ", ".join(c["id"] for c in servers.all_servers()) or "none yet"
        sys.exit(f"No server called {name}. Servers: {names}")
    cfg = match[0]
    log = f"{servers.state_dir(cfg['id'])}/console.log"
    print(f"{cfg['name']}: Ctrl+C leaves this view, the server keeps running.", flush=True)
    try:
        f = open(log, "rb")  # noqa: SIM115 followed until Ctrl+C
    except OSError:
        sys.exit("This server hasn't run yet.")
    f.seek(0, os.SEEK_END)
    f.seek(max(0, f.tell() - 8192))
    try:
        while True:
            data = f.read()
            if data:
                sys.stdout.write(data.decode("utf-8", errors="replace"))
                sys.stdout.flush()
            if select.select([sys.stdin], [], [], 0.3)[0]:
                line = sys.stdin.readline()
                if not line:
                    return
                try:
                    servers.send(cfg, line)
                except servers.ServerError as e:
                    print(e, flush=True)
    except KeyboardInterrupt:
        print()


#--------------------------------------------------------------------#
#-- Calling
#--------------------------------------------------------------------#


def run(cmd, args):
    fn = COMMANDS.get(cmd)
    if not fn:
        return {"ok": False, "error": f"Unknown command: {cmd}"}
    try:
        return {"ok": True, **fn(args)}
    except (servers.ServerError, addons.AddonError) as e:
        return {"ok": False, "error": str(e)}
    except (OSError, ValueError, KeyError, TypeError) as e:
        return {"ok": False, "error": f"{type(e).__name__}: {e}"}


def serve():
    """`--serve`: requests as JSON lines on stdin, each in a forked child; replies as
    {"id", "reply"} lines, in the order they finish."""
    sel = selectors.DefaultSelector()
    sel.register(0, selectors.EVENT_READ)
    pending = b""
    children = {}  # read end -> [request id, pid, reply bytes]
    while True:
        for key, _ in sel.select():
            fd = key.fd
            if fd == 0:
                chunk = os.read(0, 65536)
                if not chunk:
                    return
                *lines, pending = (pending + chunk).split(b"\n")
                for line in lines:
                    if line.strip():
                        r, pid, rid = fork_request(line)
                        children[r] = [rid, pid, b""]
                        sel.register(r, selectors.EVENT_READ)
                continue
            chunk = os.read(fd, 65536)
            if chunk:
                children[fd][2] += chunk
                continue
            rid, pid, data = children.pop(fd)
            sel.unregister(fd)
            os.close(fd)
            os.waitpid(pid, 0)
            if not data:
                data = json.dumps({"ok": False, "error": "omni-server-backend gave no answer"}).encode()
            sys.stdout.buffer.write(b'{"id": %s, "reply": %s}\n' % (json.dumps(rid).encode(), data))
            sys.stdout.buffer.flush()


def fork_request(line):
    try:
        req = json.loads(line)
        rid, cmd, args = req.get("id"), req.get("cmd", ""), req.get("args") or {}
    except (ValueError, AttributeError):
        rid, cmd, args = None, "", {}
    r, w = os.pipe()
    pid = os.fork()
    if pid:
        os.close(w)
        return r, pid, rid
    try:
        os.close(r)
        data = json.dumps(run(cmd, args)).encode()
        while data:
            data = data[os.write(w, data):]
    finally:
        os._exit(0)


def main():
    if sys.argv[1:] == ["--serve"]:
        serve()
        return
    if len(sys.argv) >= 3 and sys.argv[1] == "console":
        console(sys.argv[2])
        return
    if len(sys.argv) < 2:
        sys.exit(f"usage: omni-server-backend <{'|'.join(COMMANDS)}|watch> ['<json args>']")
    try:
        args = json.loads(sys.argv[2]) if len(sys.argv) > 2 else {}
    except ValueError:
        print(json.dumps({"ok": False, "error": "args aren't JSON"}))
        sys.exit(1)
    if sys.argv[1] == "watch":
        try:
            watch(args)
        except servers.ServerError as e:
            print(json.dumps({"ok": False, "error": str(e)}))
        return
    reply = run(sys.argv[1], args)
    print(json.dumps(reply))
    sys.exit(0 if reply["ok"] else 1)


if __name__ == "__main__":
    main()
