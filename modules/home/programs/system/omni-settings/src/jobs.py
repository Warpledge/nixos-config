"""Omni Settings' job service: rebuilds, updates and clean-ups run here, a
systemd user service started by its socket, so hiding the panel or restarting
DMS doesn't end one. Front ends attach to the running job's progress and log.

Each job runs `pkexec omni-settings-apply` once and ends the root process with
it: nothing stays root between jobs, so the socket (owner-only) can't reach an
unlocked root session.

Newline-delimited JSON on the socket. Requests {"id", "cmd", "args"} get
{"id", "ok", "data" | "error"}; attached clients also get pushed events:
{"event": "job", "job": snapshot}, {"event": "log", "lines": [[style, text]]}
and {"event": "progress", ...} while a build runs. A front end sends
{"cmd": "shown", "args": {"shown": bool}} as its page goes on or off screen; a
job that finishes or fails while none is shown sends a silent notification."""

import asyncio
import json
import os
import socket
import subprocess
import sys
import time
from collections import deque

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))

import api  # noqa: E402
import backend  # noqa: E402
import gitstate  # noqa: E402
import nixfile  # noqa: E402
import nixlog  # noqa: E402
import peoplestate  # noqa: E402
import system  # noqa: E402

STEPS = {
    "write": "Save and check your settings",
    "update": "Get the newest versions",
    "pull": "Get the config's new commits",
    "auth": "Confirm it's you",
    "save": "Save and check your settings",
    "build": "Build the new system",
    "compare": "Compare with what's running",
    "switch": "Switch to the new system",
    "boot": "Add it to the boot menu",
    "collect": "Delete old versions and unused files",
    "password": "Set their password",
}
#--- Jobs whose success commits and pushes the user's own folders (gitstate.back_up)
BACKED_UP = ("apply", "rebuild", "update", "pull")
LOG_LIMIT = 6000  # lines kept for a client attaching late
PROGRESS_EVERY = 0.5  # seconds between progress events
#--- Exits once no job runs and no client is attached for this long; a
#--- finished job nobody dismissed keeps it up to KEEP_FINISHED
IDLE = 60
KEEP_FINISHED = 30 * 60

#--- The last failed run, kept for the Overview
FAILED_LOG = os.path.join(api.STATE_DIR, "last-failed-run.txt")
FAILED_ERRORS = os.path.join(api.STATE_DIR, "last-failed-errors.txt")


def save_failed(title, heading, reason, log, errors):
    try:
        os.makedirs(os.path.dirname(FAILED_LOG), exist_ok=True)
        with open(FAILED_LOG, "w") as f:
            f.write(f"{title}\n{time.time():.0f}\n{heading}\n{reason}\n\n{log}")
        with open(FAILED_ERRORS, "w") as f:
            f.write(errors)
    except OSError:
        pass


def last_failed():
    """(title, epoch, heading, reason, log, errors) of the last failed run, or None."""
    try:
        with open(FAILED_LOG, errors="replace") as f:
            title, when, heading, rest = f.read().split("\n", 3)
        reason, _, log = rest.partition("\n\n")
        when = float(when)
    except (OSError, ValueError):
        return None
    try:
        with open(FAILED_ERRORS, errors="replace") as f:
            errors = f.read()
    except OSError:
        errors = ""
    return title, when, heading, reason, log, errors


class JobError(Exception):
    pass


#--------------------------------------------------------------------#
#-- Jobs
#--------------------------------------------------------------------#
class Job:
    def __init__(self, service, jid, kind, title, steps, done, titles=None):
        self.service = service
        self.id, self.kind, self.title, self.done_message = jid, kind, title, done
        self.steps = {s: {"id": s, "title": (titles or {}).get(s, STEPS[s]), "state": "waiting",
                          "detail": ""} for s in steps}
        self.started, self.ended = time.time(), None
        self.outcome = self.heading = self.detail = None
        self.mode, self.preview = "", False
        self.result, self.exit_code = {}, None
        self.errors, self.notes, self.diff, self.units = [], [], None, None
        self.restart, self.cleaned, self.deleted = False, None, 0
        self.undo = self.undo_label = self.restore = None
        self.log = deque(maxlen=LOG_LIMIT)
        self.progress = nixlog.Progress()
        self.proc, self.current, self.switch_lines = None, None, []
        self.pending_lines, self.progress_dirty = [], False

    #--- State
    def snapshot(self):
        return {"id": self.id, "kind": self.kind, "title": self.title, "done": self.done_message,
                "steps": list(self.steps.values()), "current": self.current,
                "started": self.started, "ended": self.ended, "outcome": self.outcome,
                "heading": self.heading, "detail": self.detail, "mode": self.mode,
                "preview": self.preview, "errors": list(dict.fromkeys(self.errors)),
                "notes": self.notes, "diff": self.diff, "units": self.units, "restart": self.restart,
                "cancellable": self.proc is not None and self.current == "build" and self.ended is None,
                "undo": self.undo_label if self.undo is not None and self.outcome in ("failed",) else None}

    def progress_json(self):
        p = self.progress
        return {"evaluating": p.evaluating, "evalFiles": p.eval_files,
                "downloads": [p.copies[0], max(p.copies[1], p.will_fetch)],
                "bytes": [p.downloaded(), p.download_total()],
                "builds": [p.builds[0], max(p.builds[1], p.will_build), p.builds[2]],
                "fraction": p.fraction(), "running": p.running(), "deleted": self.deleted,
                "graph": [] if p.evaluating else p.graph()}

    def changed(self):
        self.service.broadcast({"event": "job", "job": self.snapshot()})

    def step(self, sid, state, detail=None):
        if sid not in self.steps:
            return
        self.steps[sid]["state"] = state
        if detail is not None:
            self.steps[sid]["detail"] = detail
        if state == "running":
            self.current = sid
        self.changed()

    def append(self, style, text):
        self.log.append([style, text])
        self.pending_lines.append([style, text])

    def note(self, icon, title, subtitle):
        self.notes.append({"icon": icon, "title": title, "subtitle": subtitle})

    #--- Reading the helper
    def line(self, line):
        kind, data = nixlog.split(line)
        if kind == "nix":
            for style, text in self.progress.feed(data):
                self.append(style, text)
            self.progress_dirty = True
            if data.get("action") == "msg" and data.get("level") == nixlog.ERROR:
                self.errors.append(nixlog.strip_ansi(data.get("msg", "")))
        elif kind == "ns":
            self.event(data)
        else:
            text = nixlog.strip_ansi(line)
            if self.current == "collect" and text.startswith("deleting '/nix/store/"):
                self.deleted += 1  # thousands of these; counted, not logged
                self.progress_dirty = True
                return
            if self.current in ("switch", "boot"):
                self.switch_lines.append(text)
            if text.strip():
                self.append("error" if text.startswith("error") else "info", text)

    def event(self, e):
        if "step" in e:
            state = {"start": "running", "done": "done", "failed": "failed"}.get(e.get("state"), "running")
            sid = e["step"]
            if sid == "compare" and state == "done":
                self.mode = e.get("mode", self.mode)
                if self.mode == "boot" and "switch" in self.steps:
                    self.steps["switch"].update(state="skipped", detail="Used from the next restart instead")
            if sid == "save" and state == "running" and "auth" in self.steps:
                self.steps["auth"]["state"] = "done"
            if sid == "switch" and state in ("done", "failed"):
                self.units = nixlog.unit_changes(self.switch_lines)
            self.step(sid, state)
        if "diff" in e:
            self.diff = e["diff"]
        if "kernel" in e:
            old, new = e["kernel"]
            self.note("system-reboot-symbolic", f"New kernel: Linux {old} → {new}",
                      "The new kernel is used from the next restart.")
            self.restart = True
        if "boot" in e and e.get("preview"):
            self.note("dialog-warning-symbolic", "Would start at the next restart",
                      "This changes " + ", ".join(e["boot"]) + ". Switching to those while logged "
                      "in has frozen the desktop before, so Apply Now would set it up for the "
                      "next restart instead.")
        elif "boot" in e:
            self.note("dialog-warning-symbolic", "Set up for the next restart",
                      "This update changes " + ", ".join(e["boot"]) + ". Switching to those "
                      "while logged in has frozen the desktop before, so the new system "
                      "starts at the next restart instead.")
        if "note" in e:
            self.note("dialog-information-symbolic", *e["note"])
        if "cleaned" in e:
            self.cleaned = e["cleaned"]
            versions, freed = self.cleaned.get("versions", 0), self.cleaned.get("freed", "")
            self.note("user-trash-symbolic", f"Freed {freed}" if freed else "Nothing to free",
                      f"{self.cleaned.get('paths', 0):,} unused files deleted from the Nix store")
            self.note("edit-delete-symbolic",
                      f"{versions} old system version{'s' if versions != 1 else ''} deleted",
                      "The boot menu now lists only the versions that are left.")
            self.append("info", f"Deleted {self.deleted:,} store paths.")
        if "error" in e:
            self.errors.append(e["error"])
            self.append("error", e["error"])
        if "exit" in e:
            self.exit_code = e["exit"]
        if "result" in e:
            self.result = e
            if e.get("mode"):
                self.mode = e["mode"]
        self.changed()

    #--- Ending
    def exited(self, code):
        if self.exit_code is not None:
            code = self.exit_code
        result = self.result.get("result")
        if self.cleaned is not None and result == "ok":
            freed = self.cleaned.get("freed")
            self.finish("ok", "Cleaned up", f"Freed {freed} of disk space." if freed
                        else "Nothing was old enough or unused, so no space was freed.")
        elif result == "ok" and self.mode == "saved":
            self.finish("ok", "Saved", self.result.get("detail", "Your changes were saved."))
        elif result == "ok" and self.mode == "built":
            self.finish("ok", "Preview ready", "It built, and nothing was switched or kept. "
                                               "What it would change is below.")
        elif result == "ok" or (result is None and code == 0):
            boot = self.mode == "boot"
            self.restart = self.restart or boot
            heading = "Ready after a restart" if boot else "All done"
            detail = ("The new system starts the next time you restart." if boot
                      else "Your system is running the new settings.")
            if self.restart and not boot:
                detail += " Restart to use the new kernel."
            self.finish("ok", heading, detail)
        elif result == "cancelled":
            self.finish("cancelled", "Stopped", "The build was stopped and nothing was switched."
                        + (" Your settings were put back." if self.result.get("restored") else ""))
        elif result is None and code in (126, 127):
            self.finish("auth", "Nothing was changed",
                        "The password prompt was closed, or the password wasn't accepted.")
        else:
            reason = self.reason()
            if self.result.get("restored"):
                reason += "\n\nYour settings were put back the way they were."
            elif self.undo is not None:
                reason += "\n\nYour changes are still in the files, but the system wasn't rebuilt with them."
            self.finish("failed", self.failed_heading(), reason)

    def failed_heading(self):
        for sid in ("write", "update", "pull", "save", "build", "switch", "boot"):
            step = self.steps.get(sid)
            if step is not None and step["state"] == "failed":
                return {"write": "These settings don't work", "update": "Couldn't update flake.lock",
                        "pull": "Couldn't get the new commits",
                        "save": "These settings don't work", "build": "The build failed",
                        "switch": "Switching failed", "boot": "The boot menu wasn't updated"}[sid]
        return "Something went wrong"

    def reason(self):
        text = "\n\n".join(dict.fromkeys(self.errors))
        failed = [n for n in self.progress.errors if "failed" in n.lower()]
        line = nixlog.first_error(failed[0] if failed else text)
        m = nixlog.BUILDER_FAILED.search(line)
        if m:
            code = f" (exit code {m.group(2)})" if m.group(2) else ""
            return f"{nixlog.store_name(m.group(1))} failed to build{code}. The error is below."
        return line or "The details are in the log."

    def finish(self, outcome, heading, detail):
        self.outcome, self.heading, self.detail = outcome, heading, detail
        self.ended = time.time()
        for step in self.steps.values():
            if step["state"] == "running":
                step["state"] = "failed" if outcome == "failed" else "skipped"
        # A preview always puts back what it wrote; a run stopped before it
        # built anything does too
        if self.restore is not None:
            self.restore()
            self.restore = None
        if outcome in ("auth", "cancelled") and self.undo is not None:
            self.append("info", self.undo())
            self.undo = None
        if outcome == "ok":
            self.undo = None
            if not self.preview and self.kind in BACKED_UP:
                self.service.back_up(self)
        # The last graph stays at the end of the log, as nom leaves it in a terminal
        if not self.progress.evaluating:
            for row in self.progress.graph(final=True):
                self.append("graph", "".join(text for text, _ in row))
        if outcome == "failed":
            save_failed(self.title, heading, detail, "\n".join(t for _, t in self.log),
                        "\n\n".join(dict.fromkeys(self.errors)))
        if outcome in ("ok", "failed"):
            self.service.notify(f"{self.title}: {heading}", detail)
        self.service.flush()
        self.changed()


#--------------------------------------------------------------------#
#-- Starting Jobs
#--------------------------------------------------------------------#
def installed_exec_start():
    """The ExecStart of the installed unit, which names this service's build."""
    config = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")
    try:
        with open(os.path.join(config, "systemd/user/omni-settings-jobs.service")) as f:
            return next((line for line in f if line.startswith("ExecStart=")), None)
    except OSError:
        return None


def tail(preview):
    return ["build", "compare"] if preview else ["build", "compare", "switch", "boot"]


def mode_arg(args, allowed=("switch", "boot", "build")):
    mode = args.get("mode", "switch")
    if mode not in allowed:
        raise JobError(f"bad mode: {mode}")
    return mode


class Service:
    def __init__(self):
        self.cfg = backend.Config.from_env()
        self.clients = set()
        self.shown = set()  # clients whose page is on screen
        self.job, self.count, self.starting = None, 0, False
        self.idle_since = time.monotonic()
        self.exec_start, self.ticks = installed_exec_start(), 0

    #--- Clients
    def broadcast(self, msg):
        self.flush()
        self._send_all(msg)

    def _send_all(self, msg):
        data = (json.dumps(msg) + "\n").encode()
        for w in list(self.clients):
            try:
                w.write(data)
            except (ConnectionError, RuntimeError):
                self.clients.discard(w)

    def notify(self, summary, body):
        """A silent desktop notification, only while no front end is on screen."""
        if self.shown:
            return
        try:
            # "--" so busctl doesn't read the -1 timeout as an option
            subprocess.Popen(["busctl", "--user", "call", "--", "org.freedesktop.Notifications",
                              "/org/freedesktop/Notifications", "org.freedesktop.Notifications",
                              "Notify", "susssasa{sv}i", "Omni Settings", "0",
                              os.environ.get("OMNI_SETTINGS_ICON", ""), summary, body, "0",
                              "1", "suppress-sound", "b", "true", "-1"],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except OSError:
            pass

    def back_up(self, job):
        """Commits and pushes this machine's and user's folders in the background."""
        cfg = self.cfg

        async def work():
            note = await asyncio.get_running_loop().run_in_executor(
                None, gitstate.back_up, cfg.flake, cfg.machine, [f"machines/{cfg.machine}", f"users/{cfg.user}"])
            if note:
                job.append("info", note)
                self.flush()
        try:
            asyncio.get_running_loop().create_task(work())
        except RuntimeError:
            pass

    def flush(self):
        """Sends log lines gathered since the last flush."""
        job = self.job
        if job is not None and job.pending_lines:
            lines, job.pending_lines = job.pending_lines, []
            self._send_all({"event": "log", "id": job.id, "lines": lines})

    async def ticker(self):
        """Log lines and progress go out in batches, not one event per line."""
        while True:
            await asyncio.sleep(PROGRESS_EVERY)
            self.flush()
            job = self.job
            if job is not None and job.progress_dirty and job.ended is None:
                job.progress_dirty = False
                self._send_all({"event": "progress", "id": job.id, "progress": job.progress_json()})
            # A front end stays attached, so a newer build wouldn't start
            # otherwise; with no job left to show, the socket starts it next time
            self.ticks += 1
            if job is None and self.ticks % 20 == 0 and installed_exec_start() != self.exec_start:
                os._exit(0)
            if self.clients or (job is not None and job.ended is None):
                self.idle_since = time.monotonic()
            elif time.monotonic() - self.idle_since > IDLE and (
                    job is None or time.time() - job.ended > KEEP_FINISHED):
                os._exit(0)

    async def client(self, reader, writer):
        self.clients.add(writer)
        try:
            while True:
                raw = await reader.readline()
                if not raw:
                    break
                try:
                    req = json.loads(raw)
                    rid, cmd, args = req.get("id"), req.get("cmd"), req.get("args") or {}
                except (ValueError, AttributeError):
                    continue
                try:
                    if cmd == "shown":
                        # The front end's page went on or off screen
                        (self.shown.add if args.get("shown") else self.shown.discard)(writer)
                    data = True if cmd == "shown" else await self.command(cmd, args)
                    reply = {"id": rid, "ok": True, "data": data}
                except (JobError, backend.SettingsError, system.UpdateError, OSError, ValueError) as e:
                    reply = {"id": rid, "ok": False, "error": str(e)}
                writer.write((json.dumps(reply) + "\n").encode())
                if cmd == "attach" and self.job is not None:
                    writer.write((json.dumps({"event": "log", "id": self.job.id,
                                              "lines": list(self.job.log)}) + "\n").encode())
                    writer.write((json.dumps({"event": "progress", "id": self.job.id,
                                              "progress": self.job.progress_json()}) + "\n").encode())
                await writer.drain()
        except (ConnectionError, asyncio.LimitOverrunError, ValueError):
            pass
        finally:
            self.clients.discard(writer)
            self.shown.discard(writer)
            writer.close()

    async def command(self, cmd, args):
        job = self.job
        if cmd in ("status", "attach"):
            return job.snapshot() if job is not None else None
        if cmd == "start":
            if job is not None and job.ended is None:
                raise JobError("another job is running; wait for it to finish")
            if self.starting:
                raise JobError("another job is starting")
            self.starting = True
            try:
                return (await self.start(args.get("kind"), args)).snapshot()
            finally:
                self.starting = False
        if cmd == "cancel":
            if job is None or job.proc is None or job.ended is not None:
                raise JobError("nothing to stop")
            job.proc.stdin.write(b"cancel\n")
            return True
        if cmd == "undo":
            if job is None or job.undo is None or job.ended is None:
                raise JobError("nothing to undo")
            message = job.undo()
            job.undo = None
            job.changed()
            return message
        if cmd == "dismiss":
            if job is not None and job.ended is not None:
                self.job = None
            return True
        raise JobError(f"unknown command: {cmd}")

    def new_job(self, kind, title, steps, done, titles=None):
        self.count += 1
        self.job = Job(self, self.count, kind, title, steps, done, titles)
        return self.job

    async def start(self, kind, args):
        """Sets up a job and starts it running; returns it once it has started."""
        loop = asyncio.get_running_loop()
        cfg = self.cfg
        if kind == "apply":
            state = await loop.run_in_executor(None, api.loaded, cfg)
            admin, direct = api.access(cfg, state)
            if admin and not direct:
                raise JobError(f"You can't edit the files in {cfg.flake}")
            changes, machine = api.changes_arg(args), args.get("machine", cfg.machine)
            if not changes:
                raise JobError("nothing to apply")
            mode = mode_arg(args)
            preview = mode == "build"
            elsewhere = machine not in (None, cfg.machine) and all(d == "user" for d, _ in changes)
            if direct and elsewhere:
                raise JobError("another computer's changes are saved, not applied (api save)")
            title = "Previewing Changes" if preview else "Applying Changes"
            if direct:
                job = self.new_job(kind, title, ["write", "auth"] + tail(preview), "Changes applied")
                job.preview = preview
                job.step("write", "running")
                try:
                    old = await loop.run_in_executor(None, backend.write, cfg, state, changes, machine,
                                                     state.user_machines)
                except (backend.SettingsError, nixfile.NixError, OSError) as e:
                    job.errors.append(str(e))
                    job.step("write", "failed")
                    job.finish("failed", "These settings don't work", f"Nothing was saved.\n\n{e}")
                    return job
                job.step("write", "done")
                restore = lambda: (backend.restore(cfg, old), "Your settings are back how they were")[1]
                if preview:
                    job.restore = lambda: restore() and None
                else:
                    job.undo, job.undo_label = restore, "Undo My Changes"
                await self.run(job, {"rebuild": True, "mode": mode})
                return job
            steps = ["auth", "save"] if elsewhere else ["auth", "save"] + tail(preview)
            job = self.new_job(kind, "Saving Changes" if elsewhere else title, steps,
                               f"Saved for {machine}" if elsewhere else "Changes applied")
            job.preview = preview
            await self.run(job, {"mode": mode, "machine": machine,
                                 "changes": [[list(path), value] for (_, path), value in changes.items()]})
            return job
        if kind == "rebuild":
            mode = mode_arg(args)
            preview = mode == "build"
            job = self.new_job(kind, "Previewing a Rebuild" if preview else "Rebuilding",
                               ["auth"] + tail(preview), "Built" if preview else "Rebuilt")
            job.preview = preview
            await self.run(job, {"rebuild": True, "mode": mode})
            return job
        if kind == "update":
            mode = mode_arg(args, ("auto", "boot", "build"))
            preview = mode == "build"
            names, lock = args.get("inputs"), args.get("lock")
            if lock is not None and os.path.dirname(os.path.realpath(lock)) != system.runtime_dir():
                raise JobError("the new lock file must come from check_updates")
            if not names and lock is None:
                raise JobError("pick at least one source to update")
            job = self.new_job(kind, "Previewing the Update" if preview else "Updating",
                               ["update", "auth"] + tail(preview), "System updated")
            job.preview = preview
            job.step("update", "running", f"Getting the newest {', '.join(names)}" if names
                     else "Writing the new versions into flake.lock")

            def work():
                return system.apply_lock(cfg.flake, system.partial_lock(cfg.flake, names) if names else lock)
            try:
                old = await loop.run_in_executor(None, work)
            except (system.UpdateError, OSError) as e:
                job.errors.append(str(e))
                job.step("update", "failed", str(e))
                job.finish("failed", "Couldn't update flake.lock", str(e))
                return job
            job.step("update", "done", "flake.lock now names the new versions")
            restore = lambda: (system.restore_lock(cfg.flake, old), "flake.lock is back how it was")[1]
            if preview:
                job.restore = lambda: restore() and None
            else:
                job.undo, job.undo_label = restore, "Undo the Update"
            await self.run(job, {"rebuild": True, "mode": mode})
            return job
        if kind == "pull":
            state = await loop.run_in_executor(None, api.loaded, cfg)
            if api.access(cfg, state) != (True, True):
                raise JobError("Only an admin can pull the config")
            mode = mode_arg(args, ("auto", "boot", "build"))
            preview = mode == "build"
            job = self.new_job(kind, "Previewing the Pull" if preview else "Pulling",
                               ["pull", "auth"] + tail(preview), "Config pulled")
            job.preview = preview
            job.step("pull", "running", "Rebasing your commits onto the new ones")
            try:
                old, lock = await loop.run_in_executor(None, gitstate.pull, cfg.flake)
            except gitstate.PullError as e:
                job.errors.append(str(e))
                job.step("pull", "failed", str(e))
                job.finish("failed", "Couldn't get the new commits", str(e))
                return job
            job.step("pull", "done", "The config has the new commits"
                     + (", with their flake.lock in place of yours" if lock is not None else ""))
            restore = lambda: (gitstate.unpull(cfg.flake, old, lock), "The config is back how it was")[1]
            if preview:
                job.restore = lambda: restore() and None
            else:
                job.undo, job.undo_label = restore, "Undo the Pull"
            await self.run(job, {"rebuild": True, "mode": mode})
            return job
        if kind == "activate":
            mode = mode_arg(args, ("auto", "boot"))
            number = args.get("number", "")
            job = self.new_job(kind, f"Switching to Version {number}", ["auth", "compare", "switch", "boot"],
                               f"Switched to version {number}")
            await self.run(job, {"activate": args.get("generation"), "mode": mode})
            return job
        if kind == "collect":
            job = self.new_job(kind, "Cleaning Up", ["auth", "collect", "boot"], "Cleaned up",
                               titles={"boot": "Update the boot menu"})
            await self.run(job, {"collectGarbage": True})
            return job
        if kind == "clean":
            job = self.new_job(kind, "Removing Old Settings", ["auth"], "Old settings removed")
            await self.run(job, {"clean": True})
            return job
        if kind == "person":
            state = await loop.run_in_executor(None, api.loaded, cfg)
            if api.access(cfg, state) != (True, True):
                raise JobError("Only an admin can add people")
            name, password = args.get("name", "").strip(), args.get("password", "")
            if not password:
                raise JobError("Type their first password")
            job = self.new_job(kind, f"Adding {name}",
                               ["write", "auth", "build", "compare", "switch", "boot", "password"],
                               f"{name} can log in now", titles={"write": "Write their settings"})
            job.step("write", "running")
            try:
                undo = await loop.run_in_executor(None, peoplestate.add, cfg, state, name,
                                                  bool(args.get("admin")), args.get("gitName", "").strip(),
                                                  args.get("gitEmail", "").strip())
            except peoplestate.AddError as e:
                job.errors.append(str(e))
                job.step("write", "failed")
                job.finish("failed", f"Couldn't add {name}", str(e))
                return job
            job.step("write", "done")
            job.undo, job.undo_label = undo, f"Take {name} Off Again"
            # The password goes on the helper's stdin, never in its arguments
            await self.run(job, {"rebuild": True, "mode": "auto", "newUser": name}, password + "\n")
            return job
        raise JobError(f"unknown job: {kind}")

    async def run(self, job, request, first_line=None):
        """Starts the helper for `request`, writing `first_line` to its stdin;
        its output is read in the background."""
        job.step("auth", "running")
        helper = api.helper()
        if helper is None:
            job.finish("failed", "Couldn't start", "The Omni Settings helper isn't installed.")
            return
        pkexec = "/run/wrappers/bin/pkexec" if os.path.exists("/run/wrappers/bin/pkexec") else "pkexec"
        try:
            job.proc = await asyncio.create_subprocess_exec(
                pkexec, helper, json.dumps(request), stdin=asyncio.subprocess.PIPE,
                stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.STDOUT, limit=1 << 22)
        except OSError as e:
            job.append("error", str(e))
            job.finish("failed", "Couldn't start the rebuild", str(e))
            return
        if first_line is not None:
            job.proc.stdin.write(first_line.encode())
            await job.proc.stdin.drain()
        asyncio.get_running_loop().create_task(self.read(job))

    async def read(self, job):
        proc = job.proc
        while True:
            try:
                raw = await proc.stdout.readline()
            except (ValueError, asyncio.LimitOverrunError):
                continue
            if not raw:
                break
            try:
                job.line(raw.decode("utf-8", "replace").rstrip("\r\n"))
            except Exception as e:  # noqa: BLE001
                job.append("warning", f"(couldn't read a line: {e})")
        code = await proc.wait()
        if proc.stdin is not None:
            proc.stdin.close()
        job.exited(code)


#--------------------------------------------------------------------#
#-- Main
#--------------------------------------------------------------------#
def listening():
    """The socket systemd passed in, or one bound here when run by hand."""
    if os.environ.get("LISTEN_PID") == str(os.getpid()) and os.environ.get("LISTEN_FDS") == "1":
        return socket.socket(fileno=3)
    path = os.path.join(system.runtime_dir(), "jobs.sock")
    try:
        os.unlink(path)
    except OSError:
        pass
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    old = os.umask(0o177)
    try:
        sock.bind(path)
    finally:
        os.umask(old)
    sock.listen()
    return sock


async def main():
    service = Service()
    server = await asyncio.start_unix_server(service.client, sock=listening(), limit=1 << 20)
    asyncio.get_running_loop().create_task(service.ticker())
    async with server:
        await server.serve_forever()


if __name__ == "__main__":
    asyncio.run(main())
