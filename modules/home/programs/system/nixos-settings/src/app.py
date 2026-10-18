"""NixOS Settings: pick apps and system options from menus, then rebuild."""

import grp
import json
import os
import pwd
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gio, GLib, GObject, Gtk, Pango  # noqa: E402

import backend  # noqa: E402
import closure  # noqa: E402
import dms  # noqa: E402
import schema  # noqa: E402
import session  # noqa: E402
import system  # noqa: E402
import ui  # noqa: E402
from flatpaks import FlatpakPage  # noqa: E402
from overview import Overview  # noqa: E402
from proton import ProtonPage  # noqa: E402
from runview import RunView, fill_diff  # noqa: E402
from windowrules import WindowRulesPage  # noqa: E402

#--- The root helper every rebuild goes through (nixos/system/user/nixos-settings-helper.nix)
HELPER = "/run/current-system/sw/bin/nixos-settings-apply"
APP_ID = "dev.nixosconfig.Settings"
VERSION = "2.0"

#--- DMS search entries the config sets itself, and the setting here that does it
#--- ("" when the theme sets it and nothing here changes it)
OWNED = {"Cursor Theme": "cursor", "Cursor Size": "cursorSize", "Icon Theme": "",
         "Dark Mode Icon Theme": "", "Light Mode Icon Theme": "", "Normal Font": "", "Monospace Font": ""}

#--- The tabs under the search entry, each with its own sidebar
TABS = [("main", "Main"), ("niri", "Niri"), ("docs", "Docs")]

#--- Each tab's pages above its sidebar sections: key, title and icons to try
TOP = {"main": [("overview", "Overview", ("computer-symbolic",)),
                ("flatpaks", "Flatpaks", ("flatpak-symbolic", "system-software-install-symbolic"))],
       "niri": [("windowrules", "Window Rules",
                 ("window-new-symbolic", "preferences-system-windows-symbolic"))],
       "docs": [("proton", "Proton", ("input-gaming-symbolic", "applications-games-symbolic"))]}


def shown(setting, value):
    if setting.kind == "bool":
        return "On" if value else "Off"
    if value is None or value == "" or value == []:
        return "Not set"
    if isinstance(value, list):
        return ", ".join(str(v) for v in value)
    return choice_label(setting, value) if setting.kind == "choice" else str(value)


def choice_label(setting, value):
    if str(value) in setting.labels:
        return setting.labels[str(value)]
    if value is None:
        return "None"
    if isinstance(value, int):
        return f"{value} px" if setting.path == ("cursorSize",) else str(value)
    return value[:1].upper() + value[1:]


#--- This build's store path: <package>/share/nixos-settings/app.py, three levels up
RUNNING = os.path.dirname(os.path.dirname(os.path.dirname(os.path.realpath(__file__))))


def installed_package():
    """The store path of the NixOS Settings the profile now holds, which a
    switch replaces while this build keeps running; None if it can't be found."""
    path = GLib.find_program_in_path("nixos-settings")
    if not path:
        return None
    package = os.path.dirname(os.path.dirname(os.path.realpath(path)))
    return package if package.startswith("/nix/store/") else None


def in_wheel():
    """From /etc/group, as the helper checks it, not the session's groups,
    which stay as they were at login."""
    try:
        me = pwd.getpwuid(os.getuid())
        return grp.getgrnam("wheel").gr_gid in os.getgrouplist(me.pw_name, me.pw_gid)
    except KeyError:
        return False


#--------------------------------------------------------------------#
#-- Main Window
#--------------------------------------------------------------------#
class Window(Adw.ApplicationWindow):
    def __init__(self, app, cfg):
        super().__init__(application=app, title="NixOS Settings", default_width=1080, default_height=780,
                         width_request=360, height_request=294)
        self.cfg = cfg
        self.state = None
        self.info = None
        self.ports = []
        self.changes = {}
        self.rows = {}
        self.settings = {}
        self.setters = {}
        self.page_of = {}
        self.scope = None  # machine whose block takes user settings; "" for all
        self.admin = False
        self.direct = False
        self.helper = None
        self.session = None  # the root helper, kept while the window is open
        self.run_view = None
        self.run_undo = None
        self.page_key = "overview"
        self.tab = "main"
        self.tab_keys = {tab: [] for tab, _ in TABS}  # each tab's sidebar keys, in order
        self.tab_of = {}  # sidebar key -> its tab
        self.tab_page = {}  # tab -> the page last shown in it
        self.switching = False
        self.colors = {}
        self.building = False
        self.run_message = None

        self.builders = {}  # sidebar key -> makes that page, the first time it's shown
        self.toasts = Adw.ToastOverlay()
        self.root = Gtk.Stack(transition_type=Gtk.StackTransitionType.CROSSFADE, transition_duration=200)
        self.toasts.set_child(self.root)
        self.set_content(self.toasts)
        self._skeleton()
        self._actions()
        self.connect("close-request", self._on_close)
        self.reload()

    #--------------------------------------------------------------------#
    #-- Skeleton (made once; build() fills it)
    #--------------------------------------------------------------------#
    def _skeleton(self):
        self.sidebars = {}
        self.side_stack = Gtk.Stack(transition_type=Gtk.StackTransitionType.CROSSFADE,
                                    transition_duration=150, vexpand=True)
        for tab, _ in TABS:
            sidebar = Adw.Sidebar()
            sidebar.connect("notify::selected", self._selected, tab)
            sidebar.connect("activated", lambda *_: self.split.set_show_content(True))
            self.sidebars[tab] = sidebar
            self.side_stack.add_named(sidebar, tab)
        self.tabs = Adw.ToggleGroup(margin_start=10, margin_end=10, margin_bottom=8,
                                    css_classes=["round"], homogeneous=True)
        for tab, title in TABS:
            self.tabs.add(Adw.Toggle(name=tab, label=title))
        self.tabs.set_active_name(self.tab)
        self.tabs.connect("notify::active-name", self._tab_changed)
        self.search = Gtk.SearchEntry(placeholder_text="Search settings", margin_start=10, margin_end=10,
                                      margin_top=2, margin_bottom=8)
        self.search.connect("search-changed", self._search)
        self.search.connect("stop-search", lambda *_: self.search.set_text(""))
        self.search.set_key_capture_widget(self)  # typing anywhere starts a search
        side_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        side_box.append(self.search)
        side_box.append(self.tabs)
        side_box.append(self.side_stack)
        menu = Gio.Menu()
        section = Gio.Menu()
        section.append("Reload Settings", "win.reload")
        section.append("Open the Config Folder", "win.open-folder")
        menu.append_section(None, section)
        section = Gio.Menu()
        section.append("Keyboard Shortcuts", "win.shortcuts")
        section.append("About NixOS Settings", "win.about")
        menu.append_section(None, section)
        side_header = Adw.HeaderBar()
        side_header.pack_end(Gtk.MenuButton(icon_name="open-menu-symbolic", menu_model=menu,
                                            tooltip_text="Main Menu", primary=True))
        side = Adw.ToolbarView(content=side_box)
        side.add_top_bar(side_header)

        self.stack = Gtk.Stack(transition_type=Gtk.StackTransitionType.CROSSFADE, transition_duration=150)
        self.banner = Adw.Banner()

        #--- The bar that slides up while changes wait
        self.pending_label = Gtk.Label(css_classes=["heading"])
        dot = Gtk.Box(css_classes=["pending-dot"], valign=Gtk.Align.CENTER)
        start = Gtk.Box(spacing=10, margin_start=6)
        start.append(dot)
        start.append(self.pending_label)
        review = Gtk.Button(label="Review", css_classes=["flat"])
        review.connect("clicked", lambda _: self._review())
        self.discard_button = Gtk.Button(label="Discard", tooltip_text="Throw away the changes")
        self.discard_button.connect("clicked", lambda _: self._discard())
        self.apply_button = Gtk.Button(label="Apply", css_classes=["suggested-action"],
                                       tooltip_text="Save and rebuild (Ctrl+S)")
        self.apply_button.connect("clicked", lambda _: self._confirm())
        actions = Gtk.ActionBar()
        actions.pack_start(start)
        actions.pack_start(review)
        actions.pack_end(self.apply_button)
        actions.pack_end(self.discard_button)

        self.content = Adw.ToolbarView(content=self.stack, reveal_bottom_bars=False)
        self.content.add_top_bar(Adw.HeaderBar())
        self.content.add_top_bar(self.banner)
        self.content.add_bottom_bar(actions)
        self.content_page = Adw.NavigationPage(title="Overview", child=self.content)

        self.split = Adw.NavigationSplitView(min_sidebar_width=230, max_sidebar_width=300,
                                             sidebar_width_fraction=0.27)
        self.split.set_sidebar(Adw.NavigationPage(title="NixOS Settings", child=side))
        self.split.set_content(self.content_page)
        narrow = Adw.Breakpoint.new(Adw.BreakpointCondition.parse("max-width: 640sp"))
        narrow.add_setter(self.split, "collapsed", True)
        mode = GObject.Value(Adw.SidebarMode, Adw.SidebarMode.PAGE)
        for sidebar in self.sidebars.values():
            narrow.add_setter(sidebar, "mode", mode)
        self.add_breakpoint(narrow)
        self.root.add_named(self.split, "main")

    def _actions(self):
        for name, accels, fn in (
                ("search", ["<Control>f"], lambda: self.search.grab_focus()),
                ("apply", ["<Control>s"], self._confirm),
                ("discard", [], self._discard),
                ("reload", ["<Control>r", "F5"], self._reload_asked),
                ("open-folder", [], self.open_folder),
                ("shortcuts", ["<Control>question"], self._shortcuts),
                ("about", [], self._about),
                ("close", ["<Control>w"], self.close)):
            action = Gio.SimpleAction.new(name, None)
            action.connect("activate", lambda *_, fn=fn: fn())
            self.add_action(action)
            if accels:
                self.get_application().set_accels_for_action(f"win.{name}", accels)

    def _reload_asked(self):
        if self.changes:
            self.toast("Apply or discard your changes first")
            return
        self.reload("Settings read again")

    def _on_close(self, _):
        if self.busy:
            self.toast("Wait for the rebuild to finish")
            return True
        return False

    @property
    def busy(self):
        return self.run_view is not None and self.run_view.running

    def toast(self, text):
        self.toasts.add_toast(Adw.Toast(title=GLib.markup_escape_text(text), timeout=4))

    def _bare(self, child, name):
        view = Adw.ToolbarView(content=child)
        view.add_top_bar(Adw.HeaderBar())
        old = self.root.get_child_by_name(name)
        if old is not None:
            self.root.remove(old)
        self.root.add_named(view, name)
        self.root.set_visible_child_name(name)

    #--------------------------------------------------------------------#
    #-- Loading
    #--------------------------------------------------------------------#
    def reload(self, toast=None):
        """Reads the settings again in the background. The page on screen stays
        until the new ones are built, so nothing stale shows in between."""
        if self.busy:
            return
        if self.state is None and self.root.get_visible_child_name() != "run":
            spinner = Adw.Spinner(width_request=48, height_request=48)
            self._bare(Adw.StatusPage(title="Reading your settings…", child=spinner), "loading")

        def work():
            state = backend.load(self.cfg)
            info = system.info(self.cfg.flake)
            return state, info, system.open_ports(state.resolved)
        ui.run_async(work, lambda result, err: self._loaded(result, err, toast))

    def _loaded(self, result, err, toast):
        if err is None and self.cfg.user not in result[0].resolved["users"]:
            err = backend.SettingsError(
                f"{self.cfg.user} isn't listed in machines/{self.cfg.machine}/settings.nix")
        if err is not None:
            self._failed(err)
            return
        self.state, self.info, self.ports = result
        self.changes = {}
        self.build()
        self.root.set_visible_child_name("main")
        #--- A finished run's page goes once the crossfade away from it is over
        run = self.root.get_child_by_name("run")
        if run is not None and self.run_view is None:
            GLib.timeout_add(self.root.get_transition_duration() + 100, self._drop_run, run)
        if toast:
            self.toast(toast)

    def _drop_run(self, run):
        if self.root.get_child_by_name("run") is run and self.root.get_visible_child() is not run:
            self.root.remove(run)
        return False

    def _failed(self, err):
        """The error page; offers to drop settings the templates no longer have."""
        direct = in_wheel() and backend.writable(self.cfg)
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
        self.state = None
        self._bare(Adw.StatusPage(icon_name="dialog-error-symbolic", title="Couldn't read the settings",
                                  description=GLib.markup_escape_text(text), child=buttons), "error")

    def _clean(self, items, direct, helper):
        if direct:
            ui.run_async(lambda: backend.remove_stale(self.cfg, items),
                         lambda _, err: self.reload(None if err else "Old settings removed"))
            return
        spinner = Adw.Spinner(width_request=48, height_request=48)
        self._bare(Adw.StatusPage(title="Removing old settings…",
                                  description="Type your own password when asked.", child=spinner), "loading")
        try:
            proc = self._root(helper).request({"clean": True})
        except OSError as e:
            self._failed(backend.SettingsError(str(e)))
            return

        def done(code, out):
            if code == 0:
                self.reload("Old settings removed")
            else:
                self._failed(backend.SettingsError("Nothing was removed.\n\n" + out.strip()))
        proc.communicate(done)

    #--------------------------------------------------------------------#
    #-- Layout
    #--------------------------------------------------------------------#
    def build(self):
        """Lays out the sidebar for the settings just read. Each page is made the
        first time it's shown (_ensure), so this stays quick enough not to stall
        an animation."""
        state = self.state
        self.colors = ui.theme_colors()
        self.rows, self.setters, self.page_of, self.builders = {}, {}, {}, {}
        self.scope_rows, self.counts = [], {}
        self.multi = len(state.user_machines) > 1
        if not self.multi:
            self.scope = ""
        elif self.scope not in state.user_machines and self.scope != "":
            self.scope = self.cfg.machine
        self.scopes = [self.cfg.machine] + [m for m in state.user_machines if m != self.cfg.machine] + [""]
        # Admins write the files themselves; for anyone else the root helper does the
        # writing too, and takes only their own app settings
        self.admin = bool(state.resolved["users"][self.cfg.user].get("admin")) and in_wheel()
        self.direct = self.admin and backend.writable(self.cfg)
        self.helper = os.path.realpath(HELPER) if os.path.exists(HELPER) else None
        self.can_apply = bool(self.helper) and (self.direct or not self.admin)
        self.wm = state.resolved.get("windowManager", "")
        self.links = [l for p in state.pages for g in p.groups for l in g.links]
        self.new_items = []
        self.settings = {(s.domain, s.path): s for p in state.pages for g in p.groups for s in g.settings}
        for domain, path, value in state.new:
            s = self.settings.get((domain, path))
            if s is not None and (domain == "user" or self.direct):
                self.new_items.append((s, value))

        self.building = True
        # The page on screen is swapped for its new copy at once, not crossfaded
        self.stack.set_transition_type(Gtk.StackTransitionType.NONE)
        child = self.stack.get_first_child()
        while child is not None:
            following = child.get_next_sibling()
            self.stack.remove(child)
            child = following
        for sidebar in self.sidebars.values():
            sidebar.remove_all()
        self.tab_keys = {tab: [] for tab, _ in TABS}
        self.tab_of = {}

        #--- Overview, Flatpaks (whose switch is a schema page's setting) and
        #--- What's New on Main, then the Niri and Docs tabs' pages
        flatpak_page = next((p for p in state.pages if p.section == "top"), None)
        makers = {"overview": lambda: Overview(self, self.info, self.wm, self.links),
                  "flatpaks": lambda: FlatpakPage(self, flatpak_page),
                  "windowrules": lambda: WindowRulesPage(self),
                  "proton": lambda: ProtonPage(self)}
        tops = {}
        for tab, _ in TABS:
            tops[tab] = Adw.SidebarSection()
            for key, title, icons in TOP[tab]:
                self._sidebar_item(tab, tops[tab], key, title, ui.first_icon(*icons))
                self.builders[key] = makers[key]
        for g in flatpak_page.groups if flatpak_page else []:
            for s in g.settings:
                self.page_of[(s.domain, s.path)] = "flatpaks"
        if self.new_items:
            badge = ui.chip(str(len(self.new_items)), "accent")
            self._sidebar_item("main", tops["main"], "new", "What's New", "starred-symbolic", suffix=badge)
            self.builders["new"] = self._new_page
        self.sidebars["main"].append(tops["main"])

        sections = {}
        for key, title in schema.SECTIONS:
            sections[key] = Adw.SidebarSection(title=title)
        for page in state.pages:
            if page.section == "top":
                continue
            section = sections.get(page.section) or sections["apps"]
            key = f"page:{page.title}"
            count = Gtk.Label(css_classes=["dim-label", "caption", "numeric"])
            self.counts[key] = (page, count)
            self._sidebar_item("main", section, key, page.title, page.icon, suffix=count)
            self.builders[key] = lambda page=page, key=key: self._page(page, key)
            for g in page.groups:
                for s in g.settings:
                    self.page_of[(s.domain, s.path)] = key
            self._count(key)
        for key, _ in schema.SECTIONS:
            if sections[key].get_items().get_n_items():
                self.sidebars["main"].append(sections[key])
        for tab, _ in TABS[1:]:
            self.sidebars[tab].append(tops[tab])

        self.banner.set_title("")
        if not self.helper:
            self.banner.set_title("The NixOS Settings helper isn't installed, so changes can't be applied")
        elif self.admin and not self.direct:
            self.banner.set_title(f"You can't edit the files in {self.cfg.flake}")
        self.banner.set_revealed(bool(self.banner.get_title()))

        key = self.page_key if self.page_key in self.builders else "overview"
        self.building = False
        self._show(key)
        self.stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE)
        self._update()

    def _sidebar_item(self, tab, section, key, title, icon, suffix=None):
        item = Adw.SidebarItem(title=title, icon_name=ui.first_icon(icon, schema.FALLBACK_ICON))
        if suffix is not None:
            item.set_suffix(suffix)
        section.append(item)
        self.tab_keys[tab].append(key)
        self.tab_of[key] = tab

    def _selected(self, sidebar, _, tab):
        if self.building or self.switching or tab != self.tab:
            return
        keys = self.tab_keys[tab]
        index = sidebar.get_selected()
        if 0 <= index < len(keys):
            if self.search.get_text():
                self.search.set_text("")
            self._show(keys[index], from_sidebar=True)

    def _tab_changed(self, *_):
        tab = self.tabs.get_active_name()
        if self.switching or tab not in self.tab_keys:
            return
        self._set_tab(tab)
        keys = self.tab_keys[tab]
        if self.search.get_text():
            self.search.set_text("")
        if keys:
            self._show(self.tab_page.get(tab) if self.tab_page.get(tab) in keys else keys[0])

    def _set_tab(self, tab):
        """Shows `tab`'s sidebar, without opening a page."""
        self.tab = tab
        self.side_stack.set_visible_child_name(tab)
        if self.tabs.get_active_name() != tab:
            self.switching = True
            self.tabs.set_active_name(tab)
            self.switching = False

    def _ensure(self, key):
        if self.stack.get_child_by_name(key) is None and key in self.builders:
            self.stack.add_named(self.builders[key](), key)

    def _show(self, key, from_sidebar=False):
        if key not in self.tab_of and key != "search":
            key = "overview"
        if key != "search":
            tab = self.tab_of[key]
            self.page_key = key
            self.tab_page[tab] = key
            self._ensure(key)
            if tab != self.tab:
                self._set_tab(tab)
            if not from_sidebar:
                self.switching = True
                self.sidebars[tab].set_selected(self.tab_keys[tab].index(key))
                self.switching = False
        self.stack.set_visible_child_name(key)
        titles = {key: title for top in TOP.values() for key, title, _ in top} | \
            {"new": "What's New", "search": "Search"}
        self.content_page.set_title(titles.get(key, key.removeprefix("page:")))

    #--------------------------------------------------------------------#
    #-- Search
    #--------------------------------------------------------------------#
    def _search(self, entry):
        words = entry.get_text().lower().split()
        old = self.stack.get_child_by_name("search")
        if old is not None:
            self.stack.remove(old)
        if not words:
            self._show(self.page_key)
            return
        settings, links, entries = [], [], []
        for page in self.state.pages:
            for g in page.groups:
                for s in g.settings:
                    text = " ".join([s.title, s.subtitle, ui.plain(s.note), ui.plain(s.description),
                                     page.title, g.title, ".".join(s.path)]).lower()
                    if all(w in text for w in words):
                        settings.append((page, s))
                for l in g.links:
                    if all(w in f"{l.title} {l.subtitle} {page.title}".lower() for w in words):
                        links.append((page, l))
        for e in self.state.dms_entries:
            if all(w in f"{e.label} {e.description} {e.keywords} {e.link.title}".lower() for w in words):
                entries.append(e)
        results = Adw.PreferencesPage()
        if settings:
            group = Adw.PreferencesGroup(title=f"Settings ({len(settings)})")
            for page, s in settings[:60]:
                key = (s.domain, s.path)
                row = Adw.ActionRow(title=ui.esc(s.title), subtitle=ui.esc(f"{page.title} · {s.subtitle}"
                                                                          if s.subtitle else page.title),
                                    activatable=True, subtitle_lines=1)
                row.add_prefix(ui.app_image(s.icon) or Gtk.Image(icon_name=ui.first_icon(page.icon)))
                value = self.changes.get(key, self._value(s))
                row.add_suffix(Gtk.Label(label=shown(s, value), css_classes=["dim-label"],
                                         ellipsize=Pango.EllipsizeMode.END, max_width_chars=22))
                row.add_suffix(Gtk.Image(icon_name="go-next-symbolic"))
                row.connect("activated", lambda _, key=key: self._jump(key))
                group.add(row)
            results.add(group)
        if links or entries:
            group = Adw.PreferencesGroup(title="DankMaterialShell",
                                         description="These open the shell's own settings window.")
            for page, l in links:
                group.add(ui.link_row(l, self.open_dms))
            for e in entries[:40]:
                owned = OWNED.get(e.label)
                sub = f"{e.link.title} · {e.description}" if e.description else e.link.title
                if owned is not None:
                    sub = ("Set here, under Appearance" if owned else "Comes from this config's theme") + \
                          "; DMS's own choice resets on rebuild"
                row = Adw.ActionRow(title=ui.esc(e.label), subtitle=ui.esc(sub), activatable=True,
                                    subtitle_lines=2)
                row.add_prefix(Gtk.Image(icon_name=ui.first_icon(e.link.icon)))
                if owned:
                    row.add_suffix(Gtk.Image(icon_name="go-next-symbolic"))
                    row.connect("activated", lambda _, p=owned: self._jump(("machine", tuple(p.split(".")))))
                else:
                    row.add_suffix(Gtk.Image(icon_name=ui.link_icon(), css_classes=["dim-label"]))
                    row.connect("activated", lambda _, l=e.link: self.open_dms(l))
                group.add(row)
            results.add(group)
        if not (settings or links or entries):
            results = Adw.StatusPage(icon_name="system-search-symbolic", title="No matches",
                                     description="Try an app's name, like Steam or Zen, or a word "
                                                 "like cursor, firewall or monitor.")
        self.stack.add_named(results, "search")
        self._show("search")

    def _jump(self, key):
        """Opens the page holding a setting and puts focus on its row."""
        if key not in self.page_of:
            return
        self.search.set_text("")
        self._show(self.page_of[key])
        if key not in self.rows:
            return
        row = self.rows[key][0]
        if isinstance(row, Adw.ExpanderRow) and row.get_enable_expansion():
            row.set_expanded(True)
        GLib.idle_add(lambda: row.grab_focus() and False)

    #--------------------------------------------------------------------#
    #-- What's New
    #--------------------------------------------------------------------#
    def _new_page(self):
        prefs = Adw.PreferencesPage()
        top = Adw.PreferencesGroup()
        add = Gtk.Button(label="Add Them With Their Defaults", halign=Gtk.Align.CENTER,
                         css_classes=["pill", "suggested-action"], margin_top=6)
        add.connect("clicked", self._adopt)
        top.add(ui.hero("starred-symbolic", "What's New",
                        "These settings were added after your settings files were made, so the "
                        "files don't mention them yet and every switch here counts as off. Add "
                        "them with the values they come with, or set them one by one on their pages.",
                        extra=add))
        prefs.add(top)
        group = Adw.PreferencesGroup()
        for s, value in self.new_items:
            key = (s.domain, s.path)
            row = Adw.ActionRow(title=ui.esc(s.title), activatable=True,
                                subtitle=ui.esc("This computer" if s.domain == "machine" else "Your settings"))
            row.add_prefix(ui.app_image(s.icon) or Gtk.Image(icon_name="starred-symbolic"))
            row.add_suffix(Gtk.Label(label=f"Default: {shown(s, value)}", css_classes=["dim-label"]))
            row.add_suffix(Gtk.Image(icon_name="go-next-symbolic"))
            row.connect("activated", lambda _, key=key: self._jump(key))
            group.add(row)
        prefs.add(group)
        return prefs

    def _adopt(self, _):
        """Stages every new setting at its template value, even where that matches
        what the missing line already means, so Apply writes it into the file."""
        for s, value in self.new_items:
            key = (s.domain, s.path)
            self.changes[key] = value
            if key in self.rows:  # a page not made yet shows the change when it is
                self.rows[key][1].set_visible(True)
            self._count(self.page_of.get(key))
        self._update()
        self.toast("Press Apply to save them")

    #--------------------------------------------------------------------#
    #-- Pages
    #--------------------------------------------------------------------#
    def _page(self, page, key):
        prefs = Adw.PreferencesPage()
        top = Adw.PreferencesGroup()
        top.add(ui.hero(ui.first_icon(page.icon, schema.FALLBACK_ICON), page.title, page.description))
        prefs.add(top)
        has_user = any(s.domain == "user" for g in page.groups for s in g.settings)
        if self.multi and has_user:
            group = Adw.PreferencesGroup()
            labels = [f"This computer ({m})" if m == self.cfg.machine else m if m else "All my computers"
                      for m in self.scopes]
            row = Adw.ComboRow(
                title="Change For",
                subtitle="Which of your computers these app settings are saved for",
                model=Gtk.StringList.new(labels),
                selected=self.scopes.index(self.scope))
            row.set_factory(self._full_label_factory())
            row.add_prefix(Gtk.Image(icon_name=ui.first_icon("computer-symbolic"), valign=Gtk.Align.CENTER))
            row.connect("notify::selected", self._scope)
            self.scope_rows.append(row)
            group.add(row)
            prefs.add(group)
        locked = [g for g in page.groups if not self.direct and any(s.domain == "machine" for s in g.settings)]
        if locked:
            title = ("Only an admin can change these" if len(locked) == len(page.groups)
                     else "Only an admin can change the computer-wide settings here")
            note = Adw.ActionRow(title=title, subtitle="They apply to everyone who uses this computer.")
            note.add_prefix(Gtk.Image(icon_name="changes-prevent-symbolic", css_classes=["accent"]))
            group = Adw.PreferencesGroup()
            group.add(note)
            prefs.add(group)
        first_links = True
        for g in page.groups:
            description = g.description
            if g.links and not g.settings and first_links:
                description = description or "These open DankMaterialShell's settings window."
                first_links = False
            group = Adw.PreferencesGroup(title=ui.esc(g.title), description=ui.esc(description))
            icons = any(s.icon for s in g.settings)
            for s in g.settings:
                widget = self._row(s, icons, page)
                widget.set_sensitive(g not in locked)
                group.add(widget)
                self.page_of[(s.domain, s.path)] = key
            for link in g.links:
                group.add(ui.link_row(link, self.open_dms))
            prefs.add(group)
            if g.title == "Open Ports":
                prefs.add(self._ports_group())
        return prefs

    def _ports_group(self):
        group = Adw.PreferencesGroup(title="Open Right Now",
                                     description="What the running system accepts from other devices. "
                                                 "Changes above show up here after Apply.")
        if not self.ports:
            group.add(Adw.ActionRow(title="No ports are open", subtitle="Other devices can't start "
                                    "connections to this computer."))
        for proto, port, who in self.ports:
            row = Adw.ActionRow(title=f"{proto.upper()} {port}", subtitle=ui.esc(who), css_classes=["property"])
            group.add(row)
        return group

    def open_dms(self, link):
        """Opens DankMaterialShell's settings window on one tab."""
        path = dms.binary()
        if path is None:
            self.toast("DankMaterialShell isn't installed here")
            return
        try:
            Gio.Subprocess.new([path, "ipc", "call", "settings", "openWith", link.tab],
                               Gio.SubprocessFlags.STDOUT_SILENCE | Gio.SubprocessFlags.STDERR_SILENCE)
        except GLib.Error as e:
            self.toast(f"Couldn't open DankMaterialShell: {e.message}")

    def open_folder(self):
        launcher = Gtk.FileLauncher.new(Gio.File.new_for_path(self.cfg.flake))
        launcher.launch(self, None, None, None)

    def _value(self, s):
        """What a row shows: user settings as they are on the computer picked in
        Change For (this one when it's All)."""
        return self.state.value(self.cfg, s, self.scope or self.cfg.machine)

    def _scope(self, row, _):
        scope = self.scopes[row.get_selected()]
        if scope == self.scope:
            return
        self.scope = scope
        for other in self.scope_rows:
            if other is not row and other.get_selected() != row.get_selected():
                other.set_selected(row.get_selected())
        # Rows show the picked computer's values; pending changes stay and are
        # measured against them
        pending = dict(self.changes)
        for key, setter in self.setters.items():
            if key[0] == "user":
                setter(pending.get(key, self._value(self.settings[key])))
        for key, value in pending.items():
            if key[0] == "user":
                self.change(self.settings[key], value)

    def _where(self):
        if not self.scope:
            return "all your computers"
        return f"this computer ({self.scope}) only" if self.scope == self.cfg.machine else f"{self.scope} only"

    #--------------------------------------------------------------------#
    #-- Rows
    #--------------------------------------------------------------------#
    def _subtitle(self, s):
        parts = []
        if s.subtitle:
            parts.append(GLib.markup_escape_text(s.subtitle))
        if s.note:
            note = ui.rich(s.note, self.colors)
            if "!!" not in s.note:
                note = f'<span foreground="{self.colors["warning"]}">{note}</span>'
            parts.append(note)
        if self.multi and self.state.overridden(s):
            parts.append(f'<span foreground="{self.colors["accent"]}">Set for this computer only</span>')
        text = "\n".join(parts)
        if not ui.valid_markup(text):
            text = GLib.markup_escape_text("\n".join(p for p in (s.subtitle, ui.plain(s.note)) if p))
        return text

    def _row(self, s, icons, page):
        key = (s.domain, s.path)
        value = self.changes.get(key, self._value(s))
        kind = s.kind
        options = []
        if kind == "pick":
            options = list(self.state.lists.get(s.data) or [])
            kind = "choice" if options else "text"
        elif kind == "choice":
            options = [(c, choice_label(s, c)) for c in s.choices]
        common = dict(title=GLib.markup_escape_text(s.title), subtitle=self._subtitle(s), use_markup=True)

        if kind == "list":
            row = self._list_row(s, list(value or []), common)
        else:
            row = Adw.ExpanderRow(**common)
        if icons:
            image = ui.app_image(s.icon) or Gtk.Image(icon_name=ui.first_icon(page.icon), pixel_size=32)
            image.set_valign(Gtk.Align.CENTER)
            row.add_prefix(image)

        marker = Gtk.Box(css_classes=["pending-dot"], valign=Gtk.Align.CENTER, visible=key in self.changes,
                         tooltip_text="Changed; Apply to use it")
        if kind == "bool":
            control = Gtk.Switch(active=bool(value), valign=Gtk.Align.CENTER)
            control.connect("notify::active", lambda w, _: self.change(s, w.get_active()))
            self.setters[key] = lambda v, w=control: w.set_active(bool(v))
        elif kind == "choice":
            if value not in [o for o, _ in options]:
                options = [(value, shown(s, value))] + options
            control = self._dropdown(options, [o for o, _ in options].index(value), search=len(options) > 12)
            control.connect("notify::selected", lambda w, _: self.change(s, options[w.get_selected()][0]))
            self.setters[key] = lambda v, w=control: w.set_selected(
                next((i for i, (o, _) in enumerate(options) if o == v), 0))
        elif kind == "text":
            placeholder = self.cfg.machine if s.path == ("hostName",) else "Not set"
            control = Gtk.Entry(text=value or "", valign=Gtk.Align.CENTER, width_chars=22,
                                placeholder_text=placeholder if s.nullable else "")
            control.connect("changed", lambda e: self.change(s, e.get_text() or (None if s.nullable else "")))
            self.setters[key] = lambda v, w=control: w.set_text(v or "")
        else:
            control = None

        if control is not None:
            # An expander packs suffixes right to left, so its control goes in first
            row.add_suffix(control)
        row.add_suffix(marker)
        if kind != "list":
            if s.description:
                row.add_row(self._description(s.description))
            else:
                row.set_enable_expansion(False)
                row.add_css_class("nixm-plain")
        self.rows[key] = (row, marker)
        return row

    def _full_label_factory(self):
        """Labels that keep their full text instead of the default ellipsized ones."""
        factory = Gtk.SignalListItemFactory()
        factory.connect("setup", lambda _, item: item.set_child(Gtk.Label(xalign=0)))
        factory.connect("bind", lambda _, item: item.get_child().set_label(item.get_item().get_string()))
        return factory

    def _dropdown(self, options, selected, search):
        """A dropdown showing each option's label; the button shows the part
        before " — " so long labels don't widen the row."""
        model = Gtk.StringList.new([label for _, label in options])
        dd = Gtk.DropDown(model=model, selected=max(0, selected), valign=Gtk.Align.CENTER)
        if search:
            dd.set_enable_search(True)
            dd.set_expression(Gtk.PropertyExpression.new(Gtk.StringObject, None, "string"))
            dd.set_search_match_mode(Gtk.StringFilterMatchMode.SUBSTRING)

        def setup(_, item, short):
            item.set_child(Gtk.Label(xalign=0, ellipsize=Pango.EllipsizeMode.END,
                                     max_width_chars=22 if short else 48))

        def bind(_, item, short):
            text = item.get_item().get_string()
            item.get_child().set_label(text.split(" — ")[0] if short else text)
        for short, setter in ((True, dd.set_factory), (False, dd.set_list_factory)):
            factory = Gtk.SignalListItemFactory()
            factory.connect("setup", setup, short)
            factory.connect("bind", bind, short)
            setter(factory)
        return dd

    def _description(self, text):
        label = Gtk.Label(wrap=True, xalign=0, margin_top=12, margin_bottom=12, margin_start=14,
                          margin_end=14, css_classes=["body"])
        markup = ui.rich(text, self.colors)
        if ui.valid_markup(markup):
            label.set_markup(markup)
        else:
            label.set_text(ui.plain(text))
        return label

    def _list_row(self, s, items, common):
        key = (s.domain, s.path)
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
                sw = Adw.SwitchRow(title=s.labels.get(str(name), str(name)), active=name in items,
                                   use_markup=False)
                sw.connect("notify::active", toggled)
                switches.append((name, sw))
                row.add_row(sw)
            self.setters[key] = lambda v: [sw.set_active(n in (v or [])) for n, sw in switches]
            return row

        children, current = [], list(items)

        def render():
            for c in children:
                row.remove(c)
            children.clear()
            for item in current:
                r = Adw.ActionRow(title=str(item), title_lines=1, use_markup=False)
                remove = Gtk.Button(icon_name="user-trash-symbolic", valign=Gtk.Align.CENTER,
                                    css_classes=["flat"], tooltip_text="Remove")
                remove.connect("clicked", lambda _, i=item: (current.remove(i), render(),
                                                             self.change(s, list(current))))
                r.add_suffix(remove)
                children.append(r)
                row.add_row(r)
            add = Adw.EntryRow(title="Add a port number" if s.ports else "Add one", show_apply_button=True,
                               input_purpose=Gtk.InputPurpose.DIGITS if s.ports else Gtk.InputPurpose.FREE_FORM)

            def added(e):
                text = e.get_text().strip()
                if not text:
                    return
                value = text
                if s.ports:
                    if not text.isdigit() or not 1 <= int(text) <= 65535:
                        e.add_css_class("error")
                        self.toast("A port is a number from 1 to 65535")
                        return
                    value = int(text)
                if value not in current:
                    current.append(value)
                    render()
                    self.change(s, list(current))
            add.connect("apply", added)
            add.connect("changed", lambda e: e.remove_css_class("error"))
            children.append(add)
            row.add_row(add)
        render()

        def reset(v):
            current[:] = list(v or [])
            render()
            self.change(s, list(current))
        self.setters[key] = reset
        return row

    #--------------------------------------------------------------------#
    #-- Changes
    #--------------------------------------------------------------------#
    def change(self, s, value):
        key = (s.domain, s.path)
        if value == self._value(s):
            self.changes.pop(key, None)
        else:
            self.changes[key] = value
        if key in self.rows:
            self.rows[key][1].set_visible(key in self.changes)
        if key in self.page_of:
            self._count(self.page_of[key])
        self._update()

    def _count(self, key):
        """Sidebar count of the switches turned on in a page, pending changes included."""
        if key not in self.counts:
            return
        page, label = self.counts[key]
        flags = [self.changes.get((s.domain, s.path), self._value(s))
                 for g in page.groups for s in g.settings if s.kind == "bool"]
        label.set_label(f"{sum(map(bool, flags))}/{len(flags)}" if flags else "")

    def _update(self):
        n = len(self.changes)
        self.pending_label.set_label(f"{n} change{'s' if n != 1 else ''} not applied yet")
        self.apply_button.set_label(f"Apply {n} Change{'s' if n != 1 else ''}" if n > 1 else "Apply")
        self.apply_button.set_sensitive(bool(n) and self.can_apply)
        self.apply_button.set_tooltip_text("Save and rebuild (Ctrl+S)" if self.can_apply
                                           else "Changes can't be applied here")
        self.content.set_reveal_bottom_bars(bool(n))

    def _discard(self):
        """Puts each changed row back in place, rather than making the pages again."""
        if not self.changes:
            return
        for key in list(self.changes):
            if key in self.setters:
                self.setters[key](self._value(self.settings[key]))
        # Rows not made yet, and What's New values staged as the row already shows them
        for key in list(self.changes):
            del self.changes[key]
            if key in self.rows:
                self.rows[key][1].set_visible(False)
        for key in self.counts:
            self._count(key)
        self._update()
        self.toast("Changes thrown away")

    def _change_lines(self):
        lines = []
        for key, value in self.changes.items():
            s = self.settings[key]
            lines.append((s, shown(s, self._value(s)), shown(s, value)))
        return lines

    def _review(self):
        dialog = Adw.Dialog(title="Changes Not Applied Yet", content_width=560, content_height=520)
        page = Adw.PreferencesPage()
        group = Adw.PreferencesGroup()
        for s, before, after in self._change_lines():
            key = (s.domain, s.path)
            sub = f"{before}  →  {after}" if before != after else "Saved into the file as it is"
            row = Adw.ActionRow(title=ui.esc(s.title), subtitle=ui.esc(sub), subtitle_lines=2)
            row.add_prefix(ui.app_image(s.icon) or Gtk.Image(icon_name="document-edit-symbolic"))
            undo = Gtk.Button(icon_name="edit-undo-symbolic", css_classes=["flat"], valign=Gtk.Align.CENTER,
                              tooltip_text="Undo this change")

            def revert(_, key=key, row=row, s=s):
                if key in self.setters:
                    self.setters[key](self._value(s))
                self.changes.pop(key, None)
                if key in self.rows:
                    self.rows[key][1].set_visible(False)
                self._update()
                group.remove(row)
                if not self.changes:
                    dialog.close()
            undo.connect("clicked", revert)
            row.add_suffix(undo)
            group.add(row)
        page.add(group)
        if self.multi and any(k[0] == "user" for k in self.changes):
            where = self._where()
            page.add(Adw.PreferencesGroup(description=f"Your app changes are saved for {where}."))
        view = Adw.ToolbarView(content=page)
        view.add_top_bar(Adw.HeaderBar())
        dialog.set_child(view)
        dialog.present(self)

    #--------------------------------------------------------------------#
    #-- Applying
    #--------------------------------------------------------------------#
    def _confirm(self):
        if not self.changes or not self.can_apply or self.busy:
            return
        restart = any((s.domain, ".".join(s.path)) in schema.RESTART for s, _, _ in self._change_lines())
        body = []
        for s, before, after in self._change_lines()[:12]:
            body.append(f"{s.title}: {before} → {after}" if before != after else f"{s.title}: saved as it is")
        if len(self.changes) > 12:
            body.append(f"…and {len(self.changes) - 12} more")
        text = "\n".join(body)
        if self.multi and any(k[0] == "user" for k in self.changes):
            where = self._where()
            text += f"\n\nApp changes are saved for {where}."
        if restart:
            text += "\n\nKernel and window manager changes take effect after a restart."
        n = len(self.changes)
        elsewhere = self._elsewhere()
        if elsewhere:
            text += f" They take effect the next time {self.scope} rebuilds."
        verb = "Save" if elsewhere else "Apply"
        dialog = Adw.AlertDialog(heading=f"{verb} {n} Change{'s' if n != 1 else ''}?", body=text)
        dialog.add_response("cancel", "Cancel")
        if not elsewhere:
            dialog.add_response("boot", "At Next Restart")
        dialog.add_response("now", "Save" if elsewhere else "Apply Now")
        best = "boot" if restart and not elsewhere else "now"
        dialog.set_response_appearance(best, Adw.ResponseAppearance.SUGGESTED)
        dialog.set_default_response(best)
        dialog.set_close_response("cancel")
        dialog.connect("response", lambda _, r: r != "cancel" and self._apply("boot" if r == "boot" else "switch"))
        dialog.present(self)

    def _pkexec(self, request):
        """What RunView.run starts: `request` on this window's root helper."""
        return lambda: self._root(self.helper).request(request)

    def _root(self, helper):
        """This window's session with `helper`, so one password covers every run."""
        if self.session is None or self.session.helper != helper:
            if self.session is not None:
                self.session.close()
            self.session = session.Session(helper)
        return self.session

    def _start(self, title, steps, message, titles=None):
        self.run_message = message
        self.search.set_text("")
        view = RunView(self, title, steps, self._run_closed, titles)
        old = self.root.get_child_by_name("run")
        if old is not None:
            self.root.remove(old)
        self.root.add_named(view, "run")
        self.root.set_visible_child_name("run")
        self.run_view = view
        self.run_undo = None
        return view

    def _elsewhere(self):
        """Whether every pending change is for another computer, so nothing here
        needs rebuilding."""
        return bool(self.scope) and self.scope != self.cfg.machine and \
            all(k[0] == "user" for k in self.changes)

    def _apply(self, mode):
        changes, scope = dict(self.changes), self.scope or None
        elsewhere = self._elsewhere()
        if self.direct and elsewhere:
            def saved(_, err):
                if err is not None:
                    self.toast(f"Nothing was saved: {err}")
                    return
                self.reload(f"Saved for {scope}; it takes effect when {scope} rebuilds")
            ui.run_async(lambda: backend.write(self.cfg, self.state, changes, scope), saved)
            return
        if self.direct:
            view = self._start("Applying Changes", ["write", "auth", "build", "compare", "switch", "boot"],
                               "Changes applied")
            view.step("write", "running")

            def written(old, err):
                if err is not None:
                    view.fail_step("write", "These settings don't work",
                                   f"Nothing was saved.\n\n{err}")
                    return
                view.step("write", "done")
                self.run_undo = lambda: (backend.restore(self.cfg, old), "Your settings are back how they were")[1]
                view.set_undo("Undo My Changes", self.run_undo)
                view.run(self._pkexec({"rebuild": True, "mode": mode}))
            ui.run_async(lambda: backend.write(self.cfg, self.state, changes, scope,
                                               self.state.user_machines), written)
            return
        steps = ["auth", "save"] if elsewhere else ["auth", "save", "build", "compare", "switch", "boot"]
        view = self._start("Saving Changes" if elsewhere else "Applying Changes", steps,
                           f"Saved for {scope}" if elsewhere else "Changes applied")
        request = {"mode": mode, "machine": scope,
                   "changes": [[list(path), value] for (_, path), value in changes.items()]}
        view.run(self._pkexec(request))

    def confirm_rebuild(self):
        if self.busy or not self.can_apply or not self.admin:
            return
        if self.changes:
            self.toast("Apply or discard your changes first")
            return
        dialog = Adw.AlertDialog(heading="Rebuild now?",
                                 body="This builds the system from the settings files as they are "
                                      "and switches to it.")
        dialog.add_response("cancel", "Cancel")
        dialog.add_response("boot", "At Next Restart")
        dialog.add_response("now", "Rebuild Now")
        dialog.set_response_appearance("now", Adw.ResponseAppearance.SUGGESTED)
        dialog.set_close_response("cancel")

        def chosen(_, r):
            if r == "cancel":
                return
            view = self._start("Rebuilding", ["auth", "build", "compare", "switch", "boot"], "Rebuilt")
            view.run(self._pkexec({"rebuild": True, "mode": "boot" if r == "boot" else "switch"}))
        dialog.connect("response", chosen)
        dialog.present(self)

    def confirm_collect(self):
        """Explains exactly what the clean-up deletes before running it."""
        if self.busy or not self.can_apply or not self.admin:
            return
        if self.changes:
            self.toast("Apply or discard your changes first")
            return
        policy = system.clean_policy()
        gens = self.info.generations
        doomed = sorted(system.to_delete(gens, policy), key=lambda g: g.number)
        kept = f"the newest {policy.keep}" + (f" and any made in the last {policy.since_text}"
                                               if policy.since else "")
        if doomed:
            first = (f"This deletes {len(doomed)} of the {len(gens)} system versions, the oldest ones "
                     f"(versions {doomed[0].number} to {doomed[-1].number}), keeping {kept}. ")
        else:
            first = f"No system version is old enough to delete yet; the clean-up keeps {kept}. "
        body = (first + "Older versions of each person's apps and settings follow the same rule.\n\n"
                "Then every file in the Nix store that no remaining version uses is deleted, which "
                "is what frees the space, and the boot menu is rewritten to list only what's left. "
                "You can't switch back to a deleted version.")
        if policy.schedule:
            body += f"\n\nThe same clean-up also runs on its own ({policy.schedule})."
        dialog = Adw.AlertDialog(heading="Clean up old versions?", body=body)
        dialog.add_response("cancel", "Cancel")
        dialog.add_response("clean", "Clean Up")
        dialog.set_response_appearance("clean", Adw.ResponseAppearance.DESTRUCTIVE)
        dialog.set_close_response("cancel")

        def chosen(_, r):
            if r != "clean":
                return
            view = self._start("Cleaning Up", ["auth", "collect", "boot"], "Cleaned up",
                               titles={"boot": "Update the boot menu"})
            view.run(self._pkexec({"collectGarbage": True}))
        dialog.connect("response", chosen)
        dialog.present(self)

    def check_updates(self, done):
        ui.run_async(lambda: system.check_updates(self.cfg.flake), done)

    def confirm_update(self, new_lock, changes):
        if self.busy or not self.can_apply or not self.admin:
            return
        if self.changes:
            self.toast("Apply or discard your changes first")
            return
        dialog = Adw.AlertDialog(
            heading="Update this computer?",
            body=f"{len(changes)} sources move to their newest versions. The new system is "
                 "downloaded and built, then switched to. If it changes systemd, glibc, niri or "
                 "xwayland-satellite, it starts at the next restart instead, since switching to "
                 "those live has frozen the desktop before.")
        dialog.add_response("cancel", "Cancel")
        dialog.add_response("boot", "At Next Restart")
        dialog.add_response("auto", "Update Now")
        dialog.set_response_appearance("auto", Adw.ResponseAppearance.SUGGESTED)
        dialog.set_default_response("auto")
        dialog.set_close_response("cancel")
        dialog.connect("response", lambda _, r: r != "cancel" and self._run_update(new_lock, r))
        dialog.present(self)

    def _run_update(self, new_lock, mode):
        view = self._start("Updating", ["update", "auth", "build", "compare", "switch", "boot"],
                           "System updated")
        view.step("update", "running", "Writing the new versions into flake.lock")

        def written(old, err):
            if err is not None:
                view.fail_step("update", "Couldn't update flake.lock", str(err))
                return
            view.step("update", "done", "flake.lock now names the new versions")
            self.run_undo = lambda: (system.restore_lock(self.cfg.flake, old),
                                     "flake.lock is back how it was")[1]
            view.set_undo("Undo the Update", self.run_undo)
            view.run(self._pkexec({"rebuild": True, "mode": mode}))
        ui.run_async(lambda: system.apply_lock(self.cfg.flake, new_lock), written)

    def confirm_rollback(self, generation):
        if self.busy or not self.can_apply or not self.admin:
            return
        dialog = Adw.AlertDialog(
            heading=f"Switch to version {generation.number}?",
            body=f"Version {generation.number} was made {ui.when(generation.when).lower()}. "
                 "Your settings files stay as they are, so the next rebuild or update goes "
                 "back to them.")
        dialog.add_response("cancel", "Cancel")
        dialog.add_response("boot", "At Next Restart")
        dialog.add_response("auto", "Switch Now")
        dialog.set_response_appearance("auto", Adw.ResponseAppearance.SUGGESTED)
        dialog.set_close_response("cancel")

        def chosen(_, r):
            if r == "cancel":
                return
            view = self._start(f"Switching to Version {generation.number}", ["auth", "compare", "switch", "boot"],
                               f"Switched to version {generation.number}")
            view.run(self._pkexec({"activate": generation.path, "mode": r}))
        dialog.connect("response", chosen)
        dialog.present(self)

    def compare_version(self, generation):
        dialog = Adw.Dialog(title=f"Version {generation.number} and Now", content_width=560, content_height=600)
        page = Adw.PreferencesPage()
        group = Adw.PreferencesGroup(description=f"What switching from the running version to version "
                                                 f"{generation.number} would change.")
        spinner = Adw.Spinner(width_request=32, height_request=32, margin_top=24, margin_bottom=24)
        group.add(spinner)
        page.add(group)
        view = Adw.ToolbarView(content=page)
        view.add_top_bar(Adw.HeaderBar())
        dialog.set_child(view)
        dialog.present(self)

        def done(diff, err):
            group.remove(spinner)
            if err is not None:
                group.add(Adw.ActionRow(title="Couldn't compare", subtitle=ui.esc(str(err))))
                return
            fill_diff(group, diff)
        ui.run_async(lambda: closure.diff(closure.CURRENT, generation.path), done)

    def _run_closed(self, outcome):
        """The run page stays while the settings are read again, then crossfades
        straight to the pages made from them."""
        view = self.run_view
        boot = view is not None and view.mode == "boot"
        self.run_view = None
        message = None
        if outcome == "ok":
            message = "Ready; restart to use it" if boot else (self.run_message or "Done")
        elif outcome == "failed" and self.run_undo is not None:
            message = "Your changes are still in the files, but the system wasn't rebuilt with them"
        self.run_undo = None
        if view is not None:
            view.closing()
        self.reload(message)

    def notify_done(self, outcome, heading):
        """Called when a run ends: puts back what the app wrote if nothing was
        built, and tells the desktop when the window isn't in front."""
        if outcome in ("auth", "cancelled") and self.run_undo is not None:
            message = self.run_undo()
            self.run_undo = None
            if self.run_view is not None:
                self.run_view.set_undo("", None)
                self.run_view.undo_button.set_visible(False)
            self.toast(message)
        if outcome == "ok":
            self.run_undo = None
            GLib.timeout_add(700, self._offer_restart)
        if not self.is_active():
            note = Gio.Notification.new("NixOS Settings")
            note.set_body(heading)
            self.get_application().send_notification("run", note)

    def _offer_restart(self):
        """After a switch that changed this app, offers to start the new build."""
        package = installed_package()
        if package is None or package == RUNNING:
            return False
        dialog = Adw.AlertDialog(
            heading="Restart NixOS Settings?",
            body="This rebuild changed NixOS Settings itself. Restart it to use the version "
                 "just installed; until then this window keeps running the old one.")
        dialog.add_response("later", "Later")
        dialog.add_response("restart", "Restart")
        dialog.set_response_appearance("restart", Adw.ResponseAppearance.SUGGESTED)
        dialog.set_default_response("restart")
        dialog.set_close_response("later")

        def chosen(_, response):
            if response == "restart" and not self.busy:
                app = self.get_application()
                app.restart_into = os.path.join(package, "bin", "nixos-settings")
                app.quit()
        dialog.connect("response", chosen)
        dialog.present(self)
        return False

    def restart(self):
        dialog = Adw.AlertDialog(heading="Restart now?", body="Save your work in other apps first.")
        dialog.add_response("cancel", "Cancel")
        dialog.add_response("restart", "Restart")
        dialog.set_response_appearance("restart", Adw.ResponseAppearance.SUGGESTED)
        dialog.set_close_response("cancel")

        def chosen(_, response):
            if response == "restart":
                try:
                    Gio.Subprocess.new(["systemctl", "reboot"], Gio.SubprocessFlags.NONE)
                except GLib.Error as e:
                    self.toast(f"Couldn't restart: {e.message}")
        dialog.connect("response", chosen)
        dialog.present(self)

    #--------------------------------------------------------------------#
    #-- Dialogs
    #--------------------------------------------------------------------#
    def _shortcuts(self):
        dialog = Adw.ShortcutsDialog()
        section = Adw.ShortcutsSection(title="General")
        for title, accel in (("Search", "<Control>f"), ("Apply changes", "<Control>s"),
                             ("Reload the settings", "<Control>r"),
                             ("Keyboard shortcuts", "<Control>question"), ("Close the window", "<Control>w")):
            section.add(Adw.ShortcutsItem(title=title, accelerator=accel))
        dialog.add(section)
        dialog.present(self)

    def _about(self):
        dialog = Adw.AboutDialog(application_name="NixOS Settings", version=VERSION,
                                 application_icon=ui.first_icon("nix-snowflake", "distributor-logo-nixos"),
                                 comments="Pick apps and system options for this NixOS config, then "
                                          "rebuild, update or switch back to an earlier version.")
        dialog.present(self)


class App(Adw.Application):
    def __init__(self):
        super().__init__(application_id=APP_ID, flags=Gio.ApplicationFlags.DEFAULT_FLAGS)
        self.restart_into = None  # set to the new build's launcher to restart into it

    def do_startup(self):
        Adw.Application.do_startup(self)
        ui.load_css()
        quit_action = Gio.SimpleAction.new("quit", None)
        quit_action.connect("activate", lambda *_: self._quit())
        self.add_action(quit_action)
        self.set_accels_for_action("app.quit", ["<Control>q"])

    def _quit(self):
        window = self.props.active_window
        if window is not None and getattr(window, "busy", False):
            window.toast("Wait for the rebuild to finish")
            return
        self.quit()

    def do_activate(self):
        window = self.props.active_window
        if window is None:
            Window(self, backend.Config.from_env()).present()
            return
        # Started again while open: the existing window comes forward instead
        window.present()
        focus_own_window()


def focus_own_window():
    """Asks the compositor to focus this process's window. Wayland ignores
    present() without an activation token, which a second launch rarely has."""
    pid = os.getpid()
    try:
        if os.environ.get("NIRI_SOCKET") and GLib.find_program_in_path("niri"):
            out = subprocess.run(["niri", "msg", "--json", "windows"], capture_output=True,
                                 text=True, timeout=3)
            ids = [w["id"] for w in json.loads(out.stdout or "[]") if w.get("pid") == pid]
            if ids:
                subprocess.run(["niri", "msg", "action", "focus-window", "--id", str(ids[0])],
                               capture_output=True, timeout=3)
        elif os.environ.get("HYPRLAND_INSTANCE_SIGNATURE") and GLib.find_program_in_path("hyprctl"):
            subprocess.run(["hyprctl", "dispatch", "focuswindow", f"pid:{pid}"],
                           capture_output=True, timeout=3)
    except (OSError, ValueError, KeyError, subprocess.TimeoutExpired):
        pass


if __name__ == "__main__":
    app = App()
    status = app.run(sys.argv)
    if app.restart_into:
        # run() has given up the app's D-Bus name, so the new build can take it
        os.execv(app.restart_into, [app.restart_into])
    sys.exit(status)
