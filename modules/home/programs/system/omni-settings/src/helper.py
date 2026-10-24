"""omni-settings-apply: run as root by pkexec after the caller types their own
password. Builds this machine's system from the repo, shows what changes and
switches to it, printing progress for Omni Settings: nix's JSON log lines
(`@nix {...}`), the helper's own events (`@ns {...}`) and plain text.

Anyone on the machine may apply their own app settings: only template keys,
with the template's kind of value, in their own file or their own block in
the file of a machine that lists them. A change for another machine is only
saved; that machine picks it up when it rebuilds. Rebuilding as-is, and switching to an older version,
are for admins (wheel), who could run nixos-rebuild anyway.

Usage: omni-settings-apply '{"mode": "switch"|"boot", "machine": name|null,
                              "changes": [[["media", "mpv"], true], ...]}'
       (machine: whose block takes the changes; null for the caller's own file)
       omni-settings-apply '{"rebuild": true, "mode": "switch"|"boot"|"auto"|"build"}'
       omni-settings-apply '{"rebuild": true, "mode": ..., "newUser": name}'
       (stdin's first line: the first password for that newly listed person)
       omni-settings-apply '{"activate": "/nix/store/...", "mode": ...}'
       omni-settings-apply '{"collectGarbage": true}'
       omni-settings-apply '{"clean": true}'  (drop settings the templates lost)

"auto" switches now unless the new system changes a package that froze the
desktop when switched live (closure.CORE); then it's used from the next boot.
"build" builds and compares only, then puts back any settings it saved, so
nothing changes; the app's own writes are its to put back.
While building, a line "cancel" on stdin (or stdin closing) stops the build."""

import fcntl
import grp
import json
import os
import pwd
import re
import shlex
import signal
import subprocess
import sys
import threading

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))

import backend  # noqa: E402
import closure  # noqa: E402
import nixfile  # noqa: E402
import nixlog  # noqa: E402
import schema  # noqa: E402

LOCK = "/run/omni-settings-apply.lock"
RUN_DIR = "/run/omni-settings"
#--- The weekly nh clean job's own arguments (the wrapper reads nh.nix)
CLEAN_ARGS = shlex.split(os.environ.get("OMNI_SETTINGS_CLEAN_ARGS", "--keep-since 5d --keep 5"))
DELETED_SYSTEM = re.compile(r"^- DEL /nix/var/nix/profiles/system-\d+-link")
FREED = re.compile(r"(\d+) store paths deleted, ([\d.]+ \w+) freed")
#--- What nh and nixos-rebuild run switch-to-configuration with, so a lost
#--- session can't kill it halfway and two switches can't overlap
SYSTEMD_RUN = ["systemd-run", "-E", "LOCALE_ARCHIVE", "-E", "NIXOS_INSTALL_BOOTLOADER",
               "-E", "NIXOS_NO_CHECK", "--collect", "--no-ask-password", "--wait", "--verbose",
               "--output=cat", "--quiet", "--service-type=exec",
               "--unit=nixos-rebuild-switch-to-configuration"]


class Cancelled(Exception):
    pass


#--------------------------------------------------------------------#
#-- Output
#--------------------------------------------------------------------#
def out(line):
    """Prints one line; a closed pipe (the window went away) doesn't stop the work."""
    try:
        sys.stdout.write(line + "\n")
        sys.stdout.flush()
    except (BrokenPipeError, ValueError):
        pass


def emit(**event):
    out("@ns " + json.dumps(event))


def refuse(message):
    emit(error=message)
    out(f"error: {message}")
    sys.exit(2)


#--------------------------------------------------------------------#
#-- Cancelling
#--------------------------------------------------------------------#
class Canceller:
    """Watches stdin; "cancel" or end of input stops whatever `allow` names."""

    def __init__(self):
        self.proc = None
        self.allowed = False
        self.requested = False
        self.watching = False

    def watch(self):
        """Started with the first cancellable step, so a session's stdin is left alone."""
        if not self.watching:
            self.watching = True
            threading.Thread(target=self._watch, daemon=True).start()

    def _watch(self):
        try:
            for line in sys.stdin:
                if line.strip() == "cancel":
                    break
        except (OSError, ValueError):
            pass
        self.requested = True
        self._stop()

    def _stop(self):
        if self.allowed and self.proc is not None and self.proc.poll() is None:
            try:
                os.killpg(self.proc.pid, signal.SIGTERM)
            except OSError:
                pass

    def run(self, proc):
        self.watch()
        self.proc, self.allowed = proc, True
        if self.requested:
            self._stop()

    def done(self):
        self.proc, self.allowed = None, False


CANCEL = Canceller()


#--------------------------------------------------------------------#
#-- Steps
#--------------------------------------------------------------------#
def env():
    e = {"PATH": os.environ["PATH"], "HOME": "/root", "LANG": "C.UTF-8"}
    archive = "/run/current-system/sw/lib/locale/locale-archive"
    if os.path.exists(archive):
        e["LOCALE_ARCHIVE"] = archive
    return e


def stream(cmd, cancellable=False):
    """Runs `cmd`, passing its output on line by line; returns (exit code, lines)."""
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=env(),
                            start_new_session=True, text=True, errors="replace", bufsize=1)
    if cancellable:
        CANCEL.run(proc)
    lines = []
    for line in proc.stdout:
        line = line.rstrip("\n")
        lines.append(line)
        out(line)
    code = proc.wait()
    CANCEL.done()
    if cancellable and CANCEL.requested:
        raise Cancelled()
    return code, lines


def build(cfg, owner):
    """Builds the system; returns its store path. Nix's JSON log goes out as is."""
    emit(step="build", state="start")
    os.makedirs(RUN_DIR, mode=0o755, exist_ok=True)
    link = os.path.join(RUN_DIR, f"system-{owner}")
    target = f"{cfg.flake}#nixosConfigurations.{cfg.machine}.config.system.build.toplevel"
    cmd = ["nix", "build", target, "--log-format", "internal-json", "-v",
           "--out-link", link, "--print-out-paths"]
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env(),
                            start_new_session=True, text=True, errors="replace", bufsize=1)
    CANCEL.run(proc)
    for line in proc.stderr:
        out(line.rstrip("\n"))
    path = proc.stdout.read().strip().splitlines()
    code = proc.wait()
    CANCEL.done()
    if CANCEL.requested:
        raise Cancelled()
    if code != 0 or not path:
        emit(step="build", state="failed")
        raise RuntimeError("the build failed")
    emit(step="build", state="done", system=path[-1])
    return path[-1], link


def compare(path, mode):
    """Emits what changes; picks switch or boot for "auto"."""
    emit(step="compare", state="start")
    diff = closure.diff(closure.CURRENT, path)
    emit(diff=diff.as_json())
    old, new = closure.kernel(closure.BOOTED), closure.kernel(path)
    if old and new and old != new:
        emit(kernel=[old, new])
    if mode in ("auto", "build"):
        core = diff.core()
        if core:
            emit(boot=core, preview=mode == "build")
        if mode == "auto":
            mode = "boot" if core else "switch"
    emit(step="compare", state="done", mode=mode)
    return mode


def set_password(name, password):
    """Gives a newly listed person their first password; one they already have
    is left alone, so this can't change anyone's password."""
    emit(step="password", state="start")
    status = subprocess.run(["passwd", "-S", name], capture_output=True, text=True, env=env())
    fields = status.stdout.split()
    if status.returncode != 0 or len(fields) < 2:
        emit(step="password", state="failed")
        raise RuntimeError(f"there's no account for {name}; the rebuild didn't make one")
    if fields[1] == "P":
        emit(note=[f"{name} already has a password", "It was left as it was."])
    else:
        done = subprocess.run(["chpasswd"], input=f"{name}:{password}\n", capture_output=True, text=True,
                              env=env())
        if done.returncode != 0:
            emit(step="password", state="failed")
            raise RuntimeError(f"setting {name}'s password failed: {done.stderr.strip()}")
    emit(step="password", state="done")


def activate(path, mode):
    """Switches to `path` now and makes it the boot default, or (boot) only the latter."""
    if mode == "switch":
        emit(step="switch", state="start")
        code, _ = stream(SYSTEMD_RUN + [os.path.join(path, "bin/switch-to-configuration"), "test"])
        if code != 0:
            emit(step="switch", state="failed", code=code)
            raise RuntimeError("switching to the new system failed; it isn't added to the boot menu")
        emit(step="switch", state="done")
    emit(step="boot", state="start")
    code, _ = stream(["nix", "build", "--no-link", "--profile", closure.SYSTEM_PROFILE, path])
    if code == 0:
        code, _ = stream(SYSTEMD_RUN + [os.path.join(path, "bin/switch-to-configuration"), "boot"])
    if code != 0:
        emit(step="boot", state="failed", code=code)
        raise RuntimeError("adding the new system to the boot menu failed")
    emit(step="boot", state="done")


def collect():
    """Deletes old generations with the weekly nh clean job's arguments (every
    profile, home-manager's too), collects garbage, then rewrites the boot menu
    so it lists only versions that still exist."""
    emit(step="collect", state="start")
    code, lines = stream(["nh", "clean", "all", *CLEAN_ARGS])
    plain = [nixlog.strip_ansi(line).strip() for line in lines]
    if code != 0:
        emit(step="collect", state="failed")
        raise RuntimeError("cleaning up failed")
    freed = next((m for m in map(FREED.search, plain) if m), None)
    emit(step="collect", state="done")
    emit(step="boot", state="start")
    profile = os.path.realpath(closure.SYSTEM_PROFILE)
    code, _ = stream(SYSTEMD_RUN + [os.path.join(profile, "bin/switch-to-configuration"), "boot"])
    if code != 0:
        emit(step="boot", state="failed")
        raise RuntimeError("the boot menu wasn't updated")
    emit(step="boot", state="done")
    emit(cleaned={"versions": sum(1 for line in plain if DELETED_SYSTEM.match(line)),
                  "paths": int(freed.group(1)) if freed else 0,
                  "freed": freed.group(2) if freed else ""})


#--------------------------------------------------------------------#
#-- Requests
#--------------------------------------------------------------------#
def same_kind(template, value):
    if isinstance(template, bool):
        return isinstance(value, bool)
    if isinstance(template, list):
        return isinstance(value, list) and all(isinstance(v, str) for v in value)
    if template is None or isinstance(template, str):
        return value is None or isinstance(value, str)
    if isinstance(template, dict):
        return isinstance(value, dict) and all(isinstance(k, str) and k.strip() and same_kind([], v)
                                               for k, v in value.items())
    return False


#--- The fields a keybind change may set, as lib/settings.nix's keybindFields
KEYBIND_FIELDS = {"key": str, "title": str, "enable": bool, "spawn": list, "action": str, "argument": str}


def keybinds_ok(value):
    """Whether `value` is a set of keybind changes by id: a config bind's key, title
    or on/off, or a custom- bind's fields, each of its own kind."""
    if not isinstance(value, dict):
        return False
    for bind_id, b in value.items():
        if not (isinstance(bind_id, str) and re.fullmatch(r"[A-Za-z0-9_-]+", bind_id) and isinstance(b, dict)):
            return False
        allowed = KEYBIND_FIELDS if bind_id.startswith("custom-") else ("key", "title", "enable")
        for k, v in b.items():
            if k not in allowed or not isinstance(v, KEYBIND_FIELDS[k]):
                return False
            if k == "spawn" and not (v and all(isinstance(a, str) for a in v)):
                return False
    return True


def user_changes(cfg, raw):
    """The request's changes, refused unless each is a user template key with
    the template's kind of value."""
    if not isinstance(raw, list) or not raw:
        refuse("bad request")
    with open(os.path.join(cfg.flake, "users", "_template", "settings.nix")) as f:
        template = nixfile.to_python(nixfile.parse(f.read()).root)
    changes = {}
    for item in raw:
        if not (isinstance(item, list) and len(item) == 2 and isinstance(item[0], list)
                and item[0] and all(isinstance(k, str) for k in item[0])):
            refuse("bad request")
        path, value = item
        found, default = backend.lookup(template, path)
        if not found or path[0] in schema.HIDDEN or (isinstance(default, dict)
                                                     and tuple(path) not in schema.GROUPED):
            refuse(f"`{'.'.join(path)}` can't be changed here")
        if not (keybinds_ok(value) if tuple(path) == schema.KEYBINDS else same_kind(default, value)):
            refuse(f"`{'.'.join(path)}` got the wrong kind of value")
        changes[("user", tuple(path))] = value
    return changes


def clean(cfg):
    """Deletes settings the templates no longer have from the caller's own file and
    their block in this machine's file. The list is worked out here, never taken
    from the request, and machine settings are left to an admin."""
    if not os.path.exists(cfg.file("user")):
        refuse(f"there is no users/{cfg.user}/settings.nix")
    items = [(where, user, path) for where, user, path in backend.stale_settings(cfg)
             if where in ("user", "override") and user == cfg.user]
    for _, _, path in items:
        out(f"Removing {'.'.join(path)}")
    backend.remove_stale(cfg, items)


def generation_path(path):
    """`path` if it's one of this computer's system generations, else None."""
    if not isinstance(path, str):
        return None
    real = os.path.realpath(path)
    known = {g.path for g in closure.generations()}
    return real if real in known and closure.is_system(real) else None


def in_wheel(name, gid):
    try:
        wheel = grp.getgrnam("wheel").gr_gid
    except KeyError:
        return False
    return wheel in os.getgrouplist(name, gid)


def main():
    uid = os.environ.get("PKEXEC_UID")
    if os.geteuid() != 0 or uid is None:
        refuse("run this through pkexec")
    caller = pwd.getpwuid(int(uid))
    admin = in_wheel(caller.pw_name, caller.pw_gid)
    emit(step="auth", state="done")

    cfg = backend.Config(os.environ["OMNI_SETTINGS_FLAKE"], os.environ["OMNI_SETTINGS_MACHINE"],
                         caller.pw_name, os.environ["OMNI_SETTINGS_LIB"])
    try:
        request = json.loads(sys.argv[1])
    except (IndexError, ValueError):
        refuse("bad request")
    if not isinstance(request, dict):
        refuse("bad request")
    mode = request.get("mode", "switch")
    if mode not in ("switch", "boot", "auto", "build"):
        refuse("bad request")

    changes, system, target, new_user, password = None, None, None, None, None
    collecting = request.get("collectGarbage") is True
    if mode == "build" and (collecting or "activate" in request or "newUser" in request
                            or request.get("clean") is True):
        refuse("bad request")
    if request.get("clean") is True:
        pass
    elif collecting:
        if not admin:
            refuse("only an admin can clean up old versions")
    elif "activate" in request:
        if not admin:
            refuse("only an admin can switch to another version")
        system = generation_path(request["activate"])
        if system is None:
            refuse("that isn't one of this computer's system versions")
    elif request.get("rebuild") is True:
        if not admin:
            refuse("only an admin can rebuild without changes")
        if "newUser" in request:
            new_user = request["newUser"]
            if not isinstance(new_user, str) or not new_user:
                refuse("bad request")
            password = sys.stdin.readline().rstrip("\n")
            if not password:
                refuse("no password came with the new person")
    else:
        changes = user_changes(cfg, request.get("changes"))
        target = request.get("machine")
        if target is not None and not isinstance(target, str):
            refuse("bad request")
        if mode == "build" and target not in (None, cfg.machine):
            refuse("only this computer's changes can be previewed")

    with open(LOCK, "w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            refuse("another change is being applied; try again when it's done")
        if request.get("clean") is True:
            clean(cfg)
            return
        if collecting:
            try:
                collect()
            except Exception as e:  # noqa: BLE001
                emit(error=str(e))
                emit(result="failed", restored=False)
                sys.exit(1)
            emit(result="ok")
            return
        if system is None:
            try:
                state = backend.evaluate(cfg)
            except backend.SettingsError as e:
                refuse(f"the settings files don't evaluate right now:\n{e}")
            if caller.pw_name not in state["resolved"]["users"]:
                refuse(f"{caller.pw_name} isn't listed in machines/{cfg.machine}/settings.nix")
            if target is not None and target not in state["userMachines"]:
                refuse(f"{caller.pw_name} isn't listed in machines/{target}/settings.nix")
            if new_user is not None and new_user not in state["resolved"]["users"]:
                refuse(f"{new_user} isn't listed in machines/{cfg.machine}/settings.nix")
        old = None
        try:
            if changes:
                emit(step="save", state="start")
                old = backend.write(cfg, None, changes, target, state["userMachines"])
                emit(step="save", state="done")
                if target not in (None, cfg.machine):
                    emit(result="ok", mode="saved",
                         detail=f"Your changes take effect the next time {target} rebuilds.")
                    return
            link = None
            if system is None:
                system, link = build(cfg, caller.pw_name)
            mode = compare(system, mode)
            if mode == "build":
                if old:
                    backend.restore(cfg, old)
            else:
                activate(system, mode)
            if link:
                try:
                    os.unlink(link)
                except OSError:
                    pass
            if new_user is not None and mode == "boot":
                # The account is only made when the new system starts
                emit(note=[f"Set {new_user}'s password after the restart",
                           f"Run sudo passwd {new_user} once this computer has restarted."])
            elif new_user is not None:
                set_password(new_user, password)
            emit(result="ok", mode="built" if mode == "build" else mode)
        except Cancelled:
            if old:
                backend.restore(cfg, old)
            emit(result="cancelled", restored=bool(old))
            sys.exit(3)
        except backend.SettingsError as e:
            emit(step="save", state="failed")
            emit(error=f"these settings don't work, nothing was saved:\n{e}")
            emit(result="failed", restored=False)
            sys.exit(1)
        except Exception as e:  # noqa: BLE001
            if old:
                backend.restore(cfg, old)
            emit(error=str(e))
            emit(result="failed", restored=bool(old))
            sys.exit(1)


if __name__ == "__main__":
    main()
