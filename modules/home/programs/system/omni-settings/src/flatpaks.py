"""The Flatpaks page: Flatpak's own switch (a machine setting, applied with a
rebuild, which also installs Flatseal), the apps and runtimes installed,
updates and clean-up. The apps come from Flathub or a downloaded bundle, not
from this config, so an app's switch uninstalls or reinstalls it right away;
apps switched off here are remembered, so their switch stays to bring them
back."""

import re
from dataclasses import asdict

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gio, GLib, Gtk  # noqa: E402

import ui  # noqa: E402
from flatpakstate import (FLATSEAL, INSTALLATIONS, NOISE, binary, listing, load_off, save_off,  # noqa: E402
                          size_bytes, updates)


#--------------------------------------------------------------------#
#-- Running
#--------------------------------------------------------------------#
class Job:
    """Runs `commands` one after another, handing each output line to on_line
    and done(ok, last lines) to the end; stops at the first that fails."""

    def __init__(self, commands, on_line, done):
        self.commands = list(commands)
        self.on_line = on_line
        self.done = done
        self.tail = []
        self.buffer = b""

    def start(self):
        if not self.commands:
            self.done(True, self.tail)
            return
        try:
            self.proc = Gio.Subprocess.new(self.commands.pop(0), Gio.SubprocessFlags.STDOUT_PIPE
                                           | Gio.SubprocessFlags.STDERR_MERGE)
        except GLib.Error as e:
            self.done(False, [e.message])
            return
        self._read(self.proc.get_stdout_pipe())

    def _read(self, stream):
        stream.read_bytes_async(65536, GLib.PRIORITY_DEFAULT, None, self._got)

    def _got(self, stream, res):
        try:
            data = stream.read_bytes_finish(res).get_data()
        except GLib.Error:
            data = b""
        if data:
            self._feed(data)
            self._read(stream)
            return
        self._feed(b"\n")
        self.proc.wait_async(None, self._exited)

    def _feed(self, data):
        *lines, self.buffer = re.split(rb"[\r\n]", self.buffer + data)
        for raw in lines:
            line = " ".join(NOISE.sub(" ", raw.decode(errors="replace")).split())
            if line:
                self.tail = (self.tail + [line])[-20:]
                self.on_line(line)

    def _exited(self, proc, res):
        try:
            proc.wait_finish(res)
        except GLib.Error:
            pass
        if proc.get_successful():
            self.start()
        else:
            self.done(False, self.tail)


#--------------------------------------------------------------------#
#-- Page
#--------------------------------------------------------------------#
class FlatpakPage(Adw.PreferencesPage):
    def __init__(self, window, page):
        super().__init__()
        self.window = window
        self.listing = None
        self.job = None
        self.app_rows = []
        self.quiet = set()  # switches being set back, whose change isn't the user's
        self.flatpak = binary()

        top = Adw.PreferencesGroup()
        top.add(ui.hero(ui.first_icon("flatpak-symbolic", "system-software-install-symbolic"), "Flatpaks",
                        "Apps nixpkgs doesn't have: update them, clean up, and switch each one on "
                        "or off."))
        self.add(top)

        #--- Flatpak's own switch, a machine setting like any other
        on = False
        for g in page.groups if page is not None else []:
            group = Adw.PreferencesGroup()
            for s in g.settings:
                row = window._row(s, True, page)
                row.set_sensitive(window.direct)
                group.add(row)
                on = on or bool(window.state.value(window.cfg, s))
            if not window.direct:
                note = Adw.ActionRow(title="Only an admin can turn Flatpak on or off",
                                     subtitle="It's on or off for everyone who uses this computer.")
                note.add_prefix(Gtk.Image(icon_name="changes-prevent-symbolic", css_classes=["accent"]))
                group.add(note)
            self.add(group)

        if self.flatpak is None:
            group = Adw.PreferencesGroup()
            text = ("Flatpak starts working after the rebuild that turns it on." if on else
                    "Turn Flatpak on and apply, and its apps show up here.")
            row = Adw.ActionRow(title="Flatpak isn't installed", subtitle=text)
            row.add_prefix(Gtk.Image(icon_name=ui.first_icon("dialog-information-symbolic"),
                                     valign=Gtk.Align.CENTER))
            group.add(row)
            self.add(group)
            return

        #--- Flatseal
        group = Adw.PreferencesGroup(title="Permissions")
        self.flatseal_row = Adw.ActionRow(title="Flatseal")
        self.flatseal_row.add_prefix(ui.app_image([f"{FLATSEAL}.desktop", FLATSEAL])
                                     or Gtk.Image(icon_name=ui.first_icon("security-medium-symbolic"),
                                                  pixel_size=32))
        self.flatseal_button = Gtk.Button(label="Open", valign=Gtk.Align.CENTER, visible=False)
        self.flatseal_button.connect("clicked", lambda _: self.open_flatseal())
        self.flatseal_row.add_suffix(self.flatseal_button)
        group.add(self.flatseal_row)
        self.add(group)

        #--- Updates
        group = Adw.PreferencesGroup(title="Updates")
        self.updates_row = Adw.ActionRow(title="Apps and Runtimes", subtitle_lines=3,
                                         subtitle="Look for newer versions.")
        self.updates_row.add_prefix(Gtk.Image(icon_name=ui.first_icon("software-update-available-symbolic"),
                                              valign=Gtk.Align.CENTER))
        self.updates_spinner = Adw.Spinner(visible=False, valign=Gtk.Align.CENTER)
        self.check_button = Gtk.Button(label="Check for Updates", valign=Gtk.Align.CENTER)
        self.check_button.connect("clicked", lambda _: self.check())
        self.update_button = Gtk.Button(label="Update All", valign=Gtk.Align.CENTER, visible=False,
                                        css_classes=["suggested-action"])
        self.update_button.connect("clicked", lambda _: self.update_all())
        for w in (self.updates_spinner, self.check_button, self.update_button):
            self.updates_row.add_suffix(w)
        self.updates_row.spinner = self.updates_spinner
        group.add(self.updates_row)
        self.add(group)

        #--- Apps and runtimes
        self.apps_group = Adw.PreferencesGroup(
            title="Installed Apps",
            description="Switching an app off uninstalls it and keeps its settings and files, so "
                        "switching it on brings it back as it was.")
        self.add(self.apps_group)
        self.runtimes_group = Adw.PreferencesGroup()
        self.add(self.runtimes_group)
        self.runtimes_row = None

        #--- Maintenance
        group = Adw.PreferencesGroup(title="Maintenance")
        self.unused_row, self.unused_button = self._action_row(
            "Remove Unused Runtimes", "Uninstalls runtimes and extensions that no installed app needs "
                                      "any more.", "user-trash-symbolic", "Remove", self.remove_unused)
        self.repair_row, self.repair_button = self._action_row(
            "Repair", "Checks every installed file and downloads again any that are missing or "
                      "damaged.", "emblem-system-symbolic", "Repair", self.repair)
        group.add(self.unused_row)
        group.add(self.repair_row)
        self.add(group)

        self.refresh()

    def _action_row(self, title, subtitle, icon, label, fn):
        row = Adw.ActionRow(title=title, subtitle=subtitle, subtitle_lines=3)
        row.add_prefix(Gtk.Image(icon_name=ui.first_icon(icon), valign=Gtk.Align.CENTER))
        row.spinner = Adw.Spinner(visible=False, valign=Gtk.Align.CENTER)
        row.add_suffix(row.spinner)
        button = Gtk.Button(label=label, valign=Gtk.Align.CENTER)
        button.connect("clicked", lambda _: fn())
        row.add_suffix(button)
        return row, button

    #--------------------------------------------------------------------#
    #-- Lists
    #--------------------------------------------------------------------#
    def refresh(self):
        if not self.app_rows:
            spinner = Adw.Spinner(width_request=32, height_request=32, margin_top=12, margin_bottom=12)
            self.apps_group.add(spinner)
            self.app_rows = [spinner]
        ui.run_async(listing, self._listed)

    def _listed(self, result, err):
        for row in self.app_rows:
            self.apps_group.remove(row)
        self.app_rows = []
        if self.runtimes_row is not None:
            self.runtimes_group.remove(self.runtimes_row)
            self.runtimes_row = None
        if err is not None:
            self._add_app_row(Adw.ActionRow(title="Couldn't list the Flatpaks", subtitle=ui.esc(str(err))))
            return
        self.listing = result
        have = {r.ref for r in result.runtimes}
        flatseal = any(a.id == FLATSEAL for a in result.apps)
        self.flatseal_button.set_visible(flatseal)
        self.flatseal_row.set_subtitle(
            "Change what each app may reach." if flatseal else
            "Not installed yet. It installs in the background after the rebuild that turned Flatpak on.")

        for ref in result.apps:
            self._add_app_row(self._app_row(ref, True, missing=ref.runtime and ref.runtime not in have,
                                            flatseal=flatseal))
        for ref in result.off:
            self._add_app_row(self._app_row(ref, False))
        if not result.apps and not result.off:
            row = Adw.ActionRow(title="No Flatpak apps yet", activatable=True,
                                subtitle=ui.esc("Find one on flathub.org, then install it with: "
                                                "flatpak install flathub <its id>"))
            row.add_suffix(Gtk.Image(icon_name=ui.link_icon(), valign=Gtk.Align.CENTER, css_classes=["dim-label"]))
            row.connect("activated", lambda _: ui.open_uri(self.window, "https://flathub.org"))
            self._add_app_row(row)

        if result.runtimes:
            total = GLib.format_size(sum(size_bytes(r.size) for r in result.runtimes))
            exp = Adw.ExpanderRow(title=f"Runtimes ({len(result.runtimes)})",
                                  subtitle=ui.esc(f"Shared parts the apps run on, {total} in all"))
            exp.add_prefix(Gtk.Image(icon_name=ui.first_icon("application-x-addon-symbolic",
                                                             "package-x-generic-symbolic"),
                                     valign=Gtk.Align.CENTER))
            for r in result.runtimes:
                exp.add_row(Adw.ActionRow(title=ui.esc(r.id), css_classes=["property"],
                                          subtitle=ui.esc(" · ".join(p for p in (r.branch, self._where(r), r.size)
                                                                      if p))))
            self.runtimes_group.add(exp)
            self.runtimes_row = exp
        self._busy(self.job is not None)

    def _add_app_row(self, row):
        self.apps_group.add(row)
        self.app_rows.append(row)

    def _where(self, ref):
        return "Everyone" if ref.installation == "system" else "Just you"

    def _bundle(self, ref):
        return not (self.listing and self.listing.remotes.get((ref.installation, ref.origin)))

    def _app_row(self, ref, installed, missing=False, flatseal=False):
        parts = [ref.version, self._where(ref), ref.size] if installed else [self._where(ref)]
        subtitle = ui.esc(" · ".join(p for p in parts if p))
        if installed and self._bundle(ref):
            subtitle += ui.esc(" · from a downloaded file")
        if missing:
            warning = ui.esc(f"Can't start: it needs the {ref.runtime} runtime, which isn't installed")
            subtitle += f'\n<span foreground="{self.window.colors["warning"]}">{warning}</span>'
        if not installed:
            subtitle += ui.esc("\nSwitched off. Switch it on to install it again.")
        row = Adw.ActionRow(title=ui.esc(ref.name), subtitle=subtitle, subtitle_lines=3)
        row.add_prefix(ui.app_image([f"{ref.id}.desktop", ref.id])
                       or Gtk.Image(icon_name=ui.first_icon("application-x-executable-symbolic"), pixel_size=32))
        spinner = Adw.Spinner(visible=False, valign=Gtk.Align.CENTER)
        row.add_suffix(spinner)
        row.spinner = spinner
        if missing:
            fix = Gtk.Button(label="Install Runtime", valign=Gtk.Align.CENTER, css_classes=["suggested-action"])
            fix.connect("clicked", lambda _: self.install_runtime(row, ref))
            row.add_suffix(fix)
        if installed and flatseal and ref.id != FLATSEAL:
            perms = Gtk.Button(icon_name=ui.first_icon("security-medium-symbolic", "emblem-system-symbolic"),
                               valign=Gtk.Align.CENTER, css_classes=["flat"],
                               tooltip_text="What it may reach, in Flatseal")
            perms.connect("clicked", lambda _: self.open_flatseal(ref.id))
            row.add_suffix(perms)
        if ref.id == FLATSEAL and ref.installation == "system" and installed:
            row.add_suffix(ui.chip("Comes with Flatpak", "accent"))
            return row
        if not installed:
            forget = Gtk.Button(icon_name="window-close-symbolic", valign=Gtk.Align.CENTER, css_classes=["flat"],
                                tooltip_text="Take it off this list")
            forget.connect("clicked", lambda _: self.forget(ref))
            row.add_suffix(forget)
        switch = Gtk.Switch(active=installed, valign=Gtk.Align.CENTER,
                            tooltip_text="Uninstall" if installed else "Install again")
        switch.connect("notify::active", self._toggled, row, ref)
        row.add_suffix(switch)
        row.switch = switch
        return row

    #--------------------------------------------------------------------#
    #-- Switching apps on and off
    #--------------------------------------------------------------------#
    def _set(self, switch, value):
        self.quiet.add(switch)
        switch.set_active(value)
        self.quiet.discard(switch)

    def _toggled(self, switch, _, row, ref):
        if switch in self.quiet:
            return
        if self.job is not None:
            self._set(switch, not switch.get_active())
            self.window.toast("Wait for the running Flatpak job to finish")
            return
        if switch.get_active():
            self._reinstall(row, switch, ref)
        else:
            self._confirm_uninstall(row, switch, ref)

    def _confirm_uninstall(self, row, switch, ref):
        body = (f"Its settings and files in ~/.var/app/{ref.id} stay, so switching it on "
                "brings it back as it was.")
        if self._bundle(ref):
            body = (f"It came from a downloaded file, so to get it back you install that file "
                    f"again. Its settings and files in ~/.var/app/{ref.id} stay.")
        dialog = Adw.AlertDialog(heading=f"Uninstall {ref.name}?", body=body)
        dialog.add_response("cancel", "Cancel")
        dialog.add_response("remove", "Uninstall")
        dialog.set_response_appearance("remove", Adw.ResponseAppearance.DESTRUCTIVE)
        dialog.set_close_response("cancel")

        def chosen(_, response):
            if response != "remove":
                self._set(switch, True)
                return
            bundle = self._bundle(ref)

            def done(ok, tail):
                if not ok:
                    self._set(switch, True)
                    return self._failed(f"Couldn't uninstall {ref.name}", tail)
                if not bundle:
                    off = load_off()
                    off[ref.key] = asdict(ref)
                    save_off(off)
                self.window.toast(f"{ref.name} uninstalled")
            self._run(row, [[self.flatpak, "uninstall", f"--{ref.installation}", "-y", "--noninteractive", ref.id]],
                      done)
        dialog.connect("response", chosen)
        dialog.present(self.window)

    def _reinstall(self, row, switch, ref):
        if self._bundle(ref):
            self._set(switch, False)
            self.window.toast(f"Install {ref.name} again from the file it came from")
            return

        def done(ok, tail):
            if not ok:
                self._set(switch, False)
                return self._failed(f"Couldn't install {ref.name}", tail)
            off = load_off()
            off.pop(ref.key, None)
            save_off(off)
            self.window.toast(f"{ref.name} installed")
        self._run(row, [[self.flatpak, "install", f"--{ref.installation}", "-y", "--noninteractive",
                         ref.origin, f"app/{ref.ref}"]], done)

    def forget(self, ref):
        off = load_off()
        off.pop(ref.key, None)
        save_off(off)
        self.refresh()

    def install_runtime(self, row, ref):
        inst = ref.installation
        remotes = self.listing.remotes
        remote = "flathub" if remotes.get((inst, "flathub")) else \
            next((n for (i, n), url in remotes.items() if i == inst and url), None)
        if remote is None:
            self.window.toast(f"No source to install {ref.runtime} from")
            return

        def done(ok, tail):
            if not ok:
                return self._failed("Couldn't install the runtime", tail)
            self.window.toast(f"{ref.name} can start now")
        self._run(row, [[self.flatpak, "install", f"--{inst}", "-y", "--noninteractive", remote,
                         f"runtime/{ref.runtime}"]], done)

    #--------------------------------------------------------------------#
    #-- Updates and maintenance
    #--------------------------------------------------------------------#
    def _installations(self):
        """The installations holding anything, user first."""
        if self.listing is None:
            return list(INSTALLATIONS)
        used = {r.installation for r in self.listing.apps + self.listing.runtimes}
        return [i for i in INSTALLATIONS if i in used]

    def check(self):
        if self.job is not None:
            return
        self.check_button.set_visible(False)
        self.update_button.set_visible(False)
        self.updates_spinner.set_visible(True)
        self.updates_row.set_subtitle("Asking each source for its newest versions…")
        ui.run_async(lambda: updates(self._installations()), self._checked)

    def _checked(self, found, err):
        self.updates_spinner.set_visible(False)
        self.check_button.set_visible(True)
        self.check_button.set_label("Check Again")
        if err is not None:
            self.updates_row.set_subtitle(ui.esc(f"Couldn't check: {err}"))
            return
        if not found:
            self.updates_row.set_subtitle("Everything is up to date.")
            return
        names = ", ".join(found[:6]) + ("…" if len(found) > 6 else "")
        self.updates_row.set_subtitle(ui.esc(f"{len(found)} to update: {names}"))
        self.update_button.set_visible(True)

    def update_all(self):
        def done(ok, tail):
            self.check_button.set_label("Check Again")
            if not ok:
                self.updates_row.set_subtitle("The update didn't finish.")
                return self._failed("Couldn't update", tail)
            self.updates_row.set_subtitle("Everything is up to date.")
            self.window.toast("Flatpaks updated")
        self.update_button.set_visible(False)
        self._run(self.updates_row, [[self.flatpak, "update", f"--{i}", "-y", "--noninteractive"]
                                     for i in self._installations()], done)

    def remove_unused(self):
        commands = [[self.flatpak, "uninstall", f"--{i}", "--unused", "-y", "--noninteractive"]
                    for i in self._installations()]

        def done(ok, tail):
            if not ok:
                return self._failed("Couldn't remove the unused runtimes", tail)
            # Each installation with nothing to remove says so
            nothing = sum("Nothing unused" in line for line in tail) >= len(commands)
            self.window.toast("Nothing unused to remove" if nothing else "Unused runtimes removed")
        self._run(self.unused_row, commands, done)

    def repair(self):
        #--- The system installation's files belong to root
        pkexec = GLib.find_program_in_path("pkexec") or "/run/wrappers/bin/pkexec"
        commands = [([self.flatpak] if i == "user" else [pkexec, self.flatpak]) + ["repair", f"--{i}"]
                    for i in self._installations()]

        def done(ok, tail):
            if not ok:
                return self._failed("Couldn't finish the repair", tail)
            self.window.toast("Repair finished")
        self._run(self.repair_row, commands, done)

    #--------------------------------------------------------------------#
    #-- Jobs
    #--------------------------------------------------------------------#
    def _run(self, row, commands, done):
        """Runs a Flatpak job, its progress shown under `row`, then lists again."""
        if self.job is not None:
            self.window.toast("Wait for the running Flatpak job to finish")
            return
        old = row.get_subtitle()
        spinner = row.spinner
        spinner.set_visible(True)

        def line(text):
            row.set_subtitle(ui.esc(text))

        def finished(ok, tail):
            self.job = None
            spinner.set_visible(False)
            row.set_subtitle(old)
            done(ok, tail)
            self.refresh()
        self.job = Job(commands, line, finished)
        self._busy(True)
        self.job.start()

    def _busy(self, busy):
        for w in (self.check_button, self.update_button, self.unused_button, self.repair_button):
            w.set_sensitive(not busy)
        for row in self.app_rows:
            switch = getattr(row, "switch", None)
            if switch is not None:
                switch.set_sensitive(not busy)

    def _failed(self, heading, tail):
        dialog = Adw.AlertDialog(heading=heading, body="\n".join(tail[-6:]) or "Flatpak didn't say why.")
        dialog.add_response("ok", "OK")
        dialog.present(self.window)

    #--------------------------------------------------------------------#
    #-- Flatseal
    #--------------------------------------------------------------------#
    def open_flatseal(self, app_id=None):
        """Opens Flatseal, on one app's page when `app_id` is given: its `show`
        action takes an app id."""
        if app_id is None:
            self._launch_flatseal()
            return
        args = GLib.Variant("(sava{sv})", ("show", [GLib.Variant("s", app_id)], {}))

        def called(bus, res):
            try:
                bus.call_finish(res)
            except GLib.Error:
                # Not running and not D-Bus activatable here: start it, then ask again
                self._launch_flatseal()
                self._when_running(lambda: bus.call(FLATSEAL, "/com/github/tchx84/Flatseal", "org.gtk.Actions",
                                                    "Activate", args, None, Gio.DBusCallFlags.NONE, 5000, None,
                                                    None))
        try:
            bus = Gio.bus_get_sync(Gio.BusType.SESSION)
        except GLib.Error:
            self._launch_flatseal()
            return
        bus.call(FLATSEAL, "/com/github/tchx84/Flatseal", "org.gtk.Actions", "Activate", args, None,
                 Gio.DBusCallFlags.NONE, 5000, None, called)

    def _when_running(self, fn):
        """Runs `fn` once Flatseal owns its bus name, if that's within 20 seconds."""
        watch = {}

        def stop():
            if watch.get("id"):
                Gio.bus_unwatch_name(watch.pop("id"))
            return False

        def appeared(*_):
            stop()
            fn()
        watch["id"] = Gio.bus_watch_name(Gio.BusType.SESSION, FLATSEAL, Gio.BusNameWatcherFlags.NONE,
                                         appeared, None)
        GLib.timeout_add_seconds(20, stop)

    def _launch_flatseal(self):
        try:
            info = ui.DesktopAppInfo.new(f"{FLATSEAL}.desktop")
        except (TypeError, GLib.Error):
            info = None
        try:
            if info is not None:
                info.launch([], self.window.get_display().get_app_launch_context())
            else:
                Gio.Subprocess.new([self.flatpak, "run", FLATSEAL], Gio.SubprocessFlags.NONE)
        except GLib.Error as e:
            self.window.toast(f"Couldn't open Flatseal: {e.message}")
