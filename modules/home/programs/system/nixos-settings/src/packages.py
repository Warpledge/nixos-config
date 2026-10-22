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


class PackagesPage(Adw.PreferencesPage):
    def __init__(self, window):
        super().__init__()
        self.window = window
        self.index = None
        self.rows = []
        self.timer = 0
        self.asked = 0  # bumps per search, so details for an older one are dropped

        top = Adw.PreferencesGroup()
        top.add(ui.hero(ui.first_icon("system-search-symbolic", "edit-find-symbolic"), "Packages",
                        "Search nixpkgs by package name. Expand a result for its homepage, licence "
                        "and the program it runs."))
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
        version = Gtk.Label(css_classes=["dim-label", "numeric"], valign=Gtk.Align.CENTER, max_width_chars=16,
                            ellipsize=Pango.EllipsizeMode.END)
        row.add_suffix(version)
        copy = Gtk.Button(icon_name="edit-copy-symbolic", css_classes=["flat"], valign=Gtk.Align.CENTER,
                          tooltip_text="Copy the attribute name")
        copy.connect("clicked", lambda _: self._copy(attr))
        row.add_suffix(copy)

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

    def _copy(self, text):
        Gdk.Display.get_default().get_clipboard().set(text)
        self.window.toast(f"Copied {text}")
