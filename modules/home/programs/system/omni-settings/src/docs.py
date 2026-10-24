"""The Docs tab's note pages; finding and reading the notes is in docstate.py."""

import os
import re

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gio, GLib, Gtk, Pango  # noqa: E402

import docstate  # noqa: E402
import ui  # noqa: E402
from docstate import TABLE_CHARS, blocks, game_docs, guide_docs, plain, sidebar_title  # noqa: E402,F401


def inline(text):
    """Pango markup for one line of Markdown text."""
    return docstate.inline(text, GLib.markup_escape_text)


class DocPage(Gtk.ScrolledWindow):
    """One Markdown note. Links to other notes open their page; web links
    open in the browser."""

    def __init__(self, window, doc, flake):
        super().__init__(hscrollbar_policy=Gtk.PolicyType.NEVER, vexpand=True)
        self.window = window
        self.doc = doc
        body = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12, margin_top=24, margin_bottom=36,
                       margin_start=18, margin_end=18)
        try:
            with open(doc.path, errors="replace") as f:
                text = f.read()
        except OSError as e:
            text = f"# {doc.title}\n\nCouldn't read this note: {e}"

        #--- Where the note lives, and a button to open it
        where = Gtk.Box(spacing=8)
        where.append(Gtk.Label(label=os.path.relpath(doc.path, flake), css_classes=["dim-label", "caption"],
                               xalign=0, hexpand=True, ellipsize=Pango.EllipsizeMode.MIDDLE))
        open_button = Gtk.Button(icon_name=ui.link_icon(), css_classes=["flat"], valign=Gtk.Align.CENTER,
                                 tooltip_text="Open the file")
        open_button.connect("clicked", lambda _: Gtk.FileLauncher.new(Gio.File.new_for_path(doc.path))
                            .launch(window, None, None, None))
        where.append(open_button)
        body.append(where)

        for kind, data in blocks(text):
            widget = self._block(kind, data)
            if widget is not None:
                body.append(widget)
        self.set_child(Adw.Clamp(child=body, maximum_size=860, tightening_threshold=600))

    def _label(self, markup, classes=()):
        label = Gtk.Label(wrap=True, wrap_mode=Pango.WrapMode.WORD_CHAR, xalign=0, selectable=True,
                          css_classes=list(classes))
        # Pango's parser doesn't know <a>, which only GtkLabel handles
        if ui.valid_markup(re.sub(r"</?a\b[^>]*>", "", markup)):
            label.set_markup(markup)
        else:
            label.set_text(re.sub(r"<[^>]+>", "", markup))
        label.connect("activate-link", self._link)
        return label

    def _block(self, kind, data):
        if kind == "h":
            level, text = data
            classes = {1: ["title-1"], 2: ["title-2"], 3: ["title-4"]}.get(level, ["heading"])
            label = self._label(inline(text), classes)
            label.set_margin_top(4 if level == 1 else 14)
            return label
        if kind == "p":
            return self._label(inline(data), ["body"])
        if kind == "rule":
            return Gtk.Separator(margin_top=6, margin_bottom=6)
        if kind == "quote":
            box = Gtk.Box(css_classes=["doc-quote"])
            box.append(self._label(inline(data), ["body"]))
            return box
        if kind == "code":
            label = Gtk.Label(label=data, xalign=0, selectable=True, wrap=True,
                              wrap_mode=Pango.WrapMode.WORD_CHAR, css_classes=["monospace", "doc-code"])
            box = Gtk.Box(css_classes=["card"])
            box.append(label)
            return box
        if kind == "list":
            box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
            for depth, marker, text in data:
                row = Gtk.Box(spacing=8, margin_start=6 + 18 * depth)
                row.append(Gtk.Label(label=marker, valign=Gtk.Align.START, css_classes=["dim-label"]))
                row.append(self._label(inline(text), ["body"]))
                box.append(row)
            return box
        if kind == "table":
            # Rows of boxes, not a Gtk.Grid: a grid's minimum height is its height
            # at the narrowest column widths, whatever width it gets. Columns but
            # the last are as wide as their longest cell, up to TABLE_CHARS.
            columns = max(len(cells) for cells in data)
            widths = [min(TABLE_CHARS, max(len(plain(cells[c])) if c < len(cells) else 0 for cells in data))
                      for c in range(columns - 1)]
            card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, css_classes=["card"])
            for r, cells in enumerate(data):
                if r:
                    card.append(Gtk.Separator())
                row = Gtk.Box(spacing=18, margin_start=12, margin_end=12, margin_top=8, margin_bottom=8)
                for c, cell in enumerate(cells):
                    label = self._label(f"<b>{inline(cell)}</b>" if r == 0 else inline(cell))
                    label.set_valign(Gtk.Align.START)
                    if c < len(widths):
                        label.set_width_chars(widths[c])
                        label.set_max_width_chars(widths[c])
                    else:
                        label.set_hexpand(True)
                    row.append(label)
                card.append(row)
            return card
        return None

    def _link(self, _, uri):
        """Opens a link to another note on its page, and one to any other file or
        folder in the text editor. {user} and {machine} stand for this login's."""
        if re.match(r"^[a-z][a-z0-9+.-]*:", uri):
            return False  # a web link: GTK opens it
        uri = uri.replace("{user}", GLib.get_user_name()).replace("{machine}", self.window.cfg.machine)
        target = os.path.normpath(os.path.join(os.path.dirname(self.doc.path), uri.split("#")[0]))
        if self.window.open_doc(target):
            pass
        elif os.path.exists(target):
            self.window.open_in_editor(target)
        else:
            self.window.toast(f"No page for {os.path.basename(target)}")
        return True
