"""The Backups page: `nixm backup` behind buttons. FreeTube (subscriptions,
playlists, history) and Zen's bookmarks go to dated folders under
~/SyncBackups/<host>/, which Syncthing carries to the other computers; nixm
keeps the newest ten of each."""

import os
import re
import socket
import subprocess
import time

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gio, GLib, Gtk, Pango  # noqa: E402

import ui  # noqa: E402

ROOT = os.path.join(os.path.expanduser("~"), "SyncBackups")
STAMP = re.compile(r"^(\d{4})-(\d\d)-(\d\d)_(\d\d)-(\d\d)-(\d\d)$")
#--- (nixm command, title, what it saves, user setting it needs, its folder)
KINDS = [
    ("freetube-backup", "FreeTube", "Subscriptions, playlists, history and settings",
     ("media", "freetube"), "FreeTube"),
    ("zen-backup", "Zen Bookmarks", "Every bookmark, as a bookmarks.html any browser imports",
     ("browsers", "zen"), "Zen"),
]


def newest(folder):
    """When the newest dated backup in `folder` was made (epoch), or None."""
    try:
        stamps = sorted(n for n in os.listdir(folder) if STAMP.match(n))
    except OSError:
        return None
    if not stamps:
        return None
    return time.mktime(time.strptime(stamps[-1], "%Y-%m-%d_%H-%M-%S"))


def freetube_open():
    """Whether FreeTube is running, as nixm's own check sees it."""
    try:
        out = subprocess.run(["pgrep", "-f", "freetube/resources/app.asar"], capture_output=True)
    except OSError:
        return False
    return out.returncode == 0


class BackupsPage(Adw.PreferencesPage):
    def __init__(self, window):
        super().__init__()
        self.window = window
        self.host = socket.gethostname()
        self.rows = {}
        user = window.state.resolved["users"][window.cfg.user]
        self.kinds = [k for k in KINDS if (user.get(k[3][0]) or {}).get(k[3][1])]

        top = Adw.PreferencesGroup()
        everything = None
        if self.kinds:
            everything = Gtk.Button(label="Back Up Everything", halign=Gtk.Align.CENTER, margin_top=6,
                                    css_classes=["pill", "suggested-action"])
            everything.connect("clicked", lambda _: self._run("backup", "Everything"))
        top.add(ui.hero(ui.first_icon("drive-harddisk-symbolic", "document-save-symbolic"), "Backups",
                        f"Copies of app data the config can't rebuild, in dated folders under "
                        f"~/SyncBackups/{self.host}. Syncthing carries them to your other computers, "
                        f"and the newest ten of each are kept.", extra=everything))
        self.add(top)
        self.everything = everything

        group = Adw.PreferencesGroup(title="What's Backed Up")
        if not self.kinds:
            group.add(Adw.ActionRow(title="Nothing to back up",
                                    subtitle="FreeTube and Zen are the apps with backups, and neither is on."))
        for command, title, what, _, folder in self.kinds:
            row = Adw.ActionRow(title=title, subtitle_lines=3)
            row.add_prefix(Gtk.Image(icon_name=ui.first_icon("document-save-symbolic"), valign=Gtk.Align.CENTER))
            spinner = Adw.Spinner(visible=False, valign=Gtk.Align.CENTER)
            button = Gtk.Button(label="Back Up", valign=Gtk.Align.CENTER)
            button.connect("clicked", lambda _, c=command, t=title: self._run(c, t))
            open_button = Gtk.Button(icon_name=ui.first_icon("folder-open-symbolic"), css_classes=["flat"],
                                     valign=Gtk.Align.CENTER, tooltip_text="Open the backups folder")
            open_button.connect("clicked", lambda _, f=folder: self._open(f))
            for w in (spinner, button, open_button):
                row.add_suffix(w)
            group.add(row)
            self.rows[command] = (row, what, folder, spinner, button)
            self._subtitle(command)
        self.add(group)

        #--- What the last run printed
        self.output_group = Adw.PreferencesGroup(title="Last Run", visible=False)
        self.output = Gtk.Label(xalign=0, wrap=True, wrap_mode=Pango.WrapMode.WORD_CHAR, selectable=True,
                                css_classes=["monospace", "doc-code"])
        card = Gtk.Box(css_classes=["card"])
        card.append(self.output)
        self.output_group.add(card)
        self.add(self.output_group)

    def _subtitle(self, command):
        row, what, folder, _, _ = self.rows[command]
        last = newest(os.path.join(ROOT, self.host, folder))
        when = f"Last backed up {ui.when(last).lower()}" if last else "Not backed up yet"
        note = ""
        if command == "freetube-backup" and freetube_open():
            note = f'\n<span foreground="{self.window.colors.get("warning", "orange")}">' \
                   "Close FreeTube first, so its data is all on disk.</span>"
        row.set_subtitle(f"{ui.esc(what)}\n{ui.esc(when)}{note}")

    def _open(self, folder):
        path = os.path.join(ROOT, self.host, folder)
        if not os.path.isdir(path):
            self.window.toast("No backups yet")
            return
        Gtk.FileLauncher.new(Gio.File.new_for_path(path)).launch(self.window, None, None, None)

    def _busy(self, busy, command):
        for c, (_, _, _, spinner, button) in self.rows.items():
            button.set_sensitive(not busy)
            spinner.set_visible(busy and command in (c, "backup"))
        if self.everything is not None:
            self.everything.set_sensitive(not busy)

    def _run(self, command, title):
        if not GLib.find_program_in_path("nixm"):
            self.window.toast("nixm isn't installed")
            return
        self._busy(True, command)

        def done(out, err):
            self._busy(False, command)
            for c in self.rows:
                self._subtitle(c)
            text = str(err) if err is not None else (out.stdout + out.stderr).strip()
            self.output.set_text(text or "(no output)")
            self.output_group.set_visible(True)
            ok = err is None and out.returncode == 0
            self.window.toast(f"{title} backed up" if ok else f"{title}: the backup didn't finish; see below")
        ui.run_async(lambda: subprocess.run(["nixm", command], capture_output=True, text=True, timeout=600,
                                            stdin=subprocess.DEVNULL), done)
