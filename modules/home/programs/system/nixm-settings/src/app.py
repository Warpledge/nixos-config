"""nixm Settings: pick apps and system options from menus, then rebuild."""

import os
import re
import sys
import threading

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gio, GLib, Gtk  # noqa: E402

import backend  # noqa: E402
import schema  # noqa: E402

ANSI = re.compile(r"\x1b\[[0-9;?]*[ -/]*[@-~]|\x1b\][^\x07]*(\x07|\x1b\\)")


def run_async(work, done):
    """Runs `work` off the main loop and hands done(result, error) back to it."""
    def target():
        try:
            result, error = work(), None
        except Exception as e:  # noqa: BLE001
            result, error = None, e
        GLib.idle_add(done, result, error)
    threading.Thread(target=target, daemon=True).start()


def shown(setting, value):
    if setting.kind == "bool":
        return "On" if value else "Off"
    if value is None or value == "" or value == []:
        return "Not set"
    if isinstance(value, list):
        return ", ".join(value)
    return choice_label(value) if setting.kind == "choice" else str(value)


def choice_label(value):
    return "None" if value is None else value[:1].upper() + value[1:]


#--------------------------------------------------------------------#
#-- Rebuild Dialog
#--------------------------------------------------------------------#
class RebuildDialog(Adw.Dialog):
    def __init__(self, on_undo):
        super().__init__(title="Applying Changes", content_width=680, content_height=480, can_close=False)
        self.on_undo = on_undo

        self.heading = Gtk.Label(css_classes=["title-2"], wrap=True, xalign=0)
        self.detail = Gtk.Label(css_classes=["dim-label"], wrap=True, xalign=0)
        self.progress = Gtk.ProgressBar()
        self.pulse = GLib.timeout_add(120, self._pulse)

        self.log = Gtk.TextView(editable=False, cursor_visible=False, monospace=True,
                                wrap_mode=Gtk.WrapMode.WORD_CHAR, top_margin=8, bottom_margin=8,
                                left_margin=8, right_margin=8)
        self.end = self.log.get_buffer().create_mark("end", self.log.get_buffer().get_end_iter(), False)
        scroll = Gtk.ScrolledWindow(child=self.log, vexpand=True, min_content_height=220,
                                    css_classes=["card"])
        self.expander = Gtk.Expander(label="Details", child=scroll, vexpand=True)

        self.undo = Gtk.Button(label="Undo My Changes", visible=False, css_classes=["destructive-action"])
        self.undo.connect("clicked", self._undo)
        self.close_button = Gtk.Button(label="Close", visible=False, css_classes=["suggested-action"])
        self.close_button.connect("clicked", lambda _: self.close())
        buttons = Gtk.Box(spacing=12, halign=Gtk.Align.END)
        buttons.append(self.undo)
        buttons.append(self.close_button)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12, margin_top=6,
                      margin_bottom=18, margin_start=18, margin_end=18)
        for w in (self.heading, self.detail, self.progress, self.expander, buttons):
            box.append(w)
        view = Adw.ToolbarView(content=box)
        view.add_top_bar(Adw.HeaderBar(show_end_title_buttons=False, show_start_title_buttons=False))
        self.set_child(view)
        self.status("Checking your settings…", "")

    def _pulse(self):
        self.progress.pulse()
        return True

    def status(self, heading, detail):
        self.heading.set_label(heading)
        self.detail.set_label(detail)
        self.detail.set_visible(bool(detail))

    def append(self, text):
        buf = self.log.get_buffer()
        buf.insert(buf.get_end_iter(), text + "\n")
        self.log.scroll_mark_onscreen(self.end)

    def finish(self, ok, heading, detail, undo=False):
        if self.pulse:
            GLib.source_remove(self.pulse)
            self.pulse = 0
        self.progress.set_fraction(1.0 if ok else 0.0)
        self.progress.set_visible(ok)
        self.status(heading, detail)
        self.undo.set_visible(undo)
        self.close_button.set_visible(True)
        self.set_can_close(True)
        if not ok:
            self.expander.set_expanded(True)

    def _undo(self, _):
        self.on_undo()
        self.close()

    def run(self, argv, done):
        try:
            proc = Gio.Subprocess.new(argv, Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_MERGE)
        except GLib.Error as e:
            self.append(e.message)
            done(False)
            return
        stream = proc.get_stdout_pipe()
        pending = bytearray()

        def emit(line):
            # nom redraws its progress with \r; keep the last frame of each line
            text = ANSI.sub("", line.decode(errors="replace")).split("\r")[-1].rstrip()
            if text:
                self.append(text)

        def read(src, res):
            try:
                chunk = src.read_bytes_finish(res).get_data()
            except GLib.Error:
                chunk = b""
            if not chunk:
                if pending:
                    emit(bytes(pending))
                proc.wait_check_async(None, finished)
                return
            pending.extend(chunk)
            *lines, rest = pending.split(b"\n")
            pending[:] = rest
            for line in lines:
                emit(line)
            src.read_bytes_async(4096, GLib.PRIORITY_DEFAULT, None, read)

        def finished(p, res):
            try:
                ok = p.wait_check_finish(res)
            except GLib.Error:
                ok = False
            done(ok)

        stream.read_bytes_async(4096, GLib.PRIORITY_DEFAULT, None, read)


#--------------------------------------------------------------------#
#-- Main Window
#--------------------------------------------------------------------#
class Window(Adw.ApplicationWindow):
    def __init__(self, app, cfg):
        super().__init__(application=app, title="nixm Settings", default_width=980, default_height=700,
                         width_request=360, height_request=294)
        self.cfg = cfg
        self.state = None
        self.changes = {}
        self.rows = {}
        self.settings = {}
        self.this_only = False
        self.busy = False
        self.undo = None
        self.page_index = 0
        self.toasts = Adw.ToastOverlay()
        self.set_content(self.toasts)
        self.split = Adw.NavigationSplitView(min_sidebar_width=200)
        narrow = Adw.Breakpoint.new(Adw.BreakpointCondition.parse("max-width: 600sp"))
        narrow.add_setter(self.split, "collapsed", True)
        self.add_breakpoint(narrow)
        self.connect("close-request", self._on_close)
        self.reload()

    def _on_close(self, _):
        if self.busy:
            self.toasts.add_toast(Adw.Toast(title="Wait for the rebuild to finish"))
            return True
        return False

    def _bare(self, child):
        view = Adw.ToolbarView(content=child)
        view.add_top_bar(Adw.HeaderBar())
        self.toasts.set_child(view)

    #--- Loading
    def reload(self, toast=None):
        spinner = Gtk.Spinner(spinning=True, width_request=32, height_request=32)
        self._bare(Adw.StatusPage(title="Reading your settings…", child=spinner))
        run_async(lambda: backend.load(self.cfg), lambda state, err: self._loaded(state, err, toast))

    def _loaded(self, state, err, toast):
        if err is None and self.cfg.user not in state.resolved["users"]:
            err = backend.SettingsError(
                f"{self.cfg.user} isn't listed in machines/{self.cfg.machine}/settings.nix")
        if err is not None:
            retry = Gtk.Button(label="Try Again", halign=Gtk.Align.CENTER, css_classes=["pill", "suggested-action"])
            retry.connect("clicked", lambda _: self.reload())
            self._bare(Adw.StatusPage(icon_name="dialog-error-symbolic", title="Couldn't read the settings",
                                      description=GLib.markup_escape_text(str(err)), child=retry))
            return
        self.state = state
        self.changes = {}
        self.build()
        if toast:
            self.toasts.add_toast(Adw.Toast(title=toast))

    #--- Layout
    def build(self):
        state = self.state
        self.rows, self.settings, self.scope_rows = {}, {}, []
        self.multi = len(state.user_machines) > 1

        self.sidebar = Gtk.ListBox(css_classes=["navigation-sidebar"])
        self.sidebar.set_header_func(self._sidebar_header)
        self.stack = Gtk.Stack(transition_type=Gtk.StackTransitionType.CROSSFADE)
        for i, page in enumerate(state.pages):
            row = Gtk.ListBoxRow(child=Gtk.Label(label=page.title, xalign=0, margin_top=4, margin_bottom=4))
            row.domain = page.domain
            self.sidebar.append(row)
            self.stack.add_named(self._page(page), str(i))
        self.sidebar.connect("row-selected", self._select)

        side = Adw.ToolbarView(content=Gtk.ScrolledWindow(child=self.sidebar,
                                                          hscrollbar_policy=Gtk.PolicyType.NEVER))
        side.add_top_bar(Adw.HeaderBar())

        self.apply_button = Gtk.Button(label="Apply", css_classes=["suggested-action"])
        self.apply_button.connect("clicked", self._confirm)
        self.discard_button = Gtk.Button(label="Discard")
        self.discard_button.connect("clicked", lambda _: self._discard())
        header = Adw.HeaderBar()
        header.pack_end(self.apply_button)
        header.pack_end(self.discard_button)

        self.banner = Adw.Banner()
        user = state.resolved["users"][self.cfg.user]
        if not user.get("admin"):
            self.banner.set_title("Only an admin can apply changes on this computer")
        elif not backend.writable(self.cfg):
            self.banner.set_title(f"You can't edit the files in {self.cfg.flake}")
        self.can_apply = not self.banner.get_title()
        self.banner.set_revealed(not self.can_apply)

        content = Adw.ToolbarView(content=self.stack)
        content.add_top_bar(header)
        content.add_top_bar(self.banner)
        self.content_page = Adw.NavigationPage(title=state.pages[0].title, child=content)

        self.split.set_sidebar(Adw.NavigationPage(title="nixm Settings", child=side))
        self.split.set_content(self.content_page)
        self.toasts.set_child(self.split)

        self.sidebar.select_row(self.sidebar.get_row_at_index(min(self.page_index, len(state.pages) - 1)))
        self._update()

    def _sidebar_header(self, row, before):
        if before is None or before.domain != row.domain:
            title = "This Computer" if row.domain == "machine" else "Your Apps and Account"
            label = Gtk.Label(label=title, xalign=0, css_classes=["heading", "dim-label"],
                              margin_start=12, margin_top=12 if before else 6, margin_bottom=6)
            row.set_header(label)
        else:
            row.set_header(None)

    def _select(self, _, row):
        if row is None:
            return
        self.page_index = row.get_index()
        self.stack.set_visible_child_name(str(self.page_index))
        self.content_page.set_title(self.state.pages[self.page_index].title)
        self.split.set_show_content(True)

    def _page(self, page):
        prefs = Adw.PreferencesPage(description=page.description)
        if page.domain == "user" and self.multi:
            group = Adw.PreferencesGroup()
            row = Adw.ComboRow(title="Change for", model=Gtk.StringList.new(
                ["All my computers", f"Only this computer ({self.cfg.machine})"]),
                selected=int(self.this_only))
            row.connect("notify::selected", self._scope)
            self.scope_rows.append(row)
            group.add(row)
            prefs.add(group)
        for g in page.groups:
            group = Adw.PreferencesGroup(title=GLib.markup_escape_text(g.title),
                                         description=GLib.markup_escape_text(g.description))
            for s in g.settings:
                group.add(self._row(s))
            prefs.add(group)
        return prefs

    def _scope(self, row, _):
        self.this_only = row.get_selected() == 1
        for other in self.scope_rows:
            if other is not row and other.get_selected() != row.get_selected():
                other.set_selected(row.get_selected())

    #--- Rows
    def _row(self, s):
        key = (s.domain, s.path)
        self.settings[key] = s
        value = self.state.value(self.cfg, s)
        kind = s.kind
        if kind == "timezone":
            kind = "choice" if self.state.timezones else "text"
        common = dict(title=s.title, subtitle=s.subtitle, use_markup=False)

        if kind == "bool":
            row = Adw.SwitchRow(active=bool(value), **common)
            row.connect("notify::active", lambda r, _: self.change(s, r.get_active()))
        elif kind == "choice":
            options = s.choices if s.kind == "choice" else self.state.timezones
            if value not in options:
                options = [value] + options
            row = Adw.ComboRow(model=Gtk.StringList.new([choice_label(o) if s.kind == "choice" else o
                                                         for o in options]),
                               selected=options.index(value), **common)
            if len(options) > 12:
                row.set_enable_search(True)
                row.set_expression(Gtk.PropertyExpression.new(Gtk.StringObject, None, "string"))
            row.connect("notify::selected", lambda r, _: self.change(s, options[r.get_selected()]))
        elif kind == "list":
            row = self._list_row(s, list(value or []), common)
        else:
            row = Adw.ActionRow(**common)
            placeholder = self.cfg.machine if s.path == ("hostName",) else "Not set"
            entry = Gtk.Entry(text=value or "", valign=Gtk.Align.CENTER, width_chars=24,
                              placeholder_text=placeholder if s.nullable else "")
            entry.connect("changed", lambda e: self.change(
                s, e.get_text() or (None if s.nullable else "")))
            row.add_suffix(entry)
            row.set_activatable_widget(entry)

        if self.multi and self.state.overridden(s):
            row.add_suffix(Gtk.Label(label="This computer only", css_classes=["dim-label", "caption"],
                                     valign=Gtk.Align.CENTER))
        marker = Gtk.Image(icon_name="document-edit-symbolic", visible=False, valign=Gtk.Align.CENTER,
                           tooltip_text="Changed; press Apply to use it")
        row.add_suffix(marker)
        self.rows[key] = (row, marker)
        return row

    def _list_row(self, s, items, common):
        row = Adw.ExpanderRow(**common)
        if s.options:
            names = s.options + [x for x in items if x not in s.options]
            switches = []

            def toggled(*_):
                on = {n for n, sw in switches if sw.get_active()}
                self.change(s, [x for x in items if x in on] + [n for n in names if n in on and n not in items])
            for name in names:
                sw = Adw.SwitchRow(title=name, active=name in items, use_markup=False)
                sw.connect("notify::active", toggled)
                switches.append((name, sw))
                row.add_row(sw)
            return row

        children, current = [], list(items)

        def render():
            for c in children:
                row.remove(c)
            children.clear()
            for item in current:
                r = Adw.ActionRow(title=item, title_lines=1, use_markup=False)
                remove = Gtk.Button(icon_name="user-trash-symbolic", valign=Gtk.Align.CENTER,
                                    css_classes=["flat"], tooltip_text="Remove")
                remove.connect("clicked", lambda _, i=item: (current.remove(i), render(),
                                                             self.change(s, list(current))))
                r.add_suffix(remove)
                children.append(r)
                row.add_row(r)
            add = Adw.EntryRow(title="Add one", show_apply_button=True)

            def added(e):
                text = e.get_text().strip()
                if text and text not in current:
                    current.append(text)
                    render()
                    self.change(s, list(current))
            add.connect("apply", added)
            children.append(add)
            row.add_row(add)
        render()
        return row

    #--- Changes
    def change(self, s, value):
        key = (s.domain, s.path)
        if value == self.state.value(self.cfg, s):
            self.changes.pop(key, None)
        else:
            self.changes[key] = value
        self.rows[key][1].set_visible(key in self.changes)
        self._update()

    def _update(self):
        n = len(self.changes)
        self.apply_button.set_label(f"Apply {n} Change{'s' if n != 1 else ''}" if n else "Apply")
        self.apply_button.set_sensitive(bool(n) and self.can_apply)
        self.discard_button.set_visible(bool(n))

    def _discard(self):
        self.changes = {}
        self.build()

    def _confirm(self, _):
        lines, restart, user_changes = [], False, False
        for key, value in self.changes.items():
            s = self.settings[key]
            lines.append(f"{s.title}: {shown(s, self.state.value(self.cfg, s))} → {shown(s, value)}")
            restart |= (s.domain, ".".join(s.path)) in schema.RESTART
            user_changes |= s.domain == "user"
        body = "\n".join(lines)
        if user_changes and self.multi:
            where = f"this computer ({self.cfg.machine}) only" if self.this_only else "all your computers"
            body += f"\n\nApp changes are saved for {where}."
        if restart:
            body += "\n\nKernel and window manager changes take effect after a restart."
        n = len(self.changes)
        dialog = Adw.AlertDialog(heading=f"Apply {n} Change{'s' if n != 1 else ''}?", body=body)
        dialog.add_response("cancel", "Cancel")
        dialog.add_response("boot", "Apply at Next Restart")
        dialog.add_response("now", "Apply Now")
        best = "boot" if restart else "now"
        dialog.set_response_appearance(best, Adw.ResponseAppearance.SUGGESTED)
        dialog.set_default_response(best)
        dialog.set_close_response("cancel")
        dialog.connect("response", lambda _, r: r != "cancel" and self._apply(r == "boot"))
        dialog.present(self)

    def _apply(self, boot):
        self.busy = True
        self.undo = None
        dialog = RebuildDialog(self._undo)
        dialog.connect("closed", lambda _: self.reload(self.done_toast))
        self.done_toast = None
        dialog.present(self)
        changes, this_only = dict(self.changes), self.this_only
        run_async(lambda: backend.write(self.cfg, self.state, changes, this_only),
                  lambda old, err: self._written(dialog, boot, old, err))

    def _written(self, dialog, boot, old, err):
        if err is not None:
            self.busy = False
            dialog.append(str(err))
            dialog.finish(False, "These settings don't work",
                          "Nothing was saved. The details below say which setting was refused.")
            return
        self.undo = old
        nixm = GLib.find_program_in_path("nixm")
        if nixm is None:
            self.busy = False
            dialog.finish(False, "nixm wasn't found", "Your changes were saved but not applied.", undo=True)
            return
        dialog.status("Building your system…",
                      "This can take several minutes. A window will ask for your password.")
        dialog.run([nixm, "boot" if boot else "rebuild"], lambda ok: self._rebuilt(dialog, boot, ok))

    def _rebuilt(self, dialog, boot, ok):
        self.busy = False
        if ok:
            self.done_toast = "Changes saved; restart to use them" if boot else "Changes applied"
            dialog.finish(True, "Restart to finish" if boot else "Done",
                          "The new settings are used from the next restart." if boot
                          else "Your system is using the new settings.")
        else:
            dialog.finish(False, "The rebuild failed",
                          "Undo puts the settings files back the way they were.",
                          undo=True)

    def _undo(self):
        if self.undo:
            backend.restore(self.cfg, self.undo)
            self.undo = None
            self.done_toast = "Changes undone"


class App(Adw.Application):
    def __init__(self):
        super().__init__(application_id="dev.nixm.Settings", flags=Gio.ApplicationFlags.DEFAULT_FLAGS)

    def do_activate(self):
        window = self.props.active_window or Window(self, backend.Config.from_env())
        window.present()


if __name__ == "__main__":
    sys.exit(App().run(sys.argv))
