"""The notes under the repo's docs/guide/ and docs/gaming/, shown as pages: one
per guide and game note on the Docs tab. A small Markdown reader covers what the notes use:
headings, paragraphs, lists, quotes, tables, code blocks and inline marks."""

import os
import re
from dataclasses import dataclass

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gio, GLib, Gtk, Pango  # noqa: E402

import ui  # noqa: E402

GAMES = os.path.join("docs", "gaming")
GUIDES = os.path.join("docs", "guide")

FENCE = re.compile(r"^\s*(```|~~~)")
HEADING = re.compile(r"^(#{1,6})\s+(.*?)\s*#*\s*$")
ITEM = re.compile(r"^(\s*)([-*+]|\d+[.)])\s+(.*)$")
RULE = re.compile(r"^\s*([-*_])(\s*\1){2,}\s*$")
TABLE_SEP = re.compile(r"^\s*\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)*\|?\s*$")
LINK = re.compile(r"\[([^\]]+)\]\(([^)\s]+)\)")
BOLD = re.compile(r"\*\*(.+?)\*\*")
ITALIC = re.compile(r"(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?![\w*])")


@dataclass
class Doc:
    key: str  # sidebar key
    path: str  # absolute
    title: str


def first_heading(path):
    try:
        with open(path, errors="replace") as f:
            for line in f:
                m = HEADING.match(line)
                if m and len(m.group(1)) == 1:
                    return m.group(2)
    except OSError:
        pass
    return os.path.splitext(os.path.basename(path))[0].replace("-", " ").capitalize()


def _docs(folder, key_prefix):
    try:
        names = sorted(n for n in os.listdir(folder) if n.endswith(".md"))
    except OSError:
        return []
    return [Doc(f"{key_prefix}{n}", os.path.join(folder, n), first_heading(os.path.join(folder, n)))
            for n in names]


def game_docs(flake):
    """[Doc] for docs/gaming/*.md, by title."""
    return sorted(_docs(os.path.join(flake, GAMES), "doc:games/"), key=lambda d: d.title.lower())


def guide_docs(flake):
    """[Doc] for docs/guide/*.md, in file name order (the names are numbered)."""
    return _docs(os.path.join(flake, GUIDES), "doc:guide/")


SIDEBAR_CHARS = 22  # what fits the sidebar's narrowest width without cutting off
SPLITS = [(" — ", ""), (" - ", ""), (": ", ""), (" (", ""), (" & ", ""), (" on ", "on ")]


def sidebar_title(title):
    """(title, subtitle) for a sidebar item: a long title splits where it
    breaks naturally, so neither line is cut off. The page shows it whole."""
    if len(title) <= SIDEBAR_CHARS:
        return title, ""
    for sep, keep in SPLITS:
        head, found, rest = title.partition(sep)
        if found and len(head) <= SIDEBAR_CHARS:
            break
    else:
        words, head = title.split(), ""
        while words and len(f"{head} {words[0]}".strip()) <= SIDEBAR_CHARS:
            head = f"{head} {words.pop(0)}".strip()
        rest, keep = " ".join(words), ""
    rest = (keep + rest).strip().rstrip(")")
    if len(rest) > SIDEBAR_CHARS + 6:
        rest = rest.split(" & ")[0]
    return head, rest


#--------------------------------------------------------------------#
#-- Markdown
#--------------------------------------------------------------------#
TABLE_CHARS = 28  # widest a table column gets before the last one


def plain(text):
    """A line of Markdown as the text it shows, for measuring."""
    return re.sub(r"\*\*|`", "", LINK.sub(r"\1", text))


def inline(text):
    """Pango markup for one line of Markdown text."""
    # Code spans and links are set aside first, so bold can wrap around them
    code, links = [], []

    def keep_code(m):
        code.append(m.group(1))
        return f"\ue000{len(code) - 1}\ue000"

    def keep_link(m):
        links.append((m.group(1), m.group(2)))
        return f"\ue001{len(links) - 1}\ue001"
    text = re.sub(r"`([^`]+)`", keep_code, text)
    text = LINK.sub(keep_link, text)
    text = GLib.markup_escape_text(text)
    text = BOLD.sub(r"<b>\1</b>", text)
    text = ITALIC.sub(r"<i>\1</i>", text)
    for i, (label, href) in enumerate(links):
        label = BOLD.sub(r"<b>\1</b>", GLib.markup_escape_text(label))
        text = text.replace(f"\ue001{i}\ue001", f'<a href="{GLib.markup_escape_text(href)}">{label}</a>')
    for i, c in enumerate(code):
        text = text.replace(f"\ue000{i}\ue000", f"<tt>{GLib.markup_escape_text(c)}</tt>")
    return text


def blocks(text):
    """The Markdown as (kind, data) blocks."""
    lines = text.splitlines()
    out, para, i = [], [], 0

    def flush():
        if para:
            out.append(("p", " ".join(s.strip() for s in para)))
            para.clear()
    while i < len(lines):
        line = lines[i]
        if FENCE.match(line):
            flush()
            fence = FENCE.match(line).group(1)
            code = []
            i += 1
            while i < len(lines) and not lines[i].strip().startswith(fence):
                code.append(lines[i])
                i += 1
            out.append(("code", "\n".join(code)))
        elif not line.strip():
            flush()
        elif HEADING.match(line):
            flush()
            m = HEADING.match(line)
            out.append(("h", (len(m.group(1)), m.group(2))))
        elif RULE.match(line):
            flush()
            out.append(("rule", None))
        elif line.lstrip().startswith("|") and i + 1 < len(lines) and TABLE_SEP.match(lines[i + 1]):
            flush()
            rows = [line]
            i += 2
            while i < len(lines) and lines[i].lstrip().startswith("|"):
                rows.append(lines[i])
                i += 1
            cells = [[c.strip() for c in r.strip().strip("|").split("|")] for r in rows]
            out.append(("table", cells))
            continue
        elif line.lstrip().startswith(">"):
            flush()
            quote = []
            while i < len(lines) and lines[i].lstrip().startswith(">"):
                quote.append(lines[i].lstrip()[1:].strip())
                i += 1
            out.append(("quote", " ".join(quote)))
            continue
        elif ITEM.match(line):
            flush()
            items = []
            while i < len(lines):
                m = ITEM.match(lines[i])
                if m:
                    marker = m.group(2)
                    items.append([len(m.group(1).expandtabs(4)) // 2,
                                  "•" if marker in "-*+" else marker, m.group(3)])
                elif lines[i].strip() and lines[i].startswith((" ", "\t")) and items:
                    items[-1][2] += " " + lines[i].strip()
                else:
                    break
                i += 1
            out.append(("list", items))
            continue
        else:
            para.append(line)
        i += 1
    flush()
    return out


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
