"""Builds the app's pages from the two _template settings files: their
`#--` sections and `#---` headers name the pages and groups, the template
values give each setting's kind, and setup.sh's app list gives labels."""

import re
from dataclasses import dataclass, field

import nixfile

#--- Never shown: account plumbing, hardware, and values set once at install
HIDDEN = {"users", "mainUser", "stateVersion", "flakePath", "gpu", "admin"}

#--- Template sections whose `#---` headers each get their own page
SPLIT_SECTIONS = {"Apps"}

#--- Changes the running system can't pick up until the next boot
RESTART = {("machine", "kernel"), ("machine", "windowManager")}

#--- Page names and moves the template headers don't give
PAGE_TITLES = {
    "Wallpaper Picker (Mod+W)": "Wallpaper",
    "Android Screen Mirroring (scrcpy)": "Android",
}
MOVES = {  # setting -> (page, group on that page)
    ("japanese", "ime"): ("Language & Keyboard", "Japanese Typing"),
    ("japanese", "vn"): ("Gaming", "Japanese Visual Novels"),
}

SETUP_ENTRY = re.compile(r'^\s*"([^"|]+)\|([^"|]+)\|([^"]+)"\s*$', re.M)


@dataclass
class Setting:
    domain: str  # "machine" or "user"
    path: tuple
    kind: str  # bool, choice, text, timezone, list
    title: str
    subtitle: str = ""
    nullable: bool = False
    choices: list = field(default_factory=list)
    options: list = field(default_factory=list)  # known items of a list
    description: str = ""  # from descriptions.json, shown when the row expands


@dataclass
class Group:
    title: str
    description: str = ""
    settings: list = field(default_factory=list)


@dataclass
class Page:
    domain: str
    title: str
    description: str = ""
    groups: list = field(default_factory=list)


def humanize(key):
    words = re.sub(r"(?<=[a-z0-9])(?=[A-Z])", " ", key).split()
    return " ".join(w[0].upper() + w[1:] for w in words)


def setup_labels(text):
    labels = {}
    for _, path, label in SETUP_ENTRY.findall(text):
        for sep in (": ", " ("):
            if sep in label:
                head, tail = label.split(sep, 1)
                tail = tail.rstrip(")") if sep == " (" else tail
                labels[path] = (head, tail[0].upper() + tail[1:])
                break
        else:
            labels[path] = (label, "")
    return labels


def comment_text(c):
    return re.sub(r"^#[-#]*\s?", "", c.text).strip()


def leaves(attrset, prefix=()):
    for b in attrset.bindings:
        path = prefix + tuple(b.path)
        if isinstance(b.value, nixfile.AttrSet):
            yield from leaves(b.value, path)
        else:
            yield path, b, prefix


def build(domain, template_text, choices, labels):
    doc = nixfile.parse(template_text)
    #--- Comments alone on their line, by line number
    by_line = {}
    for c in doc.comments:
        if template_text[template_text.rfind("\n", 0, c.start) + 1 : c.start].strip() == "":
            by_line[c.line] = c
    values = nixfile.to_python(doc.root)

    pages, page, group = [], None, None
    last_section = last_header = prev_path = None
    for path, b, parent in leaves(doc.root):
        line = doc.line_of(b.start)

        #--- Comments above this binding: section, header, and the lead lines
        lead, n = [], line - 1
        while n in by_line and by_line[n].start < b.start:
            lead.insert(0, by_line[n])
            n -= 1
        section = header = None
        for c in reversed([c for c in doc.comments if c.start < b.start]):
            if c.text.startswith("#--- ") and header is None:
                header = c
            if c.text.startswith("#-- "):
                section = c
                break
        if header is not None and section is not None and header.start < section.start:
            header = None
        # A header that wraps onto more `#---` lines starts at the first one
        while header is not None and header.line - 1 in by_line \
                and by_line[header.line - 1].text.startswith("#--- "):
            header = by_line[header.line - 1]
        lead_text = [comment_text(c) for c in lead if not c.text.startswith("#-")]

        if path[0] in HIDDEN or section is None:
            continue
        section_title = comment_text(section)

        #--- Header title plus the plain comment lines right after it
        header_title = header_desc = ""
        if header is not None:
            parts, desc, n = [comment_text(header)], [], header.line + 1
            while n in by_line and by_line[n].start < b.start:
                t = by_line[n].text
                if t.startswith("#--- "):
                    parts.append(comment_text(by_line[n]))
                elif not t.startswith("#-"):
                    desc.append(comment_text(by_line[n]))
                n += 1
            header_title = " ".join(parts)
            header_desc = " ".join(d for d in desc if not d.startswith("Options:"))

        if section_title in SPLIT_SECTIONS:
            if header is not last_header:
                title = re.sub(r"( Software)? Selection$", "", header_title.split(":")[0])
                if humanize(path[0]).lower().startswith(title.lower()):
                    title = humanize(path[0])  # "Browser Selection" -> "Browsers"
                merge = page is not None and section is last_section and prev_path[0] == path[0]
                if not merge:
                    page = Page(domain, title, description=header_desc)
                    pages.append(page)
                group = Group(header_title if merge else "")
                page.groups.append(group)
            if lead_text and parent:
                t = " ".join(lead_text)
                group = Group(t) if len(t) <= 30 else Group("", t)
                page.groups.append(group)
        else:
            if page is None or page.title != section_title:
                page = Page(domain, section_title)
                pages.append(page)
                group = None
            if group is None or header is not last_header:
                short = len(header_title) <= 40
                group = Group(header_title if short else "", header_desc if short else header_title)
                page.groups.append(group)
        last_section, last_header, prev_path = section, header, path

        group.settings.append(make_setting(domain, path, b, values, choices, labels, doc,
                                           lead_text if not parent else [], header_title, header_desc))

    for p in pages:
        p.groups = [g for g in p.groups if g.settings]
    return [p for p in pages if p.groups]


def make_setting(domain, path, b, values, choices, labels, doc, lead, header_title, header_desc):
    dotted = ".".join(path)
    trailing = ""
    end_line = doc.line_of(b.end)
    for c in doc.comments:
        if c.line == end_line and c.start >= b.end:
            trailing = comment_text(c)
    desc = " ".join(lead)

    value = values
    for k in path:
        value = value[k]

    if dotted in labels:
        title, subtitle = labels[dotted]
        subtitle = subtitle or trailing
    elif path[-1] == "enable":
        title, subtitle = humanize(path[-2]), trailing or header_desc
        if len(path) == 2 and header_title and domain == "machine":
            title = header_title
    else:
        title, subtitle = humanize(path[-1]), trailing or desc

    if subtitle.startswith("Options:"):
        subtitle = ""
    s = Setting(domain, path, "text", title, subtitle)
    if dotted in choices:
        s.kind, s.choices = "choice", choices[dotted]
    elif isinstance(value, bool):
        s.kind = "bool"
    elif isinstance(value, list):
        s.kind = "list"
        m = re.search(r"Known names:\s*(.+)", desc)
        if m:
            s.options = [o.strip() for o in m.group(1).split(",")]
            s.subtitle = desc[: m.start()].strip()
    elif dotted == "timeZone":
        s.kind = "timezone"
    else:
        s.nullable = value is None
    return s


def arrange(pages):
    """Applies PAGE_TITLES and MOVES to the built pages, dropping any left empty."""
    moved = []
    for page in pages:
        page.title = PAGE_TITLES.get(page.title, page.title)
        for group in page.groups:
            moved += [s for s in group.settings if s.path in MOVES]
            group.settings = [s for s in group.settings if s.path not in MOVES]
    by_title = {page.title: page for page in pages}
    for s in moved:
        title, group_title = MOVES[s.path]
        page = by_title.get(title)
        if page is None:
            page = by_title[title] = Page(s.domain, title)
            pages.append(page)
        group = next((g for g in page.groups if g.title == group_title), None)
        if group is None:
            group = Group(group_title)
            page.groups.append(group)
        group.settings.append(s)
    for page in pages:
        page.groups = [g for g in page.groups if g.settings]
    return [p for p in pages if p.groups]
