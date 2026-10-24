"""The Packages page: searches nixpkgs without the website, through
nix-search-tv. It keeps its own index of search.nixos.org's unstable channel
in ~/.cache/nix-search-tv, made again once a week, so the list can be a few
days off this system's flake.lock. `print` lists every name and `preview`
gives one package's details; the page matches on names and reads the details
of the results it shows."""

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gdk, GLib, Gtk  # noqa: E402

import ui  # noqa: E402
from packagestate import STARTER, SHOWN, TOOL, category_of, flat, names, preview, search  # noqa: E402


def titled(attr, version):
    """A row title: the name, then its version in smaller, dimmer text."""
    if not version:
        return ui.esc(attr)
    return f'{ui.esc(attr)}  <span size="small" alpha="60%" weight="normal">{ui.esc(version)}</span>'


def pick_category(window, attr, on_pick, current=None):
    """Asks which category `attr` goes under: one in use, a starter one or a
    new name, then calls on_pick(name)."""
    groups = window.user_packages()
    used = sorted((cat for cat, names in groups.items() if names), key=str.lower)
    taken = {cat.lower() for cat in used}
    dialog = Adw.Dialog(title="Move To" if current else "Install Under", content_width=380, content_height=560)

    def choose(name):
        name = name.strip()[:40]
        if not name or name == current:
            return
        dialog.close()
        on_pick(next((cat for cat in used if cat.lower() == name.lower()), name))

    page = Adw.PreferencesPage()
    group = Adw.PreferencesGroup(description=f"The User Packages category {attr} is listed under.")
    for name in used + [cat for cat in STARTER if cat.lower() not in taken]:
        row = Adw.ActionRow(title=ui.esc(name), activatable=name != current)
        row.add_prefix(Gtk.Image(icon_name=ui.first_icon("folder-symbolic")))
        if name == current:
            row.add_suffix(ui.chip("Now", "accent"))
        elif groups.get(name):
            row.add_suffix(Gtk.Label(label=str(len(groups[name])), css_classes=["dim-label", "numeric"]))
        row.connect("activated", lambda _, n=name: choose(n))
        group.add(row)
    entry = Adw.EntryRow(title="New category", show_apply_button=True)
    entry.connect("apply", lambda e: choose(e.get_text()))
    group.add(entry)
    page.add(group)
    view = Adw.ToolbarView(content=page)
    view.add_top_bar(Adw.HeaderBar())
    dialog.set_child(view)
    dialog.present(window)


def state(window, attr):
    """Where `attr` stands: installed, adding (on Apply), removing, or None."""
    now, saved = attr in flat(window.user_packages()), attr in flat(window.user_packages(saved=True))
    if now:
        return "installed" if saved else "adding"
    return "removing" if saved else None


class PackagesPage(Adw.PreferencesPage):
    def __init__(self, window):
        super().__init__()
        self.window = window
        self.index = None
        self.rows = []
        self.buttons = {}  # attr -> its row's install button, for the rows shown
        window.package_listeners.append(lambda _: self._mark())
        self.timer = 0
        self.asked = 0  # bumps per search, so details for an older one are dropped

        top = Adw.PreferencesGroup()
        top.add(ui.hero(ui.first_icon("system-search-symbolic", "edit-find-symbolic"), "Search",
                        "Search nixpkgs by package name and install what you need; it's added to "
                        "User Packages and installed when you apply. Expand a result for its "
                        "homepage, licence and the program it runs."))
        self.entry = Gtk.SearchEntry(placeholder_text="Search packages", hexpand=True, sensitive=False,
                                     margin_top=6)
        self.entry.connect("search-changed", self._changed)
        self.entry.connect("activate", lambda _: self._search())
        top.add(self.entry)
        self.add(top)

        self.status_group = Adw.PreferencesGroup()
        self.status = Adw.ActionRow(title="Reading the package list…", subtitle_lines=2,
                                    subtitle="The first time, and once a week after, the list is "
                                             "downloaded again; that takes a minute or so.")
        self.spinner = Adw.Spinner(valign=Gtk.Align.CENTER)
        self.status.add_prefix(self.spinner)
        self.status_group.add(self.status)
        self.add(self.status_group)

        self.results = Adw.PreferencesGroup(visible=False)
        self.count = Gtk.Label(css_classes=["dim-label", "caption", "numeric"], valign=Gtk.Align.CENTER)
        self.results.set_header_suffix(self.count)
        self.add(self.results)
        if GLib.find_program_in_path(TOOL):
            ui.run_async(names, self._loaded)
        else:
            self._loaded(None, f"{TOOL} isn't installed")

    def _loaded(self, index, error):
        self.spinner.set_visible(False)
        if error is not None:
            detail = (getattr(error, "stderr", "") or str(error)).strip()
            self.status.set_title("Couldn't read the package list")
            self.status.set_subtitle(ui.esc(detail.splitlines()[-1] if detail else str(error)))
            return
        self.index = index
        self.status_group.set_visible(False)
        self.entry.set_sensitive(True)
        self.entry.set_placeholder_text(f"Search {len(index):,} packages")
        self.entry.grab_focus()

    #--------------------------------------------------------------------#
    #-- Searching
    #--------------------------------------------------------------------#
    def _changed(self, _):
        if self.timer:
            GLib.source_remove(self.timer)
        self.timer = GLib.timeout_add(150, self._search)

    def _search(self):
        if self.timer:
            GLib.source_remove(self.timer)
        self.timer = 0
        if self.index is None:
            return False
        for row in self.rows:
            self.results.remove(row)
        self.rows = []
        self.buttons = {}
        self.asked += 1
        query = self.entry.get_text().strip()
        found = search(self.index, query)
        self.results.set_visible(bool(query))
        self.results.set_title("Results" if found else f"Nothing is named like “{query}”")
        self.count.set_label(f"first {SHOWN} of {len(found):,}" if len(found) > SHOWN
                             else f"{len(found):,}" if found else "")
        shown = []
        for attr in found[:SHOWN]:
            row, fill = self._row(attr)
            self.results.add(row)
            self.rows.append(row)
            shown.append((attr, fill))
        asked = self.asked

        def work():
            # Each row fills in as its details arrive; a newer search stops the rest
            for attr, fill in shown:
                if asked != self.asked:
                    return
                info = preview(attr)
                GLib.idle_add(lambda f=fill, i=info: asked == self.asked and f(i) and False)
        if shown:
            ui.run_async(work, lambda *_: None)
        return False

    #--------------------------------------------------------------------#
    #-- Results
    #--------------------------------------------------------------------#
    def _row(self, attr):
        """A result row, and the function that fills it in once its details are read."""
        row = Adw.ExpanderRow(title=ui.esc(attr), subtitle="…", subtitle_lines=2)
        # An expander packs suffixes right to left: install, then copy
        install = Gtk.Button(valign=Gtk.Align.CENTER)
        install.connect("clicked", lambda _: self._install(attr))
        row.add_suffix(install)
        self.buttons[attr] = install
        copy = Gtk.Button(icon_name="edit-copy-symbolic", css_classes=["flat"], valign=Gtk.Align.CENTER,
                          tooltip_text="Copy the attribute name")
        copy.connect("clicked", lambda _: self._copy(attr))
        row.add_suffix(copy)
        self._mark_one(attr, install)

        def fill(info):
            row.set_subtitle(ui.esc(info["description"] or "No description"))
            row.set_title(titled(attr, info["version"]))
            if info["broken"]:
                row.add_suffix(ui.chip("Broken", "error", "nixpkgs marks it broken, so it may not build"))
            for home in info["homepage"]:
                link = Adw.ActionRow(title="Homepage", subtitle=ui.esc(home), activatable=True)
                link.add_suffix(Gtk.Image(icon_name=ui.link_icon(), valign=Gtk.Align.CENTER))
                link.connect("activated", lambda _, h=home: ui.open_uri(self.window, h))
                row.add_row(link)
            licenses = ", ".join(info["licenses"]) or "Not stated"
            row.add_row(Adw.ActionRow(title="Licence", subtitle=ui.esc(licenses + (" (unfree)" if info["unfree"]
                                                                                   else ""))))
            if info["program"]:
                row.add_row(Adw.ActionRow(title="Runs", subtitle=ui.esc(info["program"])))
            if info["about"]:
                row.add_row(Adw.ActionRow(title="About", subtitle=ui.esc(info["about"]), subtitle_lines=0))
        return row, fill

    def _install(self, attr):
        if attr in flat(self.window.user_packages()):
            return

        def add(cat):
            groups = self.window.user_packages()
            groups.setdefault(cat, []).append(attr)
            self.window.set_user_packages(groups)
            self.window.toast(f"{attr} will be installed under {cat} when you apply")
        pick_category(self.window, attr, add)

    def _mark(self):
        for attr, button in self.buttons.items():
            self._mark_one(attr, button)

    def _mark_one(self, attr, button):
        where = state(self.window, attr)
        label = {"installed": "Installed", "adding": "Added"}.get(where, "Install")
        button.set_label(label)
        button.set_sensitive(where not in ("installed", "adding"))
        button.set_css_classes(["suggested-action"] if label == "Install" else ["flat"])
        button.set_tooltip_text({"adding": "Installed when you apply"}.get(where, "Add to User Packages"
                                                                          if label == "Install" else None))

    def _copy(self, text):
        Gdk.Display.get_default().get_clipboard().set(text)
        self.window.toast(f"Copied {text}")


class UserPackagesPage(Adw.PreferencesPage):
    """The userPackages categories (all of them, or `category` alone): what
    Search installed, each with Move and Uninstall buttons, plus pending
    removals that can still be undone."""

    def __init__(self, window, category=None):
        super().__init__()
        self.window = window
        self.category = category
        self.groups = []
        self.details = {}  # attr -> (description, version), read once per page
        top = Adw.PreferencesGroup()
        if category:
            top.add(ui.hero(ui.first_icon("folder-symbolic"), category,
                            f"User packages sorted under {category}. Move one to list it under "
                            f"another category."))
        else:
            top.add(ui.hero(ui.first_icon("package-x-generic-symbolic"), "User Packages",
                            "Packages you added from Search, installed as they come with no settings "
                            "of their own, sorted into categories you pick. Apps with settings made "
                            "for them are under Default Packages."))
        self.add(top)
        window.package_listeners.append(lambda _: self._render())
        self._render()

    def _render(self):
        for group in self.groups:
            self.remove(group)
        self.groups = []
        now, saved = self.window.user_packages(), self.window.user_packages(saved=True)
        current = flat(now)
        cats = [self.category] if self.category else \
            sorted({c for c, n in now.items() if n} | {c for c, n in saved.items() if n}, key=str.lower)
        shown = []
        for cat in cats:
            # Pending removals stay listed, under the category they were saved in
            names = now.get(cat, []) + [n for n in saved.get(cat, []) if n not in current]
            if not names:
                continue
            group = self._group(cat if not self.category else "Installed")
            for attr in sorted(names, key=str.lower):
                group.add(self._row(cat, attr, saved))
            shown += names
        if not shown:
            group = self._group("Installed")
            empty = Adw.ActionRow(title="No user packages yet", activatable=True,
                                  subtitle="Find one on the Search page and press Install.")
            empty.add_suffix(Gtk.Image(icon_name="go-next-symbolic", valign=Gtk.Align.CENTER))
            empty.connect("activated", lambda _: self.window._show("packages"))
            group.add(empty)
            return
        self.groups[0].set_description(f"Saved for {self.window._where()}.")
        missing = [a for a in shown if a not in self.details]
        if missing and GLib.find_program_in_path(TOOL):
            ui.run_async(lambda: {a: preview(a) for a in missing}, self._described)

    def _group(self, title):
        group = Adw.PreferencesGroup(title=ui.esc(title))
        self.add(group)
        self.groups.append(group)
        return group

    def _row(self, cat, attr, saved):
        where = state(self.window, attr)
        description, version = self.details.get(attr, ("", ""))
        row = Adw.ActionRow(title=titled(attr, version), subtitle_lines=2, subtitle=ui.esc(description))
        was = category_of(saved, attr)
        if where == "adding":
            row.add_suffix(ui.chip("Installs on Apply", "accent"))
        elif where == "removing":
            row.add_suffix(ui.chip("Removed on Apply", "warning"))
        elif was != cat:
            row.add_suffix(ui.chip("Moves here on Apply", "accent", tooltip=f"Saved under {was}"))
        if where == "removing":
            button = Gtk.Button(label="Undo", valign=Gtk.Align.CENTER)
            button.connect("clicked", lambda _: self._undo(cat, attr))
            row.add_suffix(button)
            return row
        move = Gtk.Button(icon_name=ui.first_icon("folder-move-symbolic", "folder-symbolic"), css_classes=["flat"],
                          valign=Gtk.Align.CENTER, tooltip_text="Move to another category")
        move.connect("clicked", lambda _: self._move(cat, attr))
        button = Gtk.Button(label="Uninstall", valign=Gtk.Align.CENTER, css_classes=["destructive-action"])
        button.connect("clicked", lambda _: self._uninstall(attr))
        row.add_suffix(move)
        row.add_suffix(button)
        return row

    def _move(self, cat, attr):
        def to(new):
            groups = self.window.user_packages()
            groups[cat] = [n for n in groups.get(cat, []) if n != attr]
            groups.setdefault(new, []).append(attr)
            self.window.set_user_packages(groups)
            self.window.toast(f"{attr} moves to {new} when you apply")
        pick_category(self.window, attr, to, current=cat)

    def _described(self, found, error):
        if error is not None:
            return
        self.details.update({a: (i["description"] or "No description", i["version"]) for a, i in found.items()})
        self._render()

    def _uninstall(self, attr):
        groups = self.window.user_packages()
        self.window.set_user_packages({cat: [n for n in names if n != attr] for cat, names in groups.items()})
        if state(self.window, attr) == "removing":
            self.window.toast(f"{attr} will be removed when you apply")

    def _undo(self, cat, attr):
        groups = self.window.user_packages()
        groups.setdefault(cat, []).append(attr)
        self.window.set_user_packages(groups)
