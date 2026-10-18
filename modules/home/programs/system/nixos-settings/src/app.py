"""NixOS Settings: pick apps and system options from menus, then rebuild."""

import grp
import json
import os
import re
import sys
import threading

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gdk, Gio, GLib, Gtk, Pango  # noqa: E402

import backend  # noqa: E402
import schema  # noqa: E402

#--- The root helper (nixos/system/user/nixos-settings-helper.nix) for non-admins
HELPER = "/run/current-system/sw/bin/nixos-settings-apply"

ANSI = re.compile(r"\x1b\[[0-9;?]*[ -/]*[@-~]|\x1b\][^\x07]*(\x07|\x1b\\)")

#--- descriptions.json marks app names **like this** and cautions !!like this!!
STRONG = re.compile(r"\*\*(.+?)\*\*")
CAUTION = re.compile(r"!!(.+?)!!")

#--- Page icons, by the first setting on the page
ICONS = {
    "hostName": "computer-symbolic",
    "timeZone": "preferences-desktop-locale-symbolic",
    "mullvad": "network-server-symbolic",
    "git": "avatar-default-symbolic",
    "browsers": "web-browser-symbolic",
    "terminals": "utilities-terminal-symbolic",
    "editors": "accessories-text-editor-symbolic",
    "fileBrowsers": "folder-symbolic",
    "defaultApps": "emblem-default-symbolic",
    "media": "applications-multimedia-symbolic",
    "wallpaper": "preferences-desktop-wallpaper-symbolic",
    "graphics": "applications-graphics-symbolic",
    "audio": "audio-x-generic-symbolic",
    "office": "x-office-document-symbolic",
    "security": "security-high-symbolic",
    "system": "utilities-system-monitor-symbolic",
    "scrcpy": "phone-symbolic",
    "gaming": "applications-games-symbolic",
    "discord": "user-available-symbolic",
    "claude": "applications-science-symbolic",
    "japanese": "input-keyboard-symbolic",
}
FALLBACK_ICON = "applications-system-symbolic"

#--- Bolder row titles; colours stay the theme's
CSS = """
row label.title { font-weight: bold; }
row.nixm-plain image.expander-row-arrow { opacity: 0; }
"""


def page_icon(page):
    name = ICONS.get(page.groups[0].settings[0].path[0], FALLBACK_ICON)
    display = Gdk.Display.get_default()
    return name if display and Gtk.IconTheme.get_for_display(display).has_icon(name) else FALLBACK_ICON


def theme_colors():
    """The theme's accent and warning colours, read off labels styled with them."""
    colors = {}
    for name in ("accent", "warning"):
        c = Gtk.Label(css_classes=[name]).get_color()
        # Wide-gamut accents can come back outside 0..1; clamp to a valid sRGB hex
        to8 = [max(0, min(255, round(v * 255))) for v in (c.red, c.green, c.blue)]
        colors[name] = "#%02x%02x%02x" % tuple(to8)
    return colors


def valid_markup(text):
    try:
        Pango.parse_markup(text, -1, "\x01")
        return True
    except GLib.Error:
        return False


def plain(text):
    return STRONG.sub(r"\1", CAUTION.sub(r"\1", text))


def rich(text, colors):
    """Pango markup for description text, with its ** and !! marks coloured."""
    text = GLib.markup_escape_text(text)
    text = STRONG.sub(lambda m: f'<span weight="bold" foreground="{colors["accent"]}">{m.group(1)}</span>', text)
    return CAUTION.sub(lambda m: f'<span weight="bold" foreground="{colors["warning"]}">{m.group(1)}</span>', text)


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
            done(False, -1)
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
                p.wait_finish(res)
                code = p.get_exit_status() if p.get_if_exited() else -1
            except GLib.Error:
                code = -1
            done(code == 0, code)

        stream.read_bytes_async(4096, GLib.PRIORITY_DEFAULT, None, read)


#--------------------------------------------------------------------#
#-- Main Window
#--------------------------------------------------------------------#
class Window(Adw.ApplicationWindow):
    def __init__(self, app, cfg):
        super().__init__(application=app, title="NixOS Settings", default_width=980, default_height=700,
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
            self._failed(err)
            return
        self.state = state
        self.changes = {}
        self.build()
        if toast:
            self.toasts.add_toast(Adw.Toast(title=toast))

    def _failed(self, err):
        """The error page; offers to drop settings the templates no longer have."""
        try:
            in_wheel = grp.getgrnam("wheel").gr_gid in os.getgroups()
        except KeyError:
            in_wheel = False
        direct = in_wheel and backend.writable(self.cfg)
        helper = os.path.realpath(HELPER) if os.path.exists(HELPER) else None
        try:
            # An admin can clean every user on the machine; anyone else only themself
            stale = backend.stale_settings(self.cfg, everyone=direct)
        except Exception:  # noqa: BLE001
            stale = []
        mine = [i for i in stale if direct or i[0] != "machine"]
        machine_file = f"machines/{self.cfg.machine}/settings.nix"

        def where(w, user):
            return {"user": f"users/{user}/settings.nix", "machine": machine_file,
                    "override": f"{machine_file}, {user}'s block"}[w]

        buttons = Gtk.Box(spacing=12, halign=Gtk.Align.CENTER)
        retry = Gtk.Button(label="Try Again", css_classes=["pill"])
        retry.connect("clicked", lambda _: self.reload())
        buttons.append(retry)
        text = str(err)
        if stale:
            text = "These settings aren't in the templates any more, so the files can't be read:\n" + \
                "\n".join(f"• {'.'.join(p)}  ({where(w, u)})" for w, u, p in stale)
            if len(mine) < len(stale):
                text += "\n\nAn admin needs to remove the computer-wide ones."
        if mine and (direct or helper):
            remove = Gtk.Button(label="Remove Them", css_classes=["pill", "suggested-action"])
            remove.connect("clicked", lambda _: self._clean(mine, direct, helper))
            buttons.append(remove)
        self._bare(Adw.StatusPage(icon_name="dialog-error-symbolic", title="Couldn't read the settings",
                                  description=GLib.markup_escape_text(text), child=buttons))

    def _clean(self, items, direct, helper):
        if direct:
            run_async(lambda: backend.remove_stale(self.cfg, items),
                      lambda _, err: self.reload(None if err else "Old settings removed"))
            return
        dialog = RebuildDialog(lambda: None)
        dialog.status("Removing old settings…", "Type your own password when asked.")
        dialog.present(self)

        def done(ok, code):
            if ok:
                dialog.finish(True, "Done", "")
                dialog.close()
                self.reload("Old settings removed")
            else:
                dialog.finish(False, "Nothing was removed", "The details below say why.")
        dialog.run([GLib.find_program_in_path("pkexec") or "pkexec", helper,
                    json.dumps({"clean": True})], done)

    #--- Layout
    def build(self):
        state = self.state
        self.rows, self.settings, self.scope_rows = {}, {}, []
        self.multi = len(state.user_machines) > 1
        # Admins write the files and run nixm; anyone else goes through the root
        # helper, which only takes their own app settings
        self.admin = bool(state.resolved["users"][self.cfg.user].get("admin"))
        self.direct = self.admin and backend.writable(self.cfg)
        self.helper = None if self.direct or not os.path.exists(HELPER) else os.path.realpath(HELPER)

        self.sidebar = Gtk.ListBox(css_classes=["navigation-sidebar"])
        self.sidebar.set_header_func(self._sidebar_header)
        self.stack = Gtk.Stack(transition_type=Gtk.StackTransitionType.CROSSFADE)
        self.colors = theme_colors()
        self.row_page, self.counts, self.page_rows = {}, [], []
        self.new_items = [(s, value) for path, value in state.new
                          for page in state.pages for g in page.groups for s in g.settings
                          if s.domain == "user" and s.path == path]
        if self.new_items:
            box = Gtk.Box(spacing=10, margin_top=4, margin_bottom=4)
            box.append(Gtk.Image(icon_name="starred-symbolic", css_classes=["accent"]))
            box.append(Gtk.Label(label="What's New", xalign=0, hexpand=True))
            box.append(Gtk.Label(label=str(len(self.new_items)), css_classes=["accent", "caption", "numeric"]))
            row = Gtk.ListBoxRow(child=box)
            row.section, row.page_index = "new", None
            self.sidebar.append(row)
            self.stack.add_named(self._new_page(), "new")
        for i, page in enumerate(state.pages):
            box = Gtk.Box(spacing=10, margin_top=4, margin_bottom=4)
            box.append(Gtk.Image(icon_name=page_icon(page)))
            box.append(Gtk.Label(label=page.title, xalign=0, hexpand=True,
                                 ellipsize=Pango.EllipsizeMode.END))
            count = Gtk.Label(css_classes=["dim-label", "caption", "numeric"])
            box.append(count)
            self.counts.append((page, count))
            row = Gtk.ListBoxRow(child=box)
            row.section, row.page_index = page.section, i
            self.page_rows.append(row)
            self.sidebar.append(row)
            self.page_index_now = i
            self.stack.add_named(self._page(page), str(i))
            self._count(i)
        self.sidebar.connect("row-selected", self._select)

        self.search = Gtk.SearchEntry(placeholder_text="Search apps and settings", margin_start=10,
                                      margin_end=10, margin_top=4, margin_bottom=6)
        self.search.connect("search-changed", self._search)
        self.search.set_key_capture_widget(self)  # typing anywhere starts a search
        side_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        side_box.append(self.search)
        side_box.append(Gtk.ScrolledWindow(child=self.sidebar, vexpand=True,
                                           hscrollbar_policy=Gtk.PolicyType.NEVER))
        side = Adw.ToolbarView(content=side_box)
        side.add_top_bar(Adw.HeaderBar())

        self.apply_button = Gtk.Button(label="Apply", css_classes=["suggested-action"])
        self.apply_button.connect("clicked", self._confirm)
        self.discard_button = Gtk.Button(label="Discard")
        self.discard_button.connect("clicked", lambda _: self._discard())
        header = Adw.HeaderBar()
        header.pack_end(self.apply_button)
        header.pack_end(self.discard_button)

        self.banner = Adw.Banner()
        if not self.direct and not self.helper:
            self.banner.set_title("Only an admin can apply changes on this computer"
                                  if not self.admin else f"You can't edit the files in {self.cfg.flake}")
        self.can_apply = self.direct or bool(self.helper)
        self.banner.set_revealed(not self.can_apply)

        content = Adw.ToolbarView(content=self.stack)
        content.add_top_bar(header)
        content.add_top_bar(self.banner)
        self.content_page = Adw.NavigationPage(title=state.pages[0].title, child=content)

        self.split.set_sidebar(Adw.NavigationPage(title="NixOS Settings", child=side))
        self.split.set_content(self.content_page)
        if self.toasts.get_child() is not self.split:
            self.toasts.set_child(self.split)

        self.sidebar.select_row(self.page_rows[min(self.page_index, len(state.pages) - 1)])
        self._update()

    def _sidebar_header(self, row, before):
        if row.section == "new":
            row.set_header(None)
        elif before is None or before.section != row.section:
            title = {"computer": "This Computer", "personal": "Personal", "apps": "Apps"}[row.section]
            label = Gtk.Label(label=title, xalign=0, css_classes=["heading", "dim-label"],
                              margin_start=12, margin_top=12 if before else 6, margin_bottom=6)
            row.set_header(label)
        else:
            row.set_header(None)

    def _select(self, _, row):
        if row is None:
            return
        if row.page_index is None:
            self.stack.set_visible_child_name("new")
            self.content_page.set_title("What's New")
            self.split.set_show_content(True)
            return
        self.page_index = row.page_index
        self.stack.set_visible_child_name(str(self.page_index))
        self.content_page.set_title(self.state.pages[self.page_index].title)
        self.split.set_show_content(True)

    #--- Search
    def _search(self, entry):
        words = entry.get_text().lower().split()
        old = self.stack.get_child_by_name("search")
        if old is not None:
            self.stack.remove(old)
        if not words:
            self.stack.set_visible_child_name(str(self.page_index))
            self.content_page.set_title(self.state.pages[self.page_index].title)
            return
        hits = []
        for i, page in enumerate(self.state.pages):
            for g in page.groups:
                for s in g.settings:
                    text = " ".join([s.title, s.subtitle, plain(s.note), plain(s.description), page.title,
                                     g.title, ".".join(s.path)]).lower()
                    if all(w in text for w in words):
                        hits.append((i, page, s))
        if hits:
            results = Adw.PreferencesPage()
            group = Adw.PreferencesGroup(title=f"{len(hits)} match{'es' if len(hits) != 1 else ''}")
            for i, page, s in hits:
                key = (s.domain, s.path)
                row = Adw.ActionRow(title=GLib.markup_escape_text(s.title),
                                    subtitle=GLib.markup_escape_text(page.title), activatable=True)
                row.add_prefix(Gtk.Image(icon_name=page_icon(page)))
                value = self.changes.get(key, self.state.value(self.cfg, s))
                row.add_suffix(Gtk.Label(label=shown(s, value), css_classes=["dim-label"],
                                         ellipsize=Pango.EllipsizeMode.END, max_width_chars=24))
                row.add_suffix(Gtk.Image(icon_name="go-next-symbolic"))
                row.connect("activated", lambda _, i=i, key=key: self._jump(i, key))
                group.add(row)
            results.add(group)
        else:
            results = Adw.StatusPage(icon_name="system-search-symbolic", title="No matches",
                                     description="Try an app name, like Steam or Zen.")
        self.stack.add_named(results, "search")
        self.stack.set_visible_child_name("search")
        self.content_page.set_title("Search")

    def _jump(self, i, key):
        """Opens the page holding a search hit and puts focus on its row."""
        self.search.set_text("")
        self.page_index = i
        self.sidebar.select_row(self.page_rows[i])
        self._select(self.sidebar, self.page_rows[i])
        row = self.rows[key][0]
        if isinstance(row, Adw.ExpanderRow):
            row.set_expanded(True)
        GLib.idle_add(row.grab_focus)

    def _new_page(self):
        prefs = Adw.PreferencesPage()
        hero = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        hero.append(Gtk.Image(icon_name="starred-symbolic", pixel_size=56, css_classes=["accent"]))
        hero.append(Gtk.Label(label="What's New", css_classes=["title-1"]))
        hero.append(Gtk.Label(
            label="These settings were added after your settings file was made, so it doesn't "
                  "mention them yet and every switch here counts as off. Add them with the "
                  "values they come with, or set them one by one on their own pages.",
            css_classes=["dim-label"], wrap=True, justify=Gtk.Justification.CENTER))
        add = Gtk.Button(label="Add Them With Their Defaults", halign=Gtk.Align.CENTER,
                         css_classes=["pill", "suggested-action"], margin_top=6)
        add.connect("clicked", self._adopt)
        hero.append(add)
        top = Adw.PreferencesGroup()
        top.add(hero)
        prefs.add(top)
        group = Adw.PreferencesGroup()
        index = {(s.domain, s.path): i for i, p in enumerate(self.state.pages)
                 for g in p.groups for s in g.settings}
        for s, value in self.new_items:
            i = index[(s.domain, s.path)]
            row = Adw.ActionRow(title=GLib.markup_escape_text(s.title),
                                subtitle=GLib.markup_escape_text(self.state.pages[i].title),
                                activatable=True)
            row.add_prefix(Gtk.Image(icon_name=page_icon(self.state.pages[i])))
            row.add_suffix(Gtk.Label(label=f"Default: {shown(s, value)}", css_classes=["dim-label"]))
            row.add_suffix(Gtk.Image(icon_name="go-next-symbolic"))
            row.connect("activated", lambda _, i=i, key=(s.domain, s.path): self._jump(i, key))
            group.add(row)
        prefs.add(group)
        return prefs

    def _adopt(self, _):
        """Stages every new setting at its template value, even where that matches
        what the missing line already means, so Apply writes it into the file."""
        for s, value in self.new_items:
            key = (s.domain, s.path)
            self.changes[key] = value
            self.rows[key][1].set_visible(True)
            self._count(self.row_page[key])
        self._update()
        self.toasts.add_toast(Adw.Toast(title="Press Apply to save them"))

    def _page(self, page):
        prefs = Adw.PreferencesPage()
        hero = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        hero.append(Gtk.Image(icon_name=page_icon(page), pixel_size=56, css_classes=["accent"]))
        hero.append(Gtk.Label(label=page.title, css_classes=["title-1"], wrap=True,
                              justify=Gtk.Justification.CENTER))
        if page.description:
            hero.append(Gtk.Label(label=page.description, css_classes=["dim-label"], wrap=True,
                                  justify=Gtk.Justification.CENTER))
        top = Adw.PreferencesGroup()
        top.add(hero)
        prefs.add(top)
        if page.domain == "user" and self.multi:
            group = Adw.PreferencesGroup()
            everywhere = ", ".join(self.state.user_machines)
            row = Adw.ComboRow(
                title="Change for",
                subtitle=f"Your settings on all of {everywhere}, or on this one alone",
                model=Gtk.StringList.new(["All my computers", f"Only this one ({self.cfg.machine})"]),
                selected=int(self.this_only))
            row.connect("notify::selected", self._scope)
            self.scope_rows.append(row)
            group.add(row)
            prefs.add(group)
        locked = [g for g in page.groups
                  if not self.direct and any(s.domain == "machine" for s in g.settings)]
        if locked:
            title = ("Only an admin can change these" if len(locked) == len(page.groups)
                     else "Only an admin can change the computer-wide settings here")
            note = Adw.ActionRow(title=title,
                                 subtitle="They apply to everyone who uses this computer.")
            note.add_prefix(Gtk.Image(icon_name="changes-prevent-symbolic", css_classes=["accent"]))
            group = Adw.PreferencesGroup()
            group.add(note)
            prefs.add(group)
        for g in page.groups:
            group = Adw.PreferencesGroup(title=GLib.markup_escape_text(g.title),
                                         description=GLib.markup_escape_text(g.description),
                                         sensitive=g not in locked)
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
        self.row_page[key] = self.page_index_now
        value = self.state.value(self.cfg, s)
        kind = s.kind
        if kind == "timezone":
            kind = "choice" if self.state.timezones else "text"
        # A described row keeps only its note under the name; the rest is in the dropdown
        subtitle = rich(s.note, self.colors) if s.description else GLib.markup_escape_text(s.subtitle)
        if self.multi and self.state.overridden(s):
            here = f'<span foreground="{self.colors["accent"]}">Set for this computer only</span>'
            subtitle = f"{subtitle}\n{here}" if subtitle else here
        if not valid_markup(subtitle):
            subtitle = GLib.markup_escape_text(plain(s.note if s.description else s.subtitle))
        common = dict(title=GLib.markup_escape_text(s.title), subtitle=subtitle, use_markup=True)
        described = bool(s.description) and kind in ("bool", "choice")

        control = None
        if kind == "bool":
            control = Gtk.Switch(active=bool(value), valign=Gtk.Align.CENTER)
            control.connect("notify::active", lambda w, _: self.change(s, w.get_active()))
        elif kind == "choice":
            options = s.choices if s.kind == "choice" else self.state.timezones
            if value not in options:
                options = [value] + options
            model = Gtk.StringList.new([choice_label(o) if s.kind == "choice" else o for o in options])
            control = Gtk.DropDown(model=model, selected=options.index(value), valign=Gtk.Align.CENTER)
            if len(options) > 12:
                control.set_enable_search(True)
                control.set_expression(Gtk.PropertyExpression.new(Gtk.StringObject, None, "string"))
            control.connect("notify::selected", lambda w, _: self.change(s, options[w.get_selected()]))
        elif kind != "list":
            placeholder = self.cfg.machine if s.path == ("hostName",) else "Not set"
            control = Gtk.Entry(text=value or "", valign=Gtk.Align.CENTER, width_chars=24,
                                placeholder_text=placeholder if s.nullable else "")
            control.connect("changed", lambda e: self.change(
                s, e.get_text() or (None if s.nullable else "")))

        marker = Gtk.Image(icon_name="document-edit-symbolic", visible=False, valign=Gtk.Align.CENTER,
                           tooltip_text="Changed; press Apply to use it")
        if kind == "list":
            row = self._list_row(s, list(value or []), common)
            row.add_suffix(marker)
        else:
            # Every row is an expander so controls line up down the page; one with
            # nothing to show keeps its arrow's space but not the arrow (CSS)
            row = Adw.ExpanderRow(**common)
            # An expander packs suffixes right to left, so its control goes in first
            row.add_suffix(control)
            row.add_suffix(marker)
            if described:
                row.add_row(self._description(s.description))
            else:
                row.set_enable_expansion(False)
                row.add_css_class("nixm-plain")
        self.rows[key] = (row, marker)
        return row

    def _description(self, text):
        label = Gtk.Label(wrap=True, xalign=0, margin_top=10, margin_bottom=10,
                          margin_start=12, margin_end=12)
        markup = rich(text, self.colors)
        if valid_markup(markup):
            label.set_markup(markup)
        else:
            label.set_text(plain(text))
        return label

    def _list_row(self, s, items, common):
        row = Adw.ExpanderRow(**common)
        if s.description:
            row.add_row(self._description(s.description))
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
        self._count(self.row_page[key])
        self._update()

    def _count(self, i):
        """Sidebar count of the switches turned on in page i, pending changes included."""
        page, label = self.counts[i]
        flags = [self.changes.get((s.domain, s.path), self.state.value(self.cfg, s))
                 for g in page.groups for s in g.settings if s.kind == "bool"]
        label.set_label(f"{sum(map(bool, flags))}/{len(flags)}" if flags else "")

    def _update(self):
        n = len(self.changes)
        self.apply_button.set_label(f"Apply {n} Change{'s' if n != 1 else ''}" if n else "Apply")
        self.apply_button.set_sensitive(bool(n) and self.can_apply)
        self.discard_button.set_visible(bool(n))

    def _discard(self):
        self.changes = {}
        self.build()

    def _confirm(self, _):
        lines, restart, user_changes, recorded = [], False, False, 0
        for key, value in self.changes.items():
            s = self.settings[key]
            before = shown(s, self.state.value(self.cfg, s))
            if before == shown(s, value):
                recorded += 1
            else:
                lines.append(f"{s.title}: {before} → {shown(s, value)}")
            restart |= (s.domain, ".".join(s.path)) in schema.RESTART
            user_changes |= s.domain == "user"
        if recorded:
            lines.append(f"Plus {recorded} new setting{'s' if recorded != 1 else ''} "
                         "saved into your file unchanged")
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
        if self.helper:
            pkexec = GLib.find_program_in_path("pkexec")
            if pkexec is None:
                self.busy = False
                dialog.finish(False, "pkexec wasn't found", "Nothing was changed.")
                return
            request = {"mode": "boot" if boot else "switch", "thisMachineOnly": this_only,
                       "changes": [[list(path), value] for (_, path), value in changes.items()]}
            dialog.status("Applying your settings…",
                          "Type your own password when asked. The rebuild can take several minutes.")
            dialog.run([pkexec, self.helper, json.dumps(request)],
                       lambda ok, code: self._helped(dialog, boot, ok, code))
            return
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
        dialog.run([nixm, "boot" if boot else "rebuild"], lambda ok, _: self._rebuilt(dialog, boot, ok))

    def _helped(self, dialog, boot, ok, code):
        if ok:
            self._rebuilt(dialog, boot, True)
            return
        self.busy = False
        if code in (126, 127):  # pkexec: prompt dismissed, or not authorised
            dialog.finish(False, "Nothing was changed", "The password prompt was cancelled or refused.")
        else:
            dialog.finish(False, "Your settings weren't applied",
                          "Anything saved was put back. The details below say why.")

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
        super().__init__(application_id="dev.nixosconfig.Settings", flags=Gio.ApplicationFlags.DEFAULT_FLAGS)

    def do_startup(self):
        Adw.Application.do_startup(self)
        css = Gtk.CssProvider()
        css.load_from_string(CSS)
        Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), css,
                                                  Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

    def do_activate(self):
        window = self.props.active_window or Window(self, backend.Config.from_env())
        window.present()


if __name__ == "__main__":
    sys.exit(App().run(sys.argv))
