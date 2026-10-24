"""The notes under the repo's docs/guide/ and docs/gaming/, shown as pages: one
per guide and game note on the Docs tab. A small Markdown reader covers what the notes use:
headings, paragraphs, lists, quotes, tables, code blocks and inline marks. Kept
free of GTK for both front ends."""

import html
import os
import re
from dataclasses import dataclass

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


def inline(text, escape=html.escape):
    """Markup for one line of Markdown text: Pango's with GLib.markup_escape_text
    as `escape`, Qt's rich text with the default."""
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
    text = escape(text)
    text = BOLD.sub(r"<b>\1</b>", text)
    text = ITALIC.sub(r"<i>\1</i>", text)
    for i, (label, href) in enumerate(links):
        label = BOLD.sub(r"<b>\1</b>", escape(label))
        text = text.replace(f"\ue001{i}\ue001", f'<a href="{escape(href)}">{label}</a>')
    for i, c in enumerate(code):
        text = text.replace(f"\ue000{i}\ue000", f"<tt>{escape(c)}</tt>")
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


#--------------------------------------------------------------------#
#-- For the QML Front End
#--------------------------------------------------------------------#
def all_docs(flake):
    return guide_docs(flake) + game_docs(flake)


def block_json(kind, data):
    if kind == "h":
        return {"kind": "h", "level": data[0], "html": inline(data[1])}
    if kind in ("p", "quote"):
        return {"kind": kind, "html": inline(data)}
    if kind == "code":
        return {"kind": "code", "text": data}
    if kind == "list":
        return {"kind": "list", "items": [{"depth": d, "marker": m, "html": inline(t)} for d, m, t in data]}
    if kind == "table":
        columns = max(len(cells) for cells in data)
        widths = [min(TABLE_CHARS, max(len(plain(cells[c])) if c < len(cells) else 0 for cells in data))
                  for c in range(columns - 1)]
        return {"kind": "table", "widths": widths, "rows": [[inline(c) for c in cells] for cells in data]}
    return {"kind": kind}


def doc_json(flake, key):
    """One note's page: its title, path in the repo and Markdown blocks."""
    doc = next((d for d in all_docs(flake) if d.key == key), None)
    if doc is None:
        raise ValueError(f"no note {key}")
    try:
        with open(doc.path, errors="replace") as f:
            text = f.read()
    except OSError as e:
        text = f"# {doc.title}\n\nCouldn't read this note: {e}"
    return {"key": key, "title": doc.title, "path": os.path.relpath(doc.path, flake),
            "blocks": [block_json(k, d) for k, d in blocks(text)]}


def link(flake, key, href, user, machine):
    """Where a relative link in note `key` leads: {doc: key} for another note,
    {file: path in the repo or absolute} for any other file or folder, or {}.
    {user} and {machine} stand for this login's."""
    docs = all_docs(flake)
    doc = next((d for d in docs if d.key == key), None)
    if doc is None:
        return {}
    href = href.replace("{user}", user).replace("{machine}", machine)
    target = os.path.normpath(os.path.join(os.path.dirname(doc.path), href.split("#")[0]))
    found = next((d.key for d in docs if os.path.realpath(d.path) == os.path.realpath(target)), None)
    if found:
        return {"doc": found}
    return {"file": target} if os.path.exists(target) else {}
