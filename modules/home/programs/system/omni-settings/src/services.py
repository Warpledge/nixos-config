"""Running Now on the Services page: whether each background service the
config can turn on is running, its last log lines, and a Restart button
(the logic is in servicestate.py)."""

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, GLib, Gtk, Pango  # noqa: E402

import servicestate  # noqa: E402
import ui  # noqa: E402
from servicestate import UNITS, journal, states  # noqa: E402


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
        if err is None:
            self.window.set_services_count(found)
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
            ok, detail = (False, str(err)) if err is not None else res
            self.window.toast(f"{name} restarted" if ok else f"{name}: {detail}")
            GLib.timeout_add(800, lambda: self.load() and False)
        ui.run_async(lambda: servicestate.restart(scope, unit), done)
