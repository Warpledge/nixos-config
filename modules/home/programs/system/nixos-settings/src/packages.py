"""The Packages page: searches nixpkgs without the website, through
nix-search-tv. It keeps its own index of search.nixos.org's unstable channel
in ~/.cache/nix-search-tv, made again once a week, so the list can be a few
days off this system's flake.lock. `print` lists every name and `preview`
gives one package's details; the page matches on names and reads the details
of the results it shows."""

import re
import subprocess

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gdk, GLib, Gtk, Pango  # noqa: E402

import ui  # noqa: E402

TOOL = "nix-search-tv"
PREFIX = "nixpkgs/ "  # print also lists Home Manager, NixOS and NUR entries
SHOWN = 50  # results listed at once
ANSI = re.compile(r"\x1b\[[0-9;]*m")
TITLE = re.compile(r"^(\S+) \((.*)\)$")


def names():
    """Every nixpkgs attribute name in nix-search-tv's index."""
    out = subprocess.run([TOOL, "print"], capture_output=True, text=True, timeout=600, check=True)
    return sorted(line[len(PREFIX):] for line in out.stdout.splitlines() if line.startswith(PREFIX))


def preview(attr):
    """A package's details from `nix-search-tv preview`: version, description,
    about, homepage, licence, unfree and the program it runs."""
    out = subprocess.run([TOOL, "preview", PREFIX + attr], capture_output=True, text=True, timeout=30)
    blocks = [b.splitlines() for b in ANSI.sub("", out.stdout).strip().split("\n\n") if b.strip()]
    info = {"version": "", "description": "", "about": "", "homepage": [], "licenses": [],
            "unfree": False, "program": ""}
    if not blocks:
        return info
    head = blocks[0]
    m = TITLE.match(head[0].strip())
    if m:
        info["version"] = m.group(2)
    info["description"] = " ".join(l.strip() for l in head[1:])
    for block in blocks[1:]:
        title, values = block[0].strip(), [l.strip() for l in block[1:] if l.strip()]
        if title == "homepage":
            info["homepage"] = values
        elif title.startswith("license"):
            info["licenses"] = values
            info["unfree"] = "unfree" in title
        elif title == "main program":
            info["program"] = next((v.strip("│ ").removeprefix("$ ") for v in values if "$" in v), "")
        elif title in ("platforms", "outputs"):
            continue
        elif not info["about"]:
            info["about"] = " ".join(l.strip() for l in block)
    return info


def search(index, query):
    """Names holding every word of `query`, best first: the name itself, then
    its start (or its last part's, for `python313Packages.x`), then anywhere."""
    q = query.strip().lower()
    words = q.split()
    if not words:
        return []
    hits = []
    for name in index:
        low = name.lower()
        if not all(w in low for w in words):
            continue
        last = low.rsplit(".", 1)[-1]
        rank = 0 if low == q else 1 if low.startswith(q) or last.startswith(q) else 2
        hits.append((rank, low.count("."), len(low), name))
    hits.sort()
    return [h[3] for h in hits]


def state(window, attr):
    """Where `attr` stands: installed, adding (on Apply), removing, or None."""
    now, saved = attr in window.user_packages(), attr in window.user_packages(saved=True)
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
        # An expander packs suffixes right to left: install, then version, then copy
        install = Gtk.Button(valign=Gtk.Align.CENTER)
        install.connect("clicked", lambda _: self._install(attr))
        row.add_suffix(install)
        self.buttons[attr] = install
        version = Gtk.Label(css_classes=["dim-label", "numeric"], valign=Gtk.Align.CENTER, max_width_chars=16,
                            ellipsize=Pango.EllipsizeMode.END)
        row.add_suffix(version)
        copy = Gtk.Button(icon_name="edit-copy-symbolic", css_classes=["flat"], valign=Gtk.Align.CENTER,
                          tooltip_text="Copy the attribute name")
        copy.connect("clicked", lambda _: self._copy(attr))
        row.add_suffix(copy)
        self._mark_one(attr, install)

        def fill(info):
            row.set_subtitle(ui.esc(info["description"] or "No description"))
            version.set_label(info["version"])
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
        names = self.window.user_packages()
        if attr not in names:
            self.window.set_user_packages(names + [attr])
            self.window.toast(f"{attr} will be installed when you apply")

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
    """The userPackages list: what Search installed, each with an Uninstall
    button, plus pending removals that can still be undone."""

    def __init__(self, window):
        super().__init__()
        self.window = window
        self.rows = []
        self.details = {}  # attr -> (description, version), read once per page
        top = Adw.PreferencesGroup()
        top.add(ui.hero(ui.first_icon("package-x-generic-symbolic"), "User Packages",
                        "Packages you added from Search, installed as they come with no settings "
                        "of their own. Apps with settings made for them are under Default Packages."))
        self.add(top)
        self.group = Adw.PreferencesGroup(title="Installed")
        self.add(self.group)
        window.package_listeners.append(lambda _: self._render())
        self._render()

    def _render(self):
        for row in self.rows:
            self.group.remove(row)
        self.rows = []
        now, saved = self.window.user_packages(), self.window.user_packages(saved=True)
        names = now + [n for n in saved if n not in now]
        self.group.set_description(f"Saved for {self.window._where()}." if names else None)
        if not names:
            empty = Adw.ActionRow(title="No user packages yet", activatable=True,
                                  subtitle="Find one on the Search page and press Install.")
            empty.add_suffix(Gtk.Image(icon_name="go-next-symbolic", valign=Gtk.Align.CENTER))
            empty.connect("activated", lambda _: self.window._show("packages"))
            self._add(empty)
            return
        for attr in names:
            where = state(self.window, attr)
            description, version = self.details.get(attr, ("", ""))
            row = Adw.ActionRow(title=ui.esc(attr), subtitle_lines=2, subtitle=ui.esc(description))
            if where == "adding":
                row.add_suffix(ui.chip("Installs on Apply", "accent"))
            elif where == "removing":
                row.add_suffix(ui.chip("Removed on Apply", "warning"))
            if version:
                row.add_suffix(Gtk.Label(label=version, css_classes=["dim-label", "numeric"],
                                         valign=Gtk.Align.CENTER, max_width_chars=16,
                                         ellipsize=Pango.EllipsizeMode.END))
            if where == "removing":
                button = Gtk.Button(label="Undo", valign=Gtk.Align.CENTER)
                button.connect("clicked", lambda _, a=attr: self._undo(a))
            else:
                button = Gtk.Button(label="Uninstall", valign=Gtk.Align.CENTER,
                                    css_classes=["destructive-action"])
                button.connect("clicked", lambda _, a=attr: self._uninstall(a))
            row.add_suffix(button)
            self._add(row)
        missing = [a for a in names if a not in self.details]
        if missing and GLib.find_program_in_path(TOOL):
            ui.run_async(lambda: {a: preview(a) for a in missing}, self._described)

    def _add(self, row):
        self.group.add(row)
        self.rows.append(row)

    def _described(self, found, error):
        if error is not None:
            return
        self.details.update({a: (i["description"] or "No description", i["version"]) for a, i in found.items()})
        self._render()

    def _uninstall(self, attr):
        self.window.set_user_packages([n for n in self.window.user_packages() if n != attr])
        if state(self.window, attr) == "removing":
            self.window.toast(f"{attr} will be removed when you apply")

    def _undo(self, attr):
        saved = self.window.user_packages(saved=True)
        names = self.window.user_packages() + [attr]
        self.window.set_user_packages([n for n in saved if n in names] + [n for n in names if n not in saved])
