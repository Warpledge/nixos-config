"""The page a rebuild runs on. It takes the whole window and shows the steps,
live progress read from nix's JSON log (downloads, builds, what's running),
what changed between the old and new system, the services the switch touched,
and the full log. The helper (helper.py) does the work; this only reads its
output and can ask it to cancel the build."""

import time

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gdk, Gio, GLib, Gtk, Pango  # noqa: E402

import closure  # noqa: E402
import nixlog  # noqa: E402
import ui  # noqa: E402

STEPS = {
    "write": "Save and check your settings",
    "update": "Get the newest versions",
    "auth": "Confirm it's you",
    "save": "Save and check your settings",
    "build": "Build the new system",
    "compare": "Compare with what's running",
    "switch": "Switch to the new system",
    "boot": "Add it to the boot menu",
    "collect": "Delete old versions and unused files",
}
RUNNING_HEIGHT = 360  # px before the Working On list scrolls
LOG_LIMIT = 6000  # lines kept in the log view


class Step:
    def __init__(self, sid, title):
        self.id = sid
        self.state = "waiting"
        self.started = self.ended = None
        self.row = Adw.ActionRow(title=ui.esc(title))
        self.icons = Gtk.Stack(transition_type=Gtk.StackTransitionType.CROSSFADE,
                               valign=Gtk.Align.CENTER)
        for name, icon in (("waiting", "radio-symbolic"), ("done", "object-select-symbolic"),
                           ("failed", "process-stop-symbolic"), ("skipped", "list-remove-symbolic")):
            image = Gtk.Image(icon_name=ui.first_icon(icon, "emblem-default-symbolic"),
                              css_classes=["step-icon", name])
            self.icons.add_named(image, name)
        self.icons.add_named(Adw.Spinner(width_request=16, height_request=16), "running")
        self.row.add_prefix(self.icons)
        self.time = Gtk.Label(css_classes=["dim-label", "numeric"], valign=Gtk.Align.CENTER)
        self.row.add_suffix(self.time)

    def set(self, state, detail=None):
        now = time.monotonic()
        if state == "running" and self.started is None:
            self.started = now
        if state in ("done", "failed", "skipped") and self.ended is None:
            self.ended = now
            if self.started is None:
                self.started = now
        self.state = state
        self.icons.set_visible_child_name(state)
        if detail is not None:
            self.row.set_subtitle(ui.esc(detail))
        self.tick()

    def tick(self):
        if self.started is None or self.state == "skipped":
            self.time.set_label("")
            return
        self.time.set_label(ui.elapsed((self.ended or time.monotonic()) - self.started))


class RunView(Gtk.Box):
    """`steps` are STEPS ids in order, `titles` overrides some of their names.
    Start with run(argv); on_close(outcome) runs when the user leaves the page,
    outcome being ok, failed, cancelled or auth (the password prompt was closed
    or refused)."""

    def __init__(self, window, title, steps, on_close, titles=None):
        super().__init__(orientation=Gtk.Orientation.VERTICAL)
        self.window = window
        self.on_close = on_close
        self.titles = {**STEPS, **(titles or {})}
        self.cleaned = None
        self.deleted = 0  # store paths the clean-up has deleted so far
        self.colors = ui.theme_colors()
        self.progress = nixlog.Progress()
        self.proc = None
        self.started = time.monotonic()
        self.ended = None
        self.outcome = None
        self.result = {}
        self.mode = None
        self.errors = []
        self.switch_lines = []
        self.samples = []  # (time, bytes downloaded), for the speed
        self.undo = None
        self.restart = False
        self.tick_source = 0
        self.dirty = False
        self.current = None
        self.stdin = None

        #--- Header
        self.title_widget = Adw.WindowTitle(title=title, subtitle="")
        self.header = Adw.HeaderBar(title_widget=self.title_widget, show_end_title_buttons=False,
                                    show_start_title_buttons=False)

        #--- Hero
        self.hero_icon = Gtk.Stack(transition_type=Gtk.StackTransitionType.CROSSFADE,
                                   halign=Gtk.Align.CENTER)
        self.hero_icon.add_named(Adw.Spinner(width_request=64, height_request=64), "running")
        for name, icon, style in (("ok", "emblem-ok-symbolic", "success"),
                                  ("restart", "system-reboot-symbolic", "accent"),
                                  ("failed", "dialog-error-symbolic", "error"),
                                  ("cancelled", "process-stop-symbolic", "warning")):
            image = Gtk.Image(icon_name=ui.first_icon(icon, "emblem-default-symbolic"), pixel_size=72,
                              css_classes=["hero-icon", style])
            self.hero_icon.add_named(image, name)
        self.heading = Gtk.Label(css_classes=["title-1"], wrap=True, justify=Gtk.Justification.CENTER)
        self.detail = Gtk.Label(css_classes=["dim-label"], wrap=True, justify=Gtk.Justification.CENTER,
                                max_width_chars=70)
        self.bar = Gtk.ProgressBar(css_classes=["big-progress"], margin_top=6)
        hero = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10, margin_top=6)
        for w in (self.hero_icon, self.heading, self.detail, self.bar):
            hero.append(w)

        #--- Stats
        self.tiles = {}
        tiles = Gtk.Box(spacing=12, homogeneous=True, visible=False)
        for key, icon, name in (("downloads", "folder-download-symbolic", "Downloads"),
                                ("builds", "system-run-symbolic", "Builds"),
                                ("time", "alarm-symbolic", "Time")):
            tile = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2, css_classes=["card", "tile"])
            top = Gtk.Box(spacing=6)
            top.append(Gtk.Image(icon_name=ui.first_icon(icon), css_classes=["dim-label"]))
            top.append(Gtk.Label(label=name, css_classes=["caption-heading", "dim-label"]))
            value = Gtk.Label(xalign=0, css_classes=["value", "numeric"])
            sub = Gtk.Label(xalign=0, css_classes=["caption", "dim-label", "numeric"],
                            ellipsize=Pango.EllipsizeMode.END)
            for w in (top, value, sub):
                tile.append(w)
            tiles.append(tile)
            self.tiles[key] = (value, sub)
        self.tiles_box = tiles

        #--- Steps
        self.steps = {}
        steps_group = Adw.PreferencesGroup(title="Steps")
        for sid in steps:
            step = Step(sid, self.titles.get(sid, sid))
            self.steps[sid] = step
            steps_group.add(step.row)

        #--- Running now: every build and download, scrolling once it's taller than
        #--- RUNNING_HEIGHT; rows are made as needed and reused
        self.running_group = Adw.PreferencesGroup(title="Working On", visible=False)
        self.running_count = Gtk.Label(css_classes=["dim-label", "caption", "numeric"],
                                       valign=Gtk.Align.CENTER)
        self.running_group.set_header_suffix(self.running_count)
        self.running_list = Gtk.ListBox(selection_mode=Gtk.SelectionMode.NONE, show_separators=True,
                                        css_classes=["running-list"])
        running_scroll = Gtk.ScrolledWindow(child=self.running_list, max_content_height=RUNNING_HEIGHT,
                                            propagate_natural_height=True, css_classes=["card"],
                                            hscrollbar_policy=Gtk.PolicyType.NEVER,
                                            overflow=Gtk.Overflow.HIDDEN)
        self.running_group.add(running_scroll)
        self.running_rows = []

        #--- Results
        self.notes_group = Adw.PreferencesGroup(visible=False)
        self.error_group = Adw.PreferencesGroup(title="What Went Wrong", visible=False)
        self.error_label = Gtk.Label(wrap=True, xalign=0, selectable=True, css_classes=["monospace"],
                                     wrap_mode=Pango.WrapMode.WORD_CHAR, margin_top=12, margin_bottom=12,
                                     margin_start=12, margin_end=12)
        error_card = Gtk.Box(css_classes=["card"])
        error_card.append(self.error_label)
        self.error_group.add(error_card)
        copy_error = Gtk.Button(icon_name="edit-copy-symbolic", css_classes=["flat"],
                                tooltip_text="Copy the error", valign=Gtk.Align.CENTER)
        copy_error.connect("clicked", lambda _: self._copy(self.error_label.get_text(), "Error copied"))
        self.error_group.set_header_suffix(copy_error)
        self.diff_group = Adw.PreferencesGroup(title="What Changed", visible=False)
        self.units_group = Adw.PreferencesGroup(title="Services", visible=False)

        #--- Log
        self.log = Gtk.TextView(editable=False, cursor_visible=False, monospace=True,
                                wrap_mode=Gtk.WrapMode.WORD_CHAR, top_margin=10, bottom_margin=10,
                                left_margin=12, right_margin=12, css_classes=["log-view"])
        buf = self.log.get_buffer()
        self.end_mark = buf.create_mark("end", buf.get_end_iter(), False)
        fg = Gtk.Label().get_color()
        dim = Gdk.RGBA()
        dim.red, dim.green, dim.blue, dim.alpha = fg.red, fg.green, fg.blue, 0.55
        self.tags = {
            "error": buf.create_tag("error", foreground=self.colors["error"], weight=Pango.Weight.BOLD),
            "warning": buf.create_tag("warning", foreground=self.colors["warning"]),
            "accent": buf.create_tag("accent", foreground=self.colors["accent"]),
            "success": buf.create_tag("success", foreground=self.colors["success"]),
            "dim": buf.create_tag("dim", foreground_rgba=dim),
        }
        self.log_lines = 0
        self.log_scroll = Gtk.ScrolledWindow(child=self.log, min_content_height=280, max_content_height=480,
                                             propagate_natural_height=True, css_classes=["card"])
        log_group = Adw.PreferencesGroup(title="Full Log")
        copy_log = Gtk.Button(icon_name="edit-copy-symbolic", css_classes=["flat"],
                              tooltip_text="Copy the whole log", valign=Gtk.Align.CENTER)
        copy_log.connect("clicked", lambda _: self._copy(self._log_text(), "Log copied"))
        self.log_toggle = Gtk.ToggleButton(label="Show", css_classes=["flat"], valign=Gtk.Align.CENTER)
        suffix = Gtk.Box(spacing=4)
        suffix.append(copy_log)
        suffix.append(self.log_toggle)
        log_group.set_header_suffix(suffix)
        self.log_revealer = Gtk.Revealer(child=self.log_scroll,
                                         transition_type=Gtk.RevealerTransitionType.SLIDE_DOWN)
        self.log_toggle.connect("toggled", self._toggle_log)
        log_group.add(self.log_revealer)

        #--- Page
        body = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24, margin_top=18, margin_bottom=30,
                       margin_start=18, margin_end=18)
        for w in (hero, tiles, self.notes_group, self.error_group, steps_group, self.running_group,
                  self.diff_group, self.units_group, log_group):
            body.append(w)
        scroller = Gtk.ScrolledWindow(child=Adw.Clamp(child=body, maximum_size=860), vexpand=True,
                                      hscrollbar_policy=Gtk.PolicyType.NEVER)

        #--- Buttons
        self.cancel_button = Gtk.Button(label="Stop", css_classes=["destructive-action"], visible=False,
                                        tooltip_text="Stop the build; nothing is switched")
        self.cancel_button.connect("clicked", self._cancel)
        self.undo_button = Gtk.Button(label="Undo My Changes", visible=False)
        self.undo_button.connect("clicked", self._undo)
        self.restart_button = Gtk.Button(label="Restart Now", visible=False)
        self.restart_button.connect("clicked", self._restart)
        self.done_button = Gtk.Button(label="Done", css_classes=["suggested-action"], visible=False)
        self.done_button.connect("clicked", lambda _: self.close())
        bar = Gtk.ActionBar()
        bar.pack_start(self.cancel_button)
        bar.pack_end(self.done_button)
        bar.pack_end(self.restart_button)
        bar.pack_end(self.undo_button)

        view = Adw.ToolbarView(content=scroller, vexpand=True)
        view.add_top_bar(self.header)
        view.add_bottom_bar(bar)
        self.append(view)
        self._hero("running", "Getting ready…", "")
        self.tick_source = GLib.timeout_add(250, self._tick)

    #--------------------------------------------------------------------#
    #-- Steps and hero
    #--------------------------------------------------------------------#
    def step(self, sid, state, detail=None):
        step = self.steps.get(sid)
        if step is not None:
            step.set(state, detail)
        if state == "running":
            self.current = sid
            self._hero("running", self.titles.get(sid, sid) + "…", self._step_detail(sid))
        self.dirty = True

    def _step_detail(self, sid):
        return {
            "auth": "Type your password in the prompt that just opened.",
            "write": "",
            "update": "Checking every source of this config for newer versions.",
            "build": "Downloads what's ready-made and builds the rest. Big updates can take a while.",
            "compare": "",
            "switch": "Services restart as needed; the screen may flicker for a moment.",
            "boot": "",
            "collect": "Old versions go first, then every file nothing uses any more. "
                       "A big clean-up takes a few minutes.",
        }.get(sid, "")

    def _hero(self, state, heading, detail):
        if self.hero_icon.get_visible_child_name() != state:
            self.hero_icon.set_visible_child_name(state)
            child = self.hero_icon.get_visible_child()
            if state != "running":
                child.remove_css_class("pop")
                child.add_css_class("pop")
        self.heading.set_label(heading)
        self.detail.set_label(detail)
        self.detail.set_visible(bool(detail))

    def fail_step(self, sid, heading, detail):
        """Ends the run before the helper starts (the app's own steps failed)."""
        self.step(sid, "failed")
        self._finish("failed", heading, detail)

    #--------------------------------------------------------------------#
    #-- Running the helper
    #--------------------------------------------------------------------#
    def run(self, argv, first_step="auth"):
        self.step(first_step, "running")
        self.cancel_button.set_visible(False)
        flags = (Gio.SubprocessFlags.STDIN_PIPE | Gio.SubprocessFlags.STDOUT_PIPE
                 | Gio.SubprocessFlags.STDERR_MERGE)
        try:
            self.proc = Gio.Subprocess.new(argv, flags)
        except GLib.Error as e:
            self._append("error", e.message)
            self._finish("failed", "Couldn't start the rebuild", e.message)
            return
        self.stdin = self.proc.get_stdin_pipe()
        self.pending = bytearray()
        self._read(self.proc.get_stdout_pipe())

    def _read(self, stream):
        stream.read_bytes_async(65536, GLib.PRIORITY_DEFAULT, None, self._got_bytes)

    def _got_bytes(self, stream, res):
        try:
            chunk = stream.read_bytes_finish(res).get_data()
        except GLib.Error:
            chunk = b""
        if not chunk:  # only the end of the output reads as nothing
            if self.pending:
                self._feed(bytes(self.pending))
            self.proc.wait_async(None, self._exited)
            return
        self.pending.extend(chunk)
        *lines, rest = self.pending.split(b"\n")
        self.pending = bytearray(rest)
        for line in lines:
            self._feed(line)
        self._read(stream)

    def _feed(self, raw):
        try:
            self._line(raw.decode("utf-8", "replace").rstrip("\r"))
        except Exception as e:  # noqa: BLE001
            self._append("warning", f"(couldn't show a line: {e})")

    def _line(self, line):
        kind, data = nixlog.split(line)
        if kind == "nix":
            for style, text in self.progress.feed(data):
                self._append(style, text)
            self.dirty = True
            if data.get("action") == "msg" and data.get("level") == nixlog.ERROR:
                self.errors.append(nixlog.strip_ansi(data.get("msg", "")))
        elif kind == "ns":
            self._event(data)
        else:
            text = nixlog.strip_ansi(line)
            if self.current == "collect" and text.startswith("deleting '/nix/store/"):
                self.deleted += 1  # thousands of these; counted, not logged
                return
            if self.current in ("switch", "boot"):
                self.switch_lines.append(text)
            if text.strip():
                self._append("error" if text.startswith("error") else "info", text)

    def _event(self, e):
        if "step" in e:
            state = {"start": "running", "done": "done", "failed": "failed"}.get(e.get("state"), "running")
            sid = e["step"]
            if sid == "build" and state == "running":
                self.cancel_button.set_visible(True)
                self.tiles_box.set_visible(True)
                self.running_group.set_visible(True)
            if sid == "build" and state != "running":
                self.cancel_button.set_visible(False)
                self.running_group.set_visible(False)
            if sid == "compare" and state == "done":
                self.mode = e.get("mode", self.mode)
                if self.mode == "boot" and "switch" in self.steps:
                    self.steps["switch"].set("skipped", "Used from the next restart instead")
            if sid == "save" and state == "running" and "auth" in self.steps:
                self.steps["auth"].set("done")
            self.step(sid, state)
            if sid == "switch" and state in ("done", "failed"):
                self._show_units()
        if "diff" in e:
            self._show_diff(closure.Diff.from_json(e["diff"]))
        if "kernel" in e:
            old, new = e["kernel"]
            self._note("system-reboot-symbolic", f"New kernel: Linux {old} → {new}",
                       "The new kernel is used from the next restart.")
            self.restart = True
        if "boot" in e:
            self._note("dialog-warning-symbolic", "Set up for the next restart",
                       "This update changes " + ", ".join(e["boot"]) + ". Switching to those "
                       "while logged in has frozen the desktop before, so the new system "
                       "starts at the next restart instead.")
        if "cleaned" in e:
            self.cleaned = e["cleaned"]
            versions, freed = self.cleaned.get("versions", 0), self.cleaned.get("freed", "")
            self._note("user-trash-symbolic", f"Freed {freed}" if freed else "Nothing to free",
                       f"{self.cleaned.get('paths', 0):,} unused files deleted from the Nix store")
            self._note("edit-delete-symbolic",
                       f"{versions} old system version{'s' if versions != 1 else ''} deleted",
                       "The boot menu now lists only the versions that are left.")
            self._append("info", f"Deleted {self.deleted:,} store paths.")
        if "error" in e:
            self.errors.append(e["error"])
            self._append("error", e["error"])
        if "result" in e:
            self.result = e
            if e.get("mode"):
                self.mode = e["mode"]

    def _exited(self, proc, res):
        try:
            proc.wait_finish(res)
            code = proc.get_exit_status() if proc.get_if_exited() else -1
        except GLib.Error:
            code = -1
        result = self.result.get("result")
        if self.cleaned is not None and result == "ok":
            freed = self.cleaned.get("freed")
            self._finish("ok", "Cleaned up", f"Freed {freed} of disk space." if freed
                         else "Nothing was old enough or unused, so no space was freed.")
        elif result == "ok" or (result is None and code == 0):
            boot = self.mode == "boot"
            self.restart = self.restart or boot
            heading = "Ready after a restart" if boot else "All done"
            detail = ("The new system starts the next time you restart." if boot
                      else "Your system is running the new settings.")
            if self.restart and not boot:
                detail += " Restart to use the new kernel."
            self._finish("ok", heading, detail)
        elif result == "cancelled":
            self._finish("cancelled", "Stopped", "The build was stopped and nothing was switched."
                         + (" Your settings were put back." if self.result.get("restored") else ""))
        elif result is None and code in (126, 127):
            self._finish("auth", "Nothing was changed",
                         "The password prompt was closed, or the password wasn't accepted.")
        else:
            reason = self._reason()
            if self.result.get("restored"):
                reason += "\n\nYour settings were put back the way they were."
            self._finish("failed", self._failed_heading(), reason)

    def _failed_heading(self):
        for sid in ("save", "build", "switch", "boot"):
            step = self.steps.get(sid)
            if step is not None and step.state == "failed":
                return {"save": "These settings don't work", "build": "The build failed",
                        "switch": "Switching failed", "boot": "The boot menu wasn't updated"}[sid]
        return "Something went wrong"

    def _reason(self):
        """One readable line for the hero; the whole error goes in its own card."""
        text = "\n\n".join(dict.fromkeys(self.errors))
        if text:
            self.error_label.set_text(text.strip())
            self.error_group.set_visible(True)
        failed = [n for n in self.progress.errors if "failed" in n.lower()]
        line = nixlog.first_error(failed[0] if failed else text)
        m = nixlog.BUILDER_FAILED.search(line)
        if m:
            code = f" (exit code {m.group(2)})" if m.group(2) else ""
            return f"{nixlog.store_name(m.group(1))} failed to build{code}. The error is below."
        return line or "The details are in the log below."

    #--------------------------------------------------------------------#
    #-- Results
    #--------------------------------------------------------------------#
    def _note(self, icon, title, subtitle):
        row = Adw.ActionRow(title=ui.esc(title), subtitle=ui.esc(subtitle))
        row.add_prefix(Gtk.Image(icon_name=ui.first_icon(icon), css_classes=["accent"],
                                 valign=Gtk.Align.CENTER))
        self.notes_group.add(row)
        self.notes_group.set_visible(True)

    def _show_diff(self, diff):
        fill_diff(self.diff_group, diff)
        self.diff_group.set_visible(True)

    def _show_units(self):
        units = nixlog.unit_changes(self.switch_lines)
        shown = False
        for key, title, icon in (("failed", "Failed", "dialog-error-symbolic"),
                                 ("restarted", "Restarted", "view-refresh-symbolic"),
                                 ("started", "Started", "media-playback-start-symbolic"),
                                 ("reloaded", "Reloaded", "emblem-synchronizing-symbolic"),
                                 ("stopped", "Stopped", "media-playback-stop-symbolic")):
            names = [u.removesuffix(".service") for u in units[key]]
            if not names:
                continue
            row = Adw.ActionRow(title=f"{title} ({len(names)})", subtitle=ui.esc(", ".join(names)),
                                subtitle_lines=3)
            image = Gtk.Image(icon_name=ui.first_icon(icon), valign=Gtk.Align.CENTER)
            if key == "failed":
                image.add_css_class("error")
            row.add_prefix(image)
            self.units_group.add(row)
            shown = True
        self.units_group.set_visible(shown)

    #--------------------------------------------------------------------#
    #-- Live updates
    #--------------------------------------------------------------------#
    def _tick(self):
        now = time.monotonic()
        total = (self.ended or now) - self.started
        self.title_widget.set_subtitle(ui.elapsed(total))
        for step in self.steps.values():
            step.tick()
        if self.ended is not None:
            self.tick_source = 0
            return False
        p = self.progress
        if self.current == "build":
            self._build_status(p, now)
        else:
            self.bar.pulse()
            if self.current == "collect" and self.deleted:
                self.detail.set_label(f"{self.deleted:,} unused files deleted so far")
        self.tiles["time"][0].set_label(ui.elapsed(total))
        self.tiles["time"][1].set_label("so far")
        if self.dirty:
            self._running(p, now)
            self.dirty = False
        return True

    def _build_status(self, p, now):
        got, total = p.downloaded(), p.download_total()
        self.samples = [(t, b) for t, b in self.samples if now - t < 4] + [(now, got)]
        speed = 0
        if len(self.samples) > 1 and self.samples[-1][0] > self.samples[0][0]:
            speed = (self.samples[-1][1] - self.samples[0][1]) / (self.samples[-1][0] - self.samples[0][0])
        done_d, want_d = p.copies[0], max(p.copies[1], p.will_fetch)
        done_b, want_b = p.builds[0], max(p.builds[1], p.will_build)
        self.tiles["downloads"][0].set_label(f"{done_d} / {want_d}" if want_d else "—")
        size = f"{closure.human_size(got)} of {closure.human_size(total)}" if total else "nothing to download"
        self.tiles["downloads"][1].set_label(size + (f" · {closure.human_size(speed)}/s" if speed > 0 else ""))
        self.tiles["builds"][0].set_label(f"{done_b} / {want_b}" if want_b else "—")
        self.tiles["builds"][1].set_label(f"{p.builds[2]} running" if p.builds[2] else
                                          ("nothing to build" if not want_b else "waiting"))
        if p.evaluating:
            self.heading.set_label("Reading your configuration…")
            self.detail.set_label(f"{p.eval_files:,} files read so far" if p.eval_files else
                                  "Working out what this system needs.")
            self.detail.set_visible(True)
            self.bar.pulse()
            return
        parts = []
        if want_d:
            parts.append(f"{done_d} of {want_d} downloaded")
        if want_b:
            parts.append(f"{done_b} of {want_b} built")
        self.heading.set_label("Downloading and building…" if want_b else "Downloading…" if want_d
                               else "Finishing the build…")
        self.detail.set_label(" · ".join(parts) or "Putting the new system together.")
        frac = p.fraction()
        if frac is None:
            self.bar.pulse()
        else:
            self.bar.set_fraction(frac)

    def _running(self, p, now):
        items = p.running()
        while len(self.running_rows) < len(items):
            row = Adw.ActionRow(title_lines=1, subtitle_lines=1)
            icon = Gtk.Image(valign=Gtk.Align.CENTER)
            row.add_prefix(icon)
            clock = Gtk.Label(css_classes=["dim-label", "numeric"], valign=Gtk.Align.CENTER)
            row.add_suffix(clock)
            self.running_list.append(row)
            self.running_rows.append((row, icon, clock))
        for i, (row, icon, clock) in enumerate(self.running_rows):
            if i >= len(items):
                row.set_visible(False)
                continue
            kind, name, detail, started = items[i]
            row.set_title(ui.esc(name or "…"))
            if kind == "download":
                done, total = detail
                row.set_subtitle(f"Downloading · {closure.human_size(done)} of {closure.human_size(total)}"
                                 if total else "Downloading")
                icon.set_from_icon_name(ui.first_icon("folder-download-symbolic"))
            elif kind == "build":
                row.set_subtitle(ui.esc(f"Building · {detail}" if detail else "Building"))
                icon.set_from_icon_name(ui.first_icon("system-run-symbolic"))
            else:
                row.set_subtitle("Fetching")
                icon.set_from_icon_name(ui.first_icon("emblem-synchronizing-symbolic"))
            clock.set_label(ui.elapsed(now - started))
            row.set_visible(True)
        self.running_count.set_label(f"{len(items)} at once" if len(items) > 1 else "")
        self.running_group.set_visible(bool(items) and self.current == "build")

    #--------------------------------------------------------------------#
    #-- Log
    #--------------------------------------------------------------------#
    def _append(self, style, text):
        buf = self.log.get_buffer()
        adj = self.log_scroll.get_vadjustment()
        follow = adj.get_value() >= adj.get_upper() - adj.get_page_size() - 40
        end = buf.get_end_iter()
        if style == "build" and "> " in text:
            name, rest = text.split("> ", 1)
            buf.insert_with_tags(end, name + "> ", self.tags["accent"])
            buf.insert(buf.get_end_iter(), rest + "\n")
        elif style in self.tags:
            buf.insert_with_tags(end, text + "\n", self.tags[style])
        else:
            buf.insert(end, text + "\n")
        self.log_lines += text.count("\n") + 1
        if self.log_lines > LOG_LIMIT:
            _, cut = buf.get_iter_at_line(1000)
            buf.delete(buf.get_start_iter(), cut)
            self.log_lines -= 1000
        if follow:
            self.log.scroll_mark_onscreen(self.end_mark)

    def _log_text(self):
        buf = self.log.get_buffer()
        return buf.get_text(buf.get_start_iter(), buf.get_end_iter(), False)

    def _toggle_log(self, button):
        shown = button.get_active()
        self.log_revealer.set_reveal_child(shown)
        button.set_label("Hide" if shown else "Show")
        if shown:
            GLib.idle_add(lambda: self.log.scroll_mark_onscreen(self.end_mark) and False)

    def _copy(self, text, toast):
        Gdk.Display.get_default().get_clipboard().set(text)
        self.window.toast(toast)

    #--------------------------------------------------------------------#
    #-- Endings
    #--------------------------------------------------------------------#
    def set_undo(self, label, callback):
        """Offers `callback` behind a button if the run fails or stops."""
        self.undo = callback
        self.undo_button.set_label(label)

    def _finish(self, outcome, heading, detail):
        self.outcome = outcome
        self.ended = time.monotonic()
        for step in self.steps.values():
            if step.state == "running":
                step.set("failed" if outcome == "failed" else "skipped")
        self.cancel_button.set_visible(False)
        self.running_group.set_visible(False)
        self.bar.set_visible(outcome == "ok")
        self.bar.set_fraction(1.0)
        icon = {"ok": "restart" if self.restart else "ok", "failed": "failed"}.get(outcome, "cancelled")
        self._hero(icon, heading, detail)
        self.undo_button.set_visible(self.undo is not None and outcome in ("failed", "cancelled"))
        self.restart_button.set_visible(outcome == "ok" and self.restart)
        if outcome == "ok" and self.restart:
            self.restart_button.add_css_class("suggested-action")
            self.done_button.remove_css_class("suggested-action")
            self.done_button.set_label("Later")
        self.done_button.set_visible(True)
        self.header.set_show_end_title_buttons(True)
        if outcome == "failed" and not self.log_toggle.get_active() and not self.error_group.get_visible():
            self.log_toggle.set_active(True)
        if self.tick_source:
            GLib.source_remove(self.tick_source)
            self.tick_source = 0
        self._tick()
        self.window.notify_done(outcome, heading)

    def _cancel(self, _):
        if self.proc is None or self.ended is not None:
            return
        self.cancel_button.set_sensitive(False)
        self.cancel_button.set_label("Stopping…")
        try:
            self.stdin.write_bytes(GLib.Bytes.new(b"cancel\n"), None)
            self.stdin.flush(None)
        except GLib.Error:
            pass

    def _undo(self, _):
        if self.undo is not None:
            message = self.undo()
            self.undo = None
            self.window.run_undo = None
            self.undo_button.set_visible(False)
            self.window.toast(message or "Changes undone")

    def _restart(self, _):
        self.window.restart()

    def close(self):
        if self.tick_source:
            GLib.source_remove(self.tick_source)
            self.tick_source = 0
        self.on_close(self.outcome or "failed")

    @property
    def running(self):
        return self.ended is None


def fill_diff(group, diff):
    """Adds chips and expandable package lists for `diff` to `group`."""
    chips = []
    if diff.updated:
        chips.append(ui.chip(f"{len(diff.updated)} updated", "accent"))
    if diff.added:
        chips.append(ui.chip(f"{len(diff.added)} new", "success"))
    if diff.removed:
        chips.append(ui.chip(f"{len(diff.removed)} removed", "neutral"))
    old, new = diff.size
    if old and new and old != new:
        chips.append(ui.chip(f"{closure.human_size(new - old, signed=True)} on disk", "neutral"))
    if chips:
        box = Adw.WrapBox(child_spacing=6, line_spacing=6, margin_bottom=10)
        for c in chips:
            box.append(c)
        group.add(box)
    for title, items, fmt in (
            ("Updated", diff.updated, lambda i: (i[0], f"{i[1]}  →  {i[2]}")),
            ("New", diff.added, lambda i: (i[0], i[1] if i[1] != "ε" else "")),
            ("Removed", diff.removed, lambda i: (i[0], i[1] if i[1] != "ε" else ""))):
        if not items:
            continue
        exp = Adw.ExpanderRow(title=f"{title} ({len(items)})",
                              subtitle=ui.esc(", ".join(i[0] for i in items[:6])
                                              + ("…" if len(items) > 6 else "")))
        for item in items[:300]:
            name, sub = fmt(item)
            exp.add_row(Adw.ActionRow(title=ui.esc(name), subtitle=ui.esc(sub), title_lines=1,
                                      css_classes=["property"] if sub else []))
        group.add(exp)
    if not (diff.updated or diff.added or diff.removed):
        files = f" ({diff.files} settings files)" if diff.files else ""
        group.add(Adw.ActionRow(title="No package versions changed",
                                subtitle=ui.esc("Only settings and generated files did" + files)))
