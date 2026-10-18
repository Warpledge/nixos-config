"""One password per window. The root helper is started through pkexec the first
time it's needed and kept until the window closes or sits idle for IDLE seconds.
Requests reach it over a socket pair only this process holds (nothing on disk
to connect to), and each one runs helper.py afresh as root with its usual checks."""

import json
import re
import socket

from gi.repository import Gio, GLib

IDLE = 15 * 60
EXIT = re.compile(r'^@ns \{"exit": (-?\d+)\}$', re.M)


class Session:
    def __init__(self, helper):
        self.helper = helper
        self.ctl = None
        self.ready = False
        self.busy = 0
        self.timer = 0

    def _start(self):
        mine, theirs = socket.socketpair(socket.AF_UNIX, socket.SOCK_SEQPACKET)
        launcher = Gio.SubprocessLauncher.new(Gio.SubprocessFlags.STDOUT_SILENCE
                                              | Gio.SubprocessFlags.STDERR_SILENCE)
        launcher.take_stdin_fd(theirs.detach())
        pkexec = GLib.find_program_in_path("pkexec") or "/run/wrappers/bin/pkexec"
        try:
            launcher.spawnv([pkexec, self.helper, json.dumps({"session": True})])
        finally:
            launcher.close()  # this process keeps no copy of the helper's end
        self.ctl, self.ready = mine, False

    def close(self):
        """Drops the helper; a run already going finishes first."""
        if self.timer:
            GLib.source_remove(self.timer)
            self.timer = 0
        if self.ctl is not None:
            self.ctl.close()
            self.ctl = None

    def request(self, request):
        """Starts `request` as root; returns a Run, read like a Gio.Subprocess."""
        if self.timer:
            GLib.source_remove(self.timer)
            self.timer = 0
        mine, theirs = socket.socketpair()
        try:
            for attempt in (0, 1):
                if self.ctl is None:
                    self._start()
                try:
                    socket.send_fds(self.ctl, [json.dumps(request).encode()], [theirs.fileno()])
                    break
                except OSError:  # the helper behind it has gone; start another
                    self.close()
                    if attempt:
                        raise
        except OSError:
            mine.close()
            raise
        finally:
            theirs.close()
        self.busy += 1
        return Run(self, self.ctl, mine)

    def ran(self, ctl):
        """Whether the helper behind `ctl` got past the password prompt."""
        if ctl is not self.ctl:
            return True
        if not self.ready:
            try:
                self.ready = ctl.recv(16, socket.MSG_DONTWAIT) == b"ready"
            except OSError:
                pass
        if not self.ready:
            self.close()  # prompt closed or refused: ask again next time
        return self.ready

    def finished(self):
        self.busy -= 1
        if self.busy == 0 and self.ctl is not None and not self.timer:
            self.timer = GLib.timeout_add_seconds(IDLE, self._idle)

    def _idle(self):
        self.timer = 0
        self.close()
        return False


class Run:
    """One request: the part of Gio.Subprocess that RunView uses. The helper's
    exit code arrives as a last `@ns {"exit": N}` line."""

    def __init__(self, session, ctl, sock):
        self.session, self.ctl = session, ctl
        self.conn = Gio.Socket.new_from_fd(sock.detach()).connection_factory_create_connection()
        self.done = False

    def get_stdin_pipe(self):
        return self.conn.get_output_stream()

    def get_stdout_pipe(self):
        return self.conn.get_input_stream()

    def wait_async(self, _cancellable, callback):
        GLib.idle_add(lambda: callback(self, None) and False)

    def wait_finish(self, _res):
        if not self.done:
            self.done = True
            self.conn.close(None)
            self.session.finished()
        return True

    def get_if_exited(self):
        return True

    def get_exit_status(self):
        """Only asked for when no exit line came: 126, as pkexec gives, if the
        password prompt was closed."""
        return -1 if self.session.ran(self.ctl) else 126

    def communicate(self, callback):
        """Reads everything, then calls callback(exit code, text)."""
        data = bytearray()
        stream = self.get_stdout_pipe()

        def got(s, res):
            try:
                chunk = s.read_bytes_finish(res).get_data()
            except GLib.Error:
                chunk = b""
            if chunk:
                data.extend(chunk)
                s.read_bytes_async(65536, GLib.PRIORITY_DEFAULT, None, got)
                return
            self.wait_finish(None)
            text = data.decode("utf-8", "replace")
            m = EXIT.search(text)
            callback(int(m.group(1)) if m else self.get_exit_status(), EXIT.sub("", text))
        stream.read_bytes_async(65536, GLib.PRIORITY_DEFAULT, None, got)
