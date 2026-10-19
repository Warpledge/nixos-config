"""The Servers tab's Minecraft page. Each server module writes a description
of itself to ~/.config/nixos-settings/servers/<name>.json (machines/legion/
minecraft-servers/), so the page follows the servers the computer has. A
server is its own command (`gtnh`, `tfg`): run bare it starts the server in
tmux and attaches, `status`, `stop` and `log` do the rest."""

import json
import os
import subprocess
from dataclasses import dataclass

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gio, GLib, Gtk  # noqa: E402

import ui  # noqa: E402

MANIFESTS = os.path.join(GLib.get_user_config_dir(), "nixos-settings", "servers")
POLL = 5  # seconds between status checks while the page is shown


@dataclass
class Server:
    name: str
    version: str
    command: str
    folder: str  # under the home folder
    docs: str  # its folder under docs/gaming/minecraft_servers, or ""


def servers():
    try:
        names = sorted(n for n in os.listdir(MANIFESTS) if n.endswith(".json"))
    except OSError:
        return []
    out = []
    for n in names:
        try:
            with open(os.path.join(MANIFESTS, n)) as f:
                d = json.load(f)
            out.append(Server(d["name"], d.get("version", ""), d["command"], d.get("folder", ""),
                              d.get("docs", "")))
        except (OSError, ValueError, KeyError, TypeError):
            continue
    return out


def running(command):
    """Whether the server's tmux session is up, from its own `status`."""
    try:
        out = subprocess.run([command, "status"], capture_output=True, text=True, timeout=5)
    except (OSError, subprocess.TimeoutExpired):
        return None
    return "is running" in out.stdout


class ServersPage(Adw.PreferencesPage):
    def __init__(self, window):
        super().__init__()
        self.window = window
        self.rows = {}
        self.timer = 0
        top = Adw.PreferencesGroup()
        top.add(ui.hero(ui.first_icon("network-server-symbolic"), "Minecraft Servers",
                        "Start, stop and watch the servers this computer hosts. Each runs in its own "
                        "terminal session, which keeps going when the window is closed."))
        self.add(top)

        found = [s for s in servers() if GLib.find_program_in_path(s.command)]
        group = Adw.PreferencesGroup(title="Servers")
        if not found:
            group.add(Adw.ActionRow(title="No servers on this computer",
                                    subtitle="Servers are set up in machines/<name>/minecraft-servers/."))
        for s in found:
            group.add(self._row(s))
        self.add(group)
        self.connect("map", lambda *_: self._start_polling())
        self.connect("unmap", lambda *_: self._stop_polling())

    def _row(self, s):
        sub = "\n".join(p for p in (s.version and f"Version {s.version}", f"~/{s.folder}" if s.folder else "")
                        if p)
        row = Adw.ActionRow(title=ui.esc(s.name), subtitle=ui.esc(sub), subtitle_lines=4)
        row.add_prefix(Gtk.Image(icon_name=ui.first_icon("network-server-symbolic"), valign=Gtk.Align.CENTER))
        state = ui.chip("Checking…", "neutral")
        row.add_suffix(state)
        console = Gtk.Button(label="Start", valign=Gtk.Align.CENTER, css_classes=["suggested-action"],
                             tooltip_text="Start the server and open its console")
        console.connect("clicked", lambda _: self._terminal([s.command]))
        stop = Gtk.Button(icon_name=ui.first_icon("media-playback-stop-symbolic"), valign=Gtk.Align.CENTER,
                          css_classes=["flat"], tooltip_text="Stop the server", visible=False)
        stop.connect("clicked", lambda _: self._stop(s))
        menu = Gio.Menu()
        menu.append("Follow the Log", f"server.log::{s.command}")
        if s.folder:
            menu.append("Open the Server Folder", f"server.folder::{s.command}")
        if s.docs:
            menu.append("Open Its Notes", f"server.notes::{s.command}")
        more = Gtk.MenuButton(icon_name="view-more-symbolic", menu_model=menu, valign=Gtk.Align.CENTER,
                              css_classes=["flat"], tooltip_text="More")
        for w in (console, stop, more):
            row.add_suffix(w)
        self.rows[s.command] = (s, state, console, stop)
        if len(self.rows) == 1:
            self._actions()
        return row

    def _actions(self):
        group = Gio.SimpleActionGroup()
        for name, fn in (("log", lambda s: self._terminal([s.command, "log"])),
                         ("folder", self._folder), ("notes", self._notes)):
            action = Gio.SimpleAction.new(name, GLib.VariantType.new("s"))
            action.connect("activate", lambda _, v, fn=fn: fn(self.rows[v.get_string()][0]))
            group.add_action(action)
        self.insert_action_group("server", group)

    #--------------------------------------------------------------------#
    #-- Status
    #--------------------------------------------------------------------#
    def _start_polling(self):
        if not self.timer and self.rows:
            self._poll()
            self.timer = GLib.timeout_add_seconds(POLL, self._poll)

    def _stop_polling(self):
        if self.timer:
            GLib.source_remove(self.timer)
            self.timer = 0

    def _poll(self):
        commands = list(self.rows)
        ui.run_async(lambda: {c: running(c) for c in commands}, self._show)
        return True

    def _show(self, states, err):
        if err is not None:
            return
        for command, up in states.items():
            _, state, console, stop = self.rows[command]
            text, kind = {True: ("Running", "success"), False: ("Stopped", "neutral")}.get(up, ("Unknown", "warning"))
            state.set_label(text)
            for k in ("success", "neutral", "warning"):
                state.remove_css_class(k)
            state.add_css_class(kind)
            console.set_label("Console" if up else "Start")
            console.set_tooltip_text("Open the server's console" if up else "Start the server and open its console")
            console.set_css_classes([] if up else ["suggested-action"])
            stop.set_visible(bool(up))

    #--------------------------------------------------------------------#
    #-- Actions
    #--------------------------------------------------------------------#
    def _terminal(self, argv):
        term = GLib.find_program_in_path("xdg-terminal-exec")
        if term is None:
            self.window.toast(f"Run {' '.join(argv)} in a terminal")
            return
        try:
            Gio.Subprocess.new([term] + argv, Gio.SubprocessFlags.NONE)
        except GLib.Error as e:
            self.window.toast(f"Couldn't open a terminal: {e.message}")
        GLib.timeout_add_seconds(2, lambda: self._poll() and False)

    def _stop(self, s):
        dialog = Adw.AlertDialog(heading=f"Stop {s.name}?",
                                 body="The server saves the world and shuts down; players on it are "
                                      "disconnected.")
        dialog.add_response("cancel", "Cancel")
        dialog.add_response("stop", "Stop")
        dialog.set_response_appearance("stop", Adw.ResponseAppearance.DESTRUCTIVE)
        dialog.set_close_response("cancel")

        def chosen(_, r):
            if r != "stop":
                return

            def done(out, err):
                if err is not None or out.returncode != 0:
                    self.window.toast(f"Couldn't stop {s.name}")
                else:
                    self.window.toast(f"{s.name} is shutting down")
                GLib.timeout_add_seconds(3, lambda: self._poll() and False)
            ui.run_async(lambda: subprocess.run([s.command, "stop"], capture_output=True, text=True,
                                                timeout=10), done)
        dialog.connect("response", chosen)
        dialog.present(self.window)

    def _folder(self, s):
        path = os.path.join(os.path.expanduser("~"), s.folder)
        if not os.path.isdir(path):
            self.window.toast(f"~/{s.folder} doesn't exist yet")
            return
        Gtk.FileLauncher.new(Gio.File.new_for_path(path)).launch(self.window, None, None, None)

    def _notes(self, s):
        if not self.window.open_doc(os.path.join(self.window.cfg.flake, "docs", "gaming", "minecraft_servers",
                                                 s.docs, "index.md")):
            self.window.toast(f"No notes for {s.name}")
