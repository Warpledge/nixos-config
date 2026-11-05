"""omni-server-monitor@.service, one per running server and independent of the window:
tails the console, polls TPS and players, samples the JVM, keeps the stat history,
runs quick command sequences and scheduled restarts, and publishes all of it on a
unix socket as JSON lines. It stops with the server (BindsTo)."""

import collections
import json
import os
import re
import selectors
import signal
import socket
import subprocess
import sys
import time

import history
import logparse
import properties
import rcon
import servers

TICK = 0.5
POLL_RCON = 5
POLL_STDIN = 30  # slower: each poll writes to the server's log
SAMPLE = 5
HEAP = 15
RING = 2000
LAG_KEPT = 50
HELLO_LINES = 1000
MAX_READ = 4 << 20
HEAP_LINE = re.compile(r"total(?: reserved)? (\d+)K,(?: committed \d+K,)? used (\d+)K")
TICKS = os.sysconf("SC_CLK_TCK")
CORES = os.cpu_count() or 1
PAGE = os.sysconf("SC_PAGE_SIZE")


class Monitor:
    def __init__(self, server_id):
        self.id = server_id
        self.cfg = servers.load(server_id)
        self.cfg_mtime = 0
        self.values = properties.read(servers.props_file(self.cfg))
        self.dir = servers.state_dir(server_id)
        self.log_path = f"{self.dir}/console.log"
        self.log = None
        self.log_inode = None
        self.partial = b""
        self.ring = collections.deque(maxlen=RING)
        self.fresh = []
        self.clients = {}  # socket -> unread request bytes
        self.db = history.connect(f"{self.dir}/history.db")
        self.rcon = None
        self.rcon_retry = 0
        self.stopping_flag = False
        self.pid = 0
        self.cpu_last = None
        self.tps_order = []
        self.saved_names = []
        self.expect_names = False
        self.fallback_dims = []
        self.warned = set()
        self.runs = []
        self.timers = collections.defaultdict(float)
        self.state = {
            "status": "starting", "ready": False, "pid": 0, "startedAt": time.time(),
            "cpu": None, "cores": None, "rss": None, "heapUsed": None, "heapMax": None,
            "tps": None, "mspt": None, "dims": [], "players": [],
            "maxPlayers": int(self.values.get("max-players", 0) or 0), "lagWarnings": 0,
            "lagEvents": [], "lastCrash": "", "rcon": False, "statsVia": "", "runs": [], "nextRestart": 0,
        }

    #--------------------------------------------------------------------#
    #-- Console
    #--------------------------------------------------------------------#

    def tail(self):
        """New console lines, reopening after the service's log rotation."""
        try:
            inode = os.stat(self.log_path).st_ino
        except OSError:
            return
        if inode != self.log_inode:
            if self.log:
                self.log.close()
            self.log = open(self.log_path, "rb")  # noqa: SIM115 kept open between ticks
            self.log_inode = inode
            self.partial = b""
        data = self.log.read(MAX_READ)
        if not data:
            return
        *lines, self.partial = (self.partial + data).split(b"\n")
        for raw in lines:
            self.handle(raw.decode("utf-8", errors="replace").rstrip("\r"))

    def handle(self, raw):
        event = logparse.parse_line(raw)
        kind, text = event["kind"], event["text"]
        if kind == "done":
            self.state.update(ready=True, status="running")
        elif kind == "stopping":
            self.state["status"] = "stopping"
        elif kind == "join" and event["name"] not in self.state["players"]:
            self.state["players"] = [*self.state["players"], event["name"]]
        elif kind == "leave":
            self.state["players"] = [p for p in self.state["players"] if p != event["name"]]
        elif kind == "lag":
            self.state["lagWarnings"] += 1
            if "behindMs" in event:
                detail = {k: event[k] for k in ("time", "behindMs", "ticks")}
                self.state["lagEvents"] = [*self.state["lagEvents"], detail][-LAG_KEPT:]
        elif kind == "crash":
            self.state["lastCrash"] = event["path"]
        elif kind == "saving":
            self.saved_names.append(event["dim"])
        if not self.state["rcon"]:
            self.read_fallback_reply(event, text)
        self.ring.append(event)
        self.fresh.append(event)

    def read_fallback_reply(self, event, text):
        """`forge tps` and `list` replies when they come back through the console."""
        if self.expect_names:
            self.expect_names = False
            event["hidden"] = True
            self.state["players"] = logparse.parse_list(f"There are 0/0 players online:{text}")["names"]
            return
        if logparse.POLL_LINE.search(text):
            event["hidden"] = True
        parsed = logparse.parse_tps(text)
        self.fallback_dims += parsed["dims"]
        if parsed["overall"]:
            self.apply_tps(parsed["overall"], self.fallback_dims)
            self.fallback_dims = []
        listed = logparse.parse_list(text)
        if listed:
            self.state["maxPlayers"] = listed["max"]
            if listed["names"] or not listed["online"]:
                self.state["players"] = listed["names"]
            else:
                self.expect_names = True

    #--------------------------------------------------------------------#
    #-- Polling
    #--------------------------------------------------------------------#

    def apply_tps(self, overall, dims):
        #--- A reply cut short by a stop mustn't lose the order learn_dim_names needs
        if not dims:
            return
        names = {**self.cfg.get("dimAuto", {}), **self.cfg.get("dimNames", {})}
        self.tps_order = [d["id"] for d in dims]
        self.state["dims"] = sorted(
            ({**d, "name": logparse.dim_name(d["id"], names)} for d in dims), key=lambda d: -d["ms"]
        )
        if overall:
            self.state.update(tps=overall["tps"], mspt=overall["ms"])

    def connect_rcon(self):
        self.values = properties.read(servers.props_file(self.cfg))
        if self.values.get("enable-rcon") != "true":
            return False
        now = time.time()
        if self.rcon:
            return True
        if now < self.rcon_retry:
            return False
        try:
            self.rcon = rcon.Rcon(self.values.get("server-ip") or "127.0.0.1",
                                  int(self.values.get("rcon.port") or 25575),
                                  self.values.get("rcon.password", ""))
        except (OSError, ValueError, rcon.RconError):
            self.rcon, self.rcon_retry = None, now + 10
            return False
        return True

    def poll(self):
        if not self.state["ready"] or self.state["status"] == "stopping":
            return
        now = time.time()
        if self.connect_rcon():
            self.state.update(rcon=True, statsVia="rcon")
            if now - self.timers["poll"] < POLL_RCON:
                return
            self.timers["poll"] = now
            try:
                if self.cfg.get("tps"):
                    parsed = logparse.parse_tps(self.rcon.command(self.cfg["tps"]))
                    self.apply_tps(parsed["overall"], parsed["dims"])
                listed = logparse.parse_list(self.rcon.command("list"))
                if listed:
                    self.state.update(players=listed["names"], maxPlayers=listed["max"])
            except (OSError, rcon.RconError):
                self.rcon.close()
                self.rcon, self.rcon_retry = None, now + 10
            return
        self.state.update(rcon=False, statsVia="stdin")
        if now - self.timers["poll"] < POLL_STDIN:
            return
        self.timers["poll"] = now
        try:
            if self.cfg.get("tps"):
                servers.send(self.cfg, self.cfg["tps"])
            servers.send(self.cfg, "list")
        except servers.ServerError:
            pass

    def find_jvm(self):
        """The JVM's PID: the main process, or inside the unit's cgroup for a custom command."""
        _, out = servers.systemctl("show", servers.unit(self.id), "-p", "MainPID", "--value")
        main = int(out or 0) if (out or "0").isdigit() else 0
        if not main:
            return 0
        try:
            with open(f"/proc/{main}/comm", encoding="ascii", errors="replace") as f:
                if f.read().strip() == "java":
                    return main
            with open(f"/proc/{main}/cgroup", encoding="ascii") as f:
                group = f.read().strip().split("::", 1)[-1]
            with open(f"/sys/fs/cgroup{group}/cgroup.procs", encoding="ascii") as f:
                for pid in f.read().split():
                    with open(f"/proc/{pid}/comm", encoding="ascii", errors="replace") as c:
                        if c.read().strip() == "java":
                            return int(pid)
        except OSError:
            pass
        return main

    def sample(self):
        now = time.time()
        if now - self.timers["sample"] < SAMPLE:
            return
        self.timers["sample"] = now
        if not self.pid or not os.path.exists(f"/proc/{self.pid}"):
            self.pid = self.find_jvm()
            self.cpu_last = None
            self.state["pid"] = self.pid
        try:
            with open(f"/proc/{self.pid}/stat", encoding="ascii", errors="replace") as f:
                fields = f.read().rsplit(")", 1)[1].split()
            jiffies = int(fields[11]) + int(fields[12])
            with open(f"/proc/{self.pid}/statm", encoding="ascii") as f:
                self.state["rss"] = int(f.read().split()[1]) * PAGE
        except (OSError, IndexError, ValueError):
            return
        if self.cpu_last:
            spent = (jiffies - self.cpu_last[1]) / TICKS / max(now - self.cpu_last[0], 0.1)
            self.state.update(cpu=round(spent / CORES, 4), cores=round(spent, 2))
        self.cpu_last = (now, jiffies)
        if now - self.timers["heap"] >= HEAP:
            self.timers["heap"] = now
            self.sample_heap()
        if self.state["ready"]:
            history.insert(self.db, {
                "cpu": self.state["cpu"], "rss": self.state["rss"], "heap": self.state["heapUsed"],
                "tps": self.state["tps"], "mspt": self.state["mspt"], "players": len(self.state["players"]),
            })
        if now - self.timers["rollup"] >= 60:
            self.timers["rollup"] = now
            history.roll_up(self.db)

    def sample_heap(self):
        try:
            jcmd = os.path.join(os.path.dirname(os.path.realpath(f"/proc/{self.pid}/exe")), "jcmd")
            res = subprocess.run([jcmd, str(self.pid), "GC.heap_info"], capture_output=True, text=True,
                                 timeout=5, check=False)
        except (OSError, subprocess.TimeoutExpired):
            return
        m = HEAP_LINE.search(res.stdout)
        if m:
            self.state.update(heapMax=int(m[1]) * 1024, heapUsed=int(m[2]) * 1024)

    #--------------------------------------------------------------------#
    #-- Quick commands and scheduled restarts
    #--------------------------------------------------------------------#

    def start_run(self, name, steps):
        now = time.time()
        queue, due = [], now
        for step in steps:
            due += max(0, float(step.get("delay") or 0))
            queue.append({"command": str(step.get("command", "")), "due": due})
        self.runs.append({"id": int(now * 1000), "name": name, "queue": queue})

    def do_step(self, command):
        if command == "@restart":
            servers.restart(self.cfg)
        elif command == "@stop":
            servers.stop(self.cfg)
        else:
            servers.send(self.cfg, command)

    def tick_runs(self):
        now = time.time()
        for run in self.runs:
            while run["queue"] and run["queue"][0]["due"] <= now:
                try:
                    self.do_step(run["queue"].pop(0)["command"])
                except servers.ServerError:
                    run["queue"] = []
        self.runs = [r for r in self.runs if r["queue"]]
        self.state["runs"] = [{"id": r["id"], "name": r["name"], "steps": len(r["queue"]),
                               "next": max(0, round(r["queue"][0]["due"] - now))} for r in self.runs]

    def next_restart(self, now):
        """The next scheduled restart's time, 0 with none set."""
        schedule = self.cfg.get("schedule") or {}
        if not schedule.get("enabled"):
            return 0
        lt = time.localtime(now)
        best = 0
        for clock in schedule.get("times", []):
            try:
                hour, minute = (int(x) for x in clock.split(":"))
            except ValueError:
                continue
            at = time.mktime((lt.tm_year, lt.tm_mon, lt.tm_mday, hour, minute, 0, 0, 0, -1))
            if at <= now:
                at = time.mktime((lt.tm_year, lt.tm_mon, lt.tm_mday + 1, hour, minute, 0, 0, 0, -1))
            if not best or at < best:
                best = at
        return best

    def tick_schedule(self):
        now = time.time()
        at = self.next_restart(now)
        self.state["nextRestart"] = at
        if not at or not self.state["ready"]:
            return
        schedule = self.cfg["schedule"]
        message = schedule.get("message") or "Server restarts in {time}"
        left = at - now
        for seconds in schedule.get("warnings", []):
            key = (at, seconds)
            if left <= seconds and key not in self.warned:
                self.warned.add(key)
                #--- Only the one due now: a server started near a restart stays quiet
                if left > seconds - 5:
                    try:
                        servers.send(self.cfg, "say " + message.replace("{time}", wording(seconds)))
                    except servers.ServerError:
                        pass
        if left <= TICK * 2 and (at, "restart") not in self.warned:
            self.warned.add((at, "restart"))
            servers.restart(self.cfg)

    def reload_cfg(self):
        now = time.time()
        if now - self.timers["cfg"] < 3:
            return
        self.timers["cfg"] = now
        try:
            mtime = os.stat(servers.path(self.id)).st_mtime
            if mtime != self.cfg_mtime:
                self.cfg_mtime = mtime
                self.cfg = servers.load(self.id)
        except (OSError, servers.ServerError):
            pass

    #--------------------------------------------------------------------#
    #-- The socket
    #--------------------------------------------------------------------#

    def publish(self, message, clients=None):
        data = (json.dumps(message) + "\n").encode()
        for client in list(clients if clients is not None else self.clients):
            try:
                client.sendall(data)
            except OSError:
                self.drop(client)

    def drop(self, client):
        if client in self.clients:
            del self.clients[client]
            self.selector.unregister(client)
            client.close()

    def accept(self, listener):
        client, _ = listener.accept()
        client.settimeout(1)
        self.clients[client] = b""
        self.selector.register(client, selectors.EVENT_READ)
        self.publish({"type": "hello", "state": self.state, "lines": list(self.ring)[-HELLO_LINES:]}, [client])

    def request(self, client):
        try:
            chunk = client.recv(65536)
        except OSError:
            chunk = b""
        if not chunk:
            self.drop(client)
            return
        *lines, self.clients[client] = (self.clients[client] + chunk).split(b"\n")
        for line in lines:
            try:
                req = json.loads(line)
            except ValueError:
                continue
            if req.get("cmd") == "run":
                self.start_run(req.get("name", ""), req.get("steps", []))
            elif req.get("cmd") == "cancel":
                self.runs = [r for r in self.runs if r["id"] != req.get("id")]
            elif req.get("cmd") == "query":
                self.publish(self.query(str(req.get("command", ""))), [client])

    def query(self, text):
        """A read-only command's reply. It shares the poll's connection and thread, as two
        packets must never overlap (`src/rcon.py`)."""
        if not self.state["ready"] or not self.connect_rcon():
            return {"type": "reply", "ok": False}
        try:
            return {"type": "reply", "ok": True, "text": self.rcon.command(text)}
        except (OSError, rcon.RconError):
            self.rcon.close()
            self.rcon, self.rcon_retry = None, time.time() + 10
            return {"type": "reply", "ok": False}

    def flush(self):
        now = time.time()
        if self.fresh:
            shown = [e for e in self.fresh if not e.get("hidden")][-500:]
            if shown:
                self.publish({"type": "lines", "lines": shown})
            self.fresh = []
        if now - self.timers["state"] >= 1:
            self.timers["state"] = now
            self.publish({"type": "state", "state": self.state})

    #--------------------------------------------------------------------#
    #-- Main loop
    #--------------------------------------------------------------------#

    def learn_dim_names(self):
        """At shutdown: pair the IDs from the last poll with the names just logged."""
        names = logparse.pair_dim_names(self.tps_order, self.saved_names)
        if not names:
            return
        try:
            cfg = servers.load(self.id)
            cfg["dimAuto"] = names
            servers.save(cfg)
        except servers.ServerError:
            pass

    def run(self):
        os.makedirs(servers.RUNTIME, exist_ok=True)
        address = servers.monitor_socket(self.id)
        if os.path.exists(address):
            os.unlink(address)
        listener = socket.socket(socket.AF_UNIX)
        listener.bind(address)
        os.chmod(address, 0o600)
        listener.listen()
        self.selector = selectors.DefaultSelector()
        self.selector.register(listener, selectors.EVENT_READ)
        signal.signal(signal.SIGTERM, self.on_term)
        signal.signal(signal.SIGINT, self.on_term)
        while not self.stopping_flag:
            for key, _ in self.selector.select(TICK):
                if key.fileobj is listener:
                    self.accept(listener)
                else:
                    self.request(key.fileobj)
            self.reload_cfg()
            self.tail()
            self.poll()
            self.sample()
            self.tick_runs()
            self.tick_schedule()
            self.flush()
        self.tail()
        self.learn_dim_names()
        self.flush()
        listener.close()
        os.unlink(address)

    def on_term(self, *_):
        self.stopping_flag = True


def wording(seconds):
    if seconds >= 60:
        minutes = round(seconds / 60)
        return f"{minutes} minute{'s' if minutes != 1 else ''}"
    return f"{seconds} second{'s' if seconds != 1 else ''}"


def main():
    Monitor(sys.argv[1]).run()


if __name__ == "__main__":
    main()
