"""Running Now on the Services page: whether each background service the
config can turn on is running, its last log lines, and a Restart button.
Only services the running system has are listed. A system service's restart
goes through polkit, so DMS's password prompt asks for it."""

import subprocess

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, GLib, Gtk, Pango  # noqa: E402

import ui  # noqa: E402

#--- (name, "system" or "user", unit), from the modules under nixos/services
#--- and nixos/security; Sunshine and rootless Docker run per user
UNITS = [
    ("SSH", "system", "sshd.service"),
    ("Syncthing", "system", "syncthing.service"),
    ("Sunshine", "user", "sunshine.service"),
    ("Suwayomi", "system", "suwayomi-server.service"),
    ("FlareSolverr", "system", "flaresolverr.service"),
    ("Mullvad VPN", "system", "mullvad-daemon.service"),
    ("Docker", "system", "docker.service"),
    ("Docker (rootless)", "user", "docker.service"),
    ("ClamAV", "system", "clamav-daemon.service"),
]
LOG_LINES = 30


def systemctl(scope):
    return ["systemctl"] + (["--user"] if scope == "user" else [])


def states():
    """{(scope, unit): (ActiveState, SubState, since)} for the units that exist."""
    out = {}
    for scope in ("system", "user"):
        units = [u for _, s, u in UNITS if s == scope]
        try:
            res = subprocess.run(systemctl(scope) + ["show", "-p", "Id,LoadState,ActiveState,SubState,"
                                                     "ActiveEnterTimestamp", "--", *units],
                                 capture_output=True, text=True, timeout=10)
        except (OSError, subprocess.TimeoutExpired):
            continue
        for chunk in res.stdout.strip().split("\n\n"):
            props = dict(line.split("=", 1) for line in chunk.splitlines() if "=" in line)
            if props.get("LoadState") == "loaded":
                out[(scope, props["Id"])] = (props.get("ActiveState", ""), props.get("SubState", ""),
                                             props.get("ActiveEnterTimestamp", ""))
    return out


def journal(scope, unit):
    cmd = ["journalctl", "--no-pager", "-o", "short", "-n", str(LOG_LINES)]
    cmd += ["--user-unit", unit] if scope == "user" else ["-u", unit]
    res = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
    return (res.stdout or res.stderr).strip() or "No log lines yet."


class RunningGroup(Adw.PreferencesGroup):
    def __init__(self, window):
        super().__init__(title="Running Now",
                         description="The services this computer runs right now. Changes above "
                                     "show up here after Apply.")
        self.window = window
        self.rows = {}
        self.refresh = Gtk.Button(icon_name="view-refresh-symbolic", css_classes=["flat"],
                                  valign=Gtk.Align.CENTER, tooltip_text="Check again")
        self.refresh.connect("clicked", lambda _: self.load())
        self.set_header_suffix(self.refresh)
        self.placeholder = Adw.ActionRow(title="Checking…")
        self.add(self.placeholder)
        self.load()

    def load(self):
        ui.run_async(states, self._loaded)

    def _loaded(self, found, err):
        if self.placeholder is not None:
            self.remove(self.placeholder)
            self.placeholder = None
        if err is not None or not found:
            self.placeholder = Adw.ActionRow(title="None of them is on", subtitle=ui.esc(str(err or "")))
            self.add(self.placeholder)
            return
        for name, scope, unit in UNITS:
            key = (scope, unit)
            if key not in found:
                continue
            if key not in self.rows:
                self.rows[key] = self._row(name, scope, unit)
            self._state(key, *found[key])

    def _row(self, name, scope, unit):
        row = Adw.ExpanderRow(title=ui.esc(name), subtitle=ui.esc(unit + (" (yours)" if scope == "user" else "")))
        chip = ui.chip("", "neutral")
        restart = Gtk.Button(icon_name="view-refresh-symbolic", css_classes=["flat"], valign=Gtk.Align.CENTER,
                             tooltip_text="Restart it")
        restart.connect("clicked", lambda _: self._restart(name, scope, unit, restart))
        if scope == "system" and not self.window.admin:
            restart.set_sensitive(False)
            restart.set_tooltip_text("Only an admin can restart it")
        # An expander packs suffixes right to left
        row.add_suffix(restart)
        row.add_suffix(chip)
        log = Gtk.Label(xalign=0, wrap=True, wrap_mode=Pango.WrapMode.WORD_CHAR, selectable=True,
                        css_classes=["monospace", "doc-code"], label="Loading…")
        row.add_row(log)
        row.connect("notify::expanded", lambda r, _: r.get_expanded() and self._log(scope, unit, log))
        self.add(row)
        return row, chip

    def _state(self, key, active, sub, since):
        row, chip = self.rows[key]
        text, kind = {"active": ("Running", "success"), "failed": ("Failed", "error"),
                      "activating": ("Starting", "accent"), "deactivating": ("Stopping", "accent"),
                      "reloading": ("Reloading", "accent")}.get(active, ("Stopped", "neutral"))
        chip.set_label(text)
        chip.set_css_classes(["chip", kind])
        chip.set_tooltip_text(f"{active} ({sub})" + (f" since {since}" if since and active == "active" else ""))

    def _log(self, scope, unit, label):
        ui.run_async(lambda: journal(scope, unit),
                     lambda text, err: label.set_text(str(err) if err is not None else text))

    def _restart(self, name, scope, unit, button):
        button.set_sensitive(False)

        def done(res, err):
            button.set_sensitive(True)
            if err is not None or res.returncode != 0:
                detail = str(err) if err is not None else (res.stderr.strip() or "it didn't restart")
                self.window.toast(f"{name}: {detail}")
            else:
                self.window.toast(f"{name} restarted")
            GLib.timeout_add(800, lambda: self.load() and False)
        ui.run_async(lambda: subprocess.run(systemctl(scope) + ["restart", "--", unit], capture_output=True,
                                            text=True, timeout=120), done)
