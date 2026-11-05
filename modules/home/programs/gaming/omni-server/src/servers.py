"""The registered servers: one JSON file each in ~/.config/omni-server/servers/,
what's in a server's folder (detect) and the state of its systemd units. Nothing
here touches a server's files except eula.txt and server.properties."""

import glob
import json
import os
import re
import secrets
import shlex
import shutil
import socket
import subprocess
import tempfile
import time
import zipfile

import addons
import properties

HOME = os.path.expanduser("~")
CONFIG = os.environ.get("XDG_CONFIG_HOME", f"{HOME}/.config") + "/omni-server/servers"
STATE = os.environ.get("XDG_STATE_HOME", f"{HOME}/.local/state") + "/omni-server"
RUNTIME = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}") + "/omni-server"
UNITS = os.environ.get("XDG_CONFIG_HOME", f"{HOME}/.config") + "/systemd/user"

ID = re.compile(r"^[a-z0-9][a-z0-9-]{0,63}$")
PLAYER = re.compile(r"^[A-Za-z0-9_]{1,16}$")
RCON_FIRST_PORT = 25575

#--- G1 tuning common on modded servers; Java 24+ adds compact headers
G1_FLAGS = [
    "-XX:+UseG1GC", "-XX:+ParallelRefProcEnabled", "-XX:MaxGCPauseMillis=200",
    "-XX:+UnlockExperimentalVMOptions", "-XX:+DisableExplicitGC", "-XX:G1NewSizePercent=30",
    "-XX:G1MaxNewSizePercent=40", "-XX:G1HeapRegionSize=16M", "-XX:G1ReservePercent=20",
    "-XX:G1HeapWastePercent=5", "-XX:G1MixedGCCountTarget=4",
    "-XX:InitiatingHeapOccupancyPercent=15", "-XX:G1MixedGCLiveThresholdPercent=90",
    "-XX:G1RSetUpdatingPauseTimePercent=5", "-XX:SurvivorRatio=32", "-XX:+AlwaysPreTouch",
    "-XX:+PerfDisableSharedMem", "-XX:+UseTransparentHugePages",
]
FML_FLAGS = ["-Dfml.readTimeout=180", "-Dfml.loginTimeout=60"]

DEFAULT_SCHEDULE = {
    "enabled": False,
    "times": [],
    "warnings": [900, 300, 60, 30],
    "message": "Server restarts in {time}",
}


class ServerError(Exception):
    """A problem to show the person, in words they can act on."""


def javas():
    """Version -> java binary, from the wrapper (default.nix)."""
    return json.loads(os.environ.get("OMNI_SERVER_JAVAS", "{}"))


def path(server_id):
    if not ID.match(server_id or ""):
        raise ServerError(f"Bad server id: {server_id!r}")
    return f"{CONFIG}/{server_id}.json"


def load(server_id):
    try:
        with open(path(server_id), encoding="utf-8") as f:
            return migrate(json.load(f))
    except OSError as e:
        raise ServerError(f"No server called {server_id}") from e


def migrate(cfg):
    """Fill in a config written before add-ons. Everything matching goes on, so a server
    keeps what core used to do for it."""
    if "addons" in cfg and "minecraft" in cfg:
        return cfg
    if cfg.get("kind") == "gtnh":
        cfg["kind"] = "forge"
    cfg.setdefault("minecraft", detect(cfg["dir"])["minecraft"])
    if "addons" not in cfg:
        cfg["addons"] = []
        for addon in addons.available():
            if addons.matches(addon, cfg):
                addons.switch(cfg, addon, True)
        cfg["addonsSeen"] = list(cfg["addons"])
    save(cfg)
    return cfg


def save(cfg):
    os.makedirs(CONFIG, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=CONFIG, prefix=".tmp")
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(cfg, f, indent=2)
    os.replace(tmp, path(cfg["id"]))


def all_servers():
    found = []
    for file in sorted(glob.glob(f"{CONFIG}/*.json")):
        try:
            with open(file, encoding="utf-8") as f:
                found.append(json.load(f))
        except (OSError, ValueError):
            continue
    return found


def state_dir(server_id):
    return f"{STATE}/{server_id}"


def fifo(server_id):
    return f"{RUNTIME}/{server_id}.stdin"


def monitor_socket(server_id):
    return f"{RUNTIME}/{server_id}.sock"


def pending_file(server_id):
    return f"{state_dir(server_id)}/pending-properties.json"


def props_file(cfg):
    return f"{cfg['dir']}/server.properties"


def level_dir(cfg):
    name = properties.read(props_file(cfg)).get("level-name", "world")
    if "/" in name or name in ("", ".", ".."):
        raise ServerError(f"level-name in server.properties looks wrong: {name}")
    return f"{cfg['dir']}/{name}"


#--------------------------------------------------------------------#
#-- What's in a server's folder
#--------------------------------------------------------------------#


def minecraft_version(folder):
    """The folder's Minecraft version, or "" when nothing in it says."""
    root = glob.escape(folder)
    for file in glob.glob(f"{root}/minecraft_server.*.jar"):
        return os.path.basename(file)[len("minecraft_server."):-len(".jar")]
    for file in glob.glob(f"{root}/forge-*.jar"):
        if m := re.match(r"forge-(\d+\.\d+(?:\.\d+)?)-", os.path.basename(file)):
            return m[1]
    for project in ("minecraft/server", "fabricmc/intermediary"):
        for found in sorted(glob.glob(f"{root}/libraries/net/{project}/*/")):
            name = os.path.basename(found.rstrip("/"))
            #--- Newer Forge names this folder <version>-<date>
            return name.split("-")[0]
    for file in sorted(glob.glob(f"{root}/*.jar")):
        try:
            with zipfile.ZipFile(file) as z:
                return str(json.loads(z.read("version.json"))["id"]).split(" ")[0]
        except (OSError, ValueError, KeyError, zipfile.BadZipFile):
            continue
    return ""


def detect(folder):
    """How this folder starts: kind, label, launch arguments, Minecraft version and a
    suggested Java."""
    return addons.detected(folder) or {**launch_target(folder), "minecraft": minecraft_version(folder)}


def launch_target(folder):
    for project, kind, tps in (("net/minecraftforge/forge", "forge", "forge tps"),
                               ("net/neoforged/neoforge", "neoforge", "neoforge tps")):
        args = sorted(glob.glob(f"{folder}/libraries/{project}/*/unix_args.txt"))
        if args:
            rel = os.path.relpath(args[-1], folder)
            label = f"{'NeoForge' if kind == 'neoforge' else 'Forge'} {os.path.basename(os.path.dirname(rel))}"
            return {"kind": kind, "label": label, "java": "21", "launch": f"@{rel} nogui", "tps": tps}
    if os.path.exists(f"{folder}/fabric-server-launch.jar"):
        return {"kind": "fabric", "label": "Fabric", "java": "21",
                "launch": "-jar fabric-server-launch.jar nogui", "tps": ""}
    old_forge = sorted(glob.glob(f"{folder}/forge-1.7.10-*.jar"))
    if old_forge:
        return {"kind": "forge", "label": "Forge 1.7.10", "java": "8",
                "launch": f"-jar {os.path.basename(old_forge[-1])} nogui", "tps": "forge tps"}
    jars = sorted(os.path.basename(j) for j in glob.glob(f"{folder}/*.jar"))
    if jars:
        pick = next((j for j in jars if "server" in j.lower()), jars[0])
        return {"kind": "jar", "label": "Minecraft server", "java": "21",
                "launch": f"-jar {pick} nogui", "tps": ""}
    return {"kind": "custom", "label": "Custom", "java": "21", "launch": "", "tps": ""}


def default_heap_mb():
    try:
        with open("/proc/meminfo", encoding="ascii") as f:
            total = int(f.readline().split()[1]) // 1024
    except (OSError, ValueError, IndexError):
        return 4096
    return max(2048, min(12288, total // 4 // 1024 * 1024))


def seed_quick(found):
    """The quick commands a new server starts with."""
    quick = [
        {"name": "Save", "icon": "save", "pinned": True, "confirm": False,
         "steps": [{"command": "save-all", "delay": 0}]},
        {"name": "Broadcast", "icon": "campaign", "pinned": True, "confirm": False,
         "steps": [{"command": "say {message}", "delay": 0}]},
    ]
    quick.append({"name": "Restart in 1 min", "icon": "schedule", "pinned": True, "confirm": True,
                  "steps": [{"command": "say Server restarts in 1 minute", "delay": 0},
                            {"command": "@restart", "delay": 60}]})
    if found["tps"]:
        quick.append({"name": "TPS", "icon": "speed", "pinned": False, "confirm": False,
                      "steps": [{"command": found["tps"], "delay": 0}]})
    quick += [
        {"name": "List players", "icon": "group", "pinned": False, "confirm": False,
         "steps": [{"command": "list", "delay": 0}]},
        {"name": "Set day", "icon": "light_mode", "pinned": False, "confirm": False,
         "steps": [{"command": "time set 1000", "delay": 0}]},
        {"name": "Clear weather", "icon": "cloud_off", "pinned": False, "confirm": False,
         "steps": [{"command": "weather clear", "delay": 0}]},
    ]
    return quick


def add(folder, name=None):
    folder = os.path.realpath(os.path.expanduser(folder))
    if not os.path.isdir(folder):
        raise ServerError(f"{folder} isn't a folder")
    for other in all_servers():
        if other["dir"] == folder:
            raise ServerError(f"{other['name']} already uses this folder")
    found = detect(folder)
    name = name or re.sub(r"[_\s]+", " ", os.path.basename(folder)).strip()
    base = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")[:48] or "server"
    server_id, n = base, 2
    while os.path.exists(path(server_id)):
        server_id, n = f"{base}-{n}", n + 1
    cfg = {
        "id": server_id, "name": name, "dir": folder, "kind": found["kind"], "label": found["label"],
        "java": found["java"], "heapMb": default_heap_mb(), "preset": "g1", "extraFlags": "",
        "launch": found["launch"], "command": "", "tps": found["tps"], "restartOnCrash": True,
        "quick": seed_quick(found), "schedule": dict(DEFAULT_SCHEDULE), "dimNames": {},
        "minecraft": found["minecraft"], "addons": [], "addonsSeen": [],
    }
    os.makedirs(state_dir(server_id), exist_ok=True)
    save(cfg)
    return cfg


def remove(server_id):
    """Forget a server: its folder isn't touched, only this app's files about it."""
    cfg = load(server_id)
    if status_of(cfg)["active"]:
        raise ServerError("Stop the server first")
    set_boot(cfg, False)
    shutil.rmtree(f"{UNITS}/omni-server@{server_id}.service.d", ignore_errors=True)
    os.unlink(path(server_id))
    shutil.rmtree(state_dir(server_id), ignore_errors=True)


#--------------------------------------------------------------------#
#-- Launching
#--------------------------------------------------------------------#


def java_binary(cfg):
    java = str(cfg.get("java", ""))
    if java.startswith("/"):
        return java
    binary = javas().get(java)
    if not binary:
        raise ServerError(f"Java {java} isn't available")
    return binary


def java_major(cfg):
    java = str(cfg.get("java", ""))
    return int(java) if java.isdigit() else 0


def launch_argv(cfg):
    """The command runner.py execs in the server's folder."""
    if cfg.get("command", "").strip():
        return ["/bin/sh", "-c", cfg["command"]]
    if not cfg.get("launch", "").strip():
        raise ServerError("This server has no launch target. Set one in Settings.")
    heap = f"{int(cfg['heapMb'])}M"
    argv = [java_binary(cfg), f"-Xms{heap}", f"-Xmx{heap}"]
    if cfg.get("preset") == "g1":
        argv += G1_FLAGS
        if java_major(cfg) >= 24:
            argv.append("-XX:+UseCompactObjectHeaders")
    if cfg.get("kind") in ("forge", "neoforge"):
        argv += FML_FLAGS
    argv += shlex.split(cfg.get("extraFlags", ""))
    argv += shlex.split(cfg["launch"])
    return argv


def eula_accepted(cfg):
    try:
        with open(f"{cfg['dir']}/eula.txt", encoding="utf-8", errors="replace") as f:
            return any(line.strip().lower() == "eula=true" for line in f)
    except OSError:
        return False


def accept_eula(cfg):
    with open(f"{cfg['dir']}/eula.txt", "w", encoding="utf-8") as f:
        f.write(f"#Accepted in Omni Server on {time.strftime('%Y-%m-%d %H:%M:%S')}\neula=true\n")


def apply_pending(cfg):
    """The server.properties edits made while it ran; runner.py calls this before a start."""
    file = pending_file(cfg["id"])
    try:
        with open(file, encoding="utf-8") as f:
            changes = json.load(f)
    except (OSError, ValueError):
        return
    properties.write(props_file(cfg), changes)
    os.unlink(file)


def pending_properties(server_id):
    try:
        with open(pending_file(server_id), encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def save_properties(cfg, changes):
    """Write now when stopped; held for the next start while running, as the server
    can rewrite the file itself. Returns whether they were held."""
    if status_of(cfg)["active"]:
        held = pending_properties(cfg["id"])
        held.update({k: str(v) for k, v in changes.items()})
        os.makedirs(state_dir(cfg["id"]), exist_ok=True)
        with open(pending_file(cfg["id"]), "w", encoding="utf-8") as f:
            json.dump(held, f)
        os.chmod(pending_file(cfg["id"]), 0o600)
        return True
    properties.write(props_file(cfg), changes)
    return False


def free_rcon_port(cfg):
    """A port for RCON: not another registered server's and nothing listening on it."""
    taken = set()
    for other in all_servers():
        if other["id"] != cfg["id"]:
            values = properties.read(props_file(other))
            taken |= {values.get("rcon.port"), values.get("server-port")}
    taken.add(properties.read(props_file(cfg)).get("server-port"))
    port = RCON_FIRST_PORT
    while str(port) in taken or port_in_use(port):
        port += 1
    return port


def enable_rcon(cfg, on):
    values = {**properties.read(props_file(cfg)), **pending_properties(cfg["id"])}
    if not on:
        return save_properties(cfg, {"enable-rcon": "false"})
    changes = {"enable-rcon": "true"}
    if not values.get("rcon.password"):
        changes["rcon.password"] = secrets.token_urlsafe(24)
    if not values.get("rcon.port") or values.get("rcon.port") == "0":
        changes["rcon.port"] = str(free_rcon_port(cfg))
    held = save_properties(cfg, changes)
    if os.path.exists(props_file(cfg)):
        os.chmod(props_file(cfg), 0o600)  # it holds the password from here on
    return held


def port_in_use(port, host="127.0.0.1"):
    with socket.socket() as s:
        s.settimeout(0.2)
        return s.connect_ex((host, int(port))) == 0


#--------------------------------------------------------------------#
#-- systemd
#--------------------------------------------------------------------#


def unit(server_id):
    return f"omni-server@{server_id}.service"


def systemctl(*args):
    res = subprocess.run(["systemctl", "--user", *args], capture_output=True, text=True, check=False)
    return res.returncode, (res.stdout + res.stderr).strip()


def outside_pid(cfg, own=0):
    """A Java already running in this folder that isn't our service's (a tmux launcher)."""
    for entry in os.listdir("/proc"):
        if not entry.isdigit() or int(entry) == own:
            continue
        try:
            with open(f"/proc/{entry}/comm", encoding="ascii", errors="replace") as f:
                if f.read().strip() != "java":
                    continue
            if os.path.realpath(f"/proc/{entry}/cwd") == cfg["dir"]:
                return int(entry)
        except OSError:
            continue
    return 0


def status_of(cfg):
    """What systemd says: state (stopped, starting, running, stopping, restarting, failed
    or outside), pid, whether Start at boot is on."""
    code, out = systemctl("show", unit(cfg["id"]), "-p",
                          "ActiveState,SubState,MainPID,Result,ExecMainStatus,UnitFileState,ActiveEnterTimestampMonotonic,NRestarts,LoadState")
    props = dict(line.split("=", 1) for line in out.splitlines() if "=" in line) if code == 0 else {}
    active = props.get("ActiveState", "inactive")
    sub = props.get("SubState", "dead")
    pid = int(props.get("MainPID") or 0)
    state = {"active": "running", "activating": "starting", "deactivating": "stopping",
             "failed": "failed"}.get(active, "stopped")
    if sub == "auto-restart" or (active == "activating" and sub == "auto-restart"):
        state = "restarting"
    outside = 0 if pid else outside_pid(cfg)
    if outside:
        state = "outside"
    return {
        "state": state,
        "active": active in ("active", "activating", "deactivating") or bool(outside),
        "pid": pid or outside,
        "result": props.get("Result", ""),
        "exitStatus": props.get("ExecMainStatus", ""),
        "boot": props.get("UnitFileState") == "enabled",
        "restarts": int(props.get("NRestarts") or 0),
        "unitLoaded": props.get("LoadState") == "loaded",
    }


def start(cfg):
    status = status_of(cfg)
    if status["state"] == "outside":
        raise ServerError(f"This server is already running outside Omni Server (PID {status['pid']})")
    if status["active"]:
        return
    if not status["unitLoaded"]:
        raise ServerError("The omni-server units aren't installed yet. Rebuild, then try again.")
    if not eula_accepted(cfg):
        raise ServerError("Accept Minecraft's EULA in Settings first.")
    launch_argv(cfg)  # surfaces a missing Java or launch target before systemd does
    values = {**properties.read(props_file(cfg)), **pending_properties(cfg["id"])}
    port = values.get("server-port", "25565")
    if port_in_use(port):
        raise ServerError(f"Port {port} is already in use, maybe by another server.")
    os.makedirs(state_dir(cfg["id"]), exist_ok=True)
    systemctl("reset-failed", unit(cfg["id"]))
    code, out = systemctl("start", "--no-block", unit(cfg["id"]))
    if code:
        raise ServerError(out)


def stop(cfg):
    code, out = systemctl("stop", "--no-block", unit(cfg["id"]))
    if code:
        raise ServerError(out)


def restart(cfg):
    code, out = systemctl("restart", "--no-block", unit(cfg["id"]))
    if code:
        raise ServerError(out)


def kill(cfg):
    """SIGKILL, for a hung server. The stop job goes first so Restart= doesn't fire."""
    systemctl("stop", "--no-block", unit(cfg["id"]))
    time.sleep(0.2)
    code, out = systemctl("kill", "-s", "SIGKILL", unit(cfg["id"]))
    if code:
        raise ServerError(out)


def set_boot(cfg, on):
    """Start at boot: this instance's link in default.target.wants, made by hand because
    the template has no [Install], and `add-wants` would pin default.target to the store."""
    link = f"{UNITS}/default.target.wants/{unit(cfg['id'])}"
    if on and not os.path.islink(link):
        os.makedirs(os.path.dirname(link), exist_ok=True)
        os.symlink(f"{UNITS}/omni-server@.service", link)
    elif not on and os.path.islink(link):
        os.unlink(link)
    code, out = systemctl("daemon-reload")
    if code:
        raise ServerError(out)


def set_restart_policy(cfg):
    """The per-server override of Restart= in the template; none means on-failure."""
    folder = f"{UNITS}/omni-server@{cfg['id']}.service.d"
    file = f"{folder}/10-omni-server.conf"
    if cfg.get("restartOnCrash", True):
        if os.path.exists(file):
            os.unlink(file)
    else:
        os.makedirs(folder, exist_ok=True)
        with open(file, "w", encoding="ascii") as f:
            f.write("[Service]\nRestart=no\n")
    systemctl("daemon-reload")


def send(cfg, text):
    """A line on the server's stdin. A newline would start a second command."""
    line = " ".join(str(text).splitlines()).strip()
    if not line:
        return
    try:
        fd = os.open(fifo(cfg["id"]), os.O_WRONLY | os.O_NONBLOCK)
    except OSError as e:
        raise ServerError("The server isn't running") from e
    try:
        os.write(fd, (line + "\n").encode())
    finally:
        os.close(fd)
