"""Builds the app's pages from the two _template settings files: their
`#--` sections and `#---` headers name the pages and groups, the template
values give each setting's kind, and setup.sh's app list gives labels.
PAGES places the computer, desktop and personal settings on pages of their
own; a setting it doesn't name keeps its template section and header, so a
new setting still shows up without touching the app."""

import re
from dataclasses import dataclass, field

import nixfile

#--- Never shown: account plumbing, hardware, and values set once at install
HIDDEN = {"users", "mainUser", "stateVersion", "flakePath", "gpu", "admin"}
#--- Settings whose value is a set of named lists, read and written whole
#--- (lib/settings.nix checks them the same way)
GROUPED = {("userPackages",)}

#--- Template sections whose `#---` headers each get their own page
SPLIT_SECTIONS = {"Apps"}

#--- Changes the running system can't pick up until the next boot
RESTART = {("machine", "kernel"), ("machine", "windowManager")}

#--- Lists of port numbers rather than names
PORT_LISTS = {("firewall", "openTCPPorts"), ("firewall", "openUDPPorts")}

#--- Settings picked from a list default.nix builds (or timedatectl's)
DATA_CHOICES = {("timeZone",): "timezones", ("locale",): "locales",
                ("keyboardLayout",): "layouts", ("consoleKeyMap",): "keymaps"}

#--- Page names and moves the template headers don't give
PAGE_TITLES = {
    "Wallpaper Picker (Mod+W)": "Wallpaper",
    "Language & Keyboard": "Language & Input",  # fits the sidebar's width
    "Artcraft": "ArtCraft",  # humanize() of the artcraft key
}
MOVES = {  # setting -> (page, group on that page)
    ("japanese", "vn"): ("Gaming", "Japanese Visual Novels"),
    #--- Each ArtCraft app with others of its kind; a new one stays on the ArtCraft page
    **{("artcraft", app): ("Graphics", "ArtCraft") for app in
       ("photocraft", "lightcraft", "vectorcraft", "designcraft", "figcraft", "effectcraft", "cadcraft")},
    ("artcraft", "filmcraft"): ("Media", "ArtCraft"),
    ("artcraft", "soundcraft"): ("Audio", "ArtCraft"),
    **{("artcraft", app): ("Office", "ArtCraft") for app in ("pdfcraft", "wordcraft", "gridcraft", "deckcraft")},
}

#--- Sidebar sections, top to bottom; under niri, Desktop is on the Niri tab, and
#--- the two AI sections are always on the AI tab
SECTIONS = [("computer", "This Computer"), ("desktop", "Desktop"),
            ("personal", "Personal"), ("apps", "Default Packages"),
            ("cloudai", "Cloud AI"), ("localai", "Local AI")]

#--- Each page's sidebar section, icon and blurb, and for the curated ones
#--- their groups: (title, description, [setting paths]). Pages in the apps
#--- section keep the template's groups; the one "top" page is the Flatpaks
#--- page's switch (flatpaks.py lays it out), and the "userpkgs" one the list
#--- the Packages tab's pages edit (packages.py).
PAGES = {
    "Flatpaks": ("top", "system-software-install-symbolic", "", [("", "", ["flatpak.enable"])]),
    "User Packages": ("userpkgs", "package-x-generic-symbolic", "", [("", "", ["userPackages"])]),
    "System": ("computer", "computer-symbolic",
               "The name, desktop and kernel this computer runs, the same for everyone on it.",
               [("", "", ["hostName", "windowManager", "kernel"])]),
    "Language & Input": ("computer", "preferences-desktop-locale-symbolic",
                         "Time zone, language and keyboard layout.",
                         [("Region", "", ["timeZone", "locale"]),
                          ("Keyboard", "", ["keyboardLayout", "consoleKeyMap", "capsLockRemap"]),
                          ("Japanese Typing", "", ["japanese.ime"])]),
    "Devices": ("computer", "bluetooth-symbolic",
                "Bluetooth, printing and the mouse pointer.",
                [("", "", ["bluetooth.enable", "printing.enable"]),
                 ("Mouse Pointer", "", ["cursor", "cursorSize"])]),
    "Network & Firewall": ("computer", "network-workgroup-symbolic",
                           "What other devices may reach on this computer, and what it blocks.",
                           [("Open Ports", "Other devices can connect to this computer on these.",
                             ["firewall.openTCPPorts", "firewall.openUDPPorts"]),
                            ("Ad & Tracker Blocking", "",
                             ["blocklist.enable", "blocklist.extra"])]),
    "Services": ("computer", "network-server-symbolic",
                 "Background services for everyone on this computer.",
                 [("VPN & Remote Access", "", ["mullvad.enable", "mullvad.splitTunnel", "ssh.enable"]),
                  ("Sharing & Streaming", "", ["syncthing.enable", "sunshine.enable", "suwayomi.enable"]),
                  ("Containers & Scanning", "", ["docker.enable", "clamav.enable"])]),
    "Appearance": ("desktop", "applications-graphics-symbolic",
                   "Wallpaper and the shell's look.",
                   [("Wallpaper", "", ["wallpaper"])]),
    "Displays": ("desktop", "video-display-symbolic",
                 "Monitors, night light and what each screen shows.", []),
    "Input & Connections": ("desktop", "input-keyboard-symbolic",
                            "The shell's keyboard, mouse, sound, printer and network settings.", []),
    "Desktop Shell": ("desktop", "view-app-grid-symbolic",
                      "The bar, dock, launcher, notifications and widgets.", []),
    "Power & Lock": ("desktop", "system-lock-screen-symbolic",
                     "Idle timers, the lock screen and the power menu.", []),
    "Account": ("personal", "avatar-default-symbolic",
                "Your name on git commits and the keys that may log in as you.",
                [("Git", "", ["git.name", "git.email"]),
                 ("Remote Login", "", ["ssh.authorizedKeys"])]),
    "Default Apps": ("personal", "emblem-default-symbolic",
                     "Which app opens links, text files, terminal programs and folders.",
                     [("", "", ["defaultApps.browser", "defaultApps.textEditor",
                                "defaultApps.terminal", "defaultApps.fileManager"])]),
    "Browsers": ("apps", "web-browser-symbolic", "Browsers to install. The one that opens links "
                 "is picked under Default Apps.", None),
    "Terminals": ("apps", "utilities-terminal-symbolic", "Terminal emulators to install.", None),
    "Editors": ("apps", "accessories-text-editor-symbolic", "Text and code editors to install.", None),
    "File Browsers": ("apps", "folder-symbolic", "File managers to install.", None),
    "Media": ("apps", "applications-multimedia-symbolic", "Video, music, streaming and reading.", None),
    "Graphics": ("apps", "applications-graphics-symbolic", "3D, painting and design.", None),
    "ArtCraft": ("apps", "draw-brush-symbolic", "Rust creative and office suite.", None),
    "Audio": ("apps", "audio-x-generic-symbolic", "Recording, mixing and guitar tools.", None),
    "Office": ("apps", "x-office-document-symbolic", "Mail, notes and money.", None),
    "Security": ("apps", "security-high-symbolic", "Passwords and clean-up.", None),
    "System Tools": ("apps", "utilities-system-monitor-symbolic", "Monitoring tools.", None),
    "Android": ("apps", "phone-symbolic", "Phones and tablets.", None),
    "Gaming": ("apps", "applications-games-symbolic", "Launchers, games and gaming tools.", None),
    "Discord": ("apps", "user-available-symbolic", "Discord and showing what you play.", None),
    "Claude": ("cloudai", "applications-science-symbolic",
               "Anthropic's Claude, signed in with your Claude account.",
               [("", "", ["claude.enable", "claudeDesktop.enable"])]),
    "Tools": ("localai", "utilities-terminal-symbolic",
              "The local model server, the app that downloads models, and opencode, "
              "the coding agent that uses them.",
              [("", "", ["llamaSwap.enable", "lmstudio.enable", "opencode.enable", "openWebui.enable"])]),
    "Models": ("localai", "applications-engineering-symbolic",
               "The models llama-swap runs on this computer, one at a time.",
               [("Code", "For opencode and Zed's agent panel.", ["localAi.code"]),
                ("Chat", "For conversation in Open WebUI or llama-swap's Playground, which also "
                 "list the coding models.", ["localAi.chat"]),
                ("Inline Suggestions", "Zed's suggestions as you type, run on the CPU so the GPU "
                 "stays free.", ["localAi.edit"])]),
}

#--- List and none-or-one settings shown as one switch per model, straight in their group
SWITCH_LISTS = {"localAi.code", "localAi.chat", "localAi.edit"}

#--- Text shown above a page's groups, with descriptions.json's ** and !! marks
PAGE_INTROS = {
    "Models": "Download a model in **LM Studio** (turn it on under Tools) before turning it on "
              "here: open its **Discover** tab, search for the repo, pick the named file from the "
              "download options and download it. llama-swap finds it in ~/.lmstudio/models, so it "
              "doesn't need loading in LM Studio.\n\n"
              "Code\n"
              "1. **Ornith 1.5 35B A3B**: ornith-ai/Ornith-1.5-35B-A3B-GGUF, the Q4_K_M file "
              "(~23 GB)\n"
              "2. **Qwen3.6 35B A3B (Q4)**: unsloth/Qwen3.6-35B-A3B-GGUF, the UD-Q4_K_XL file "
              "(~21 GB)\n\n"
              "Chat\n"
              "3. **gpt-oss 20B**: ggml-org/gpt-oss-20b-GGUF (~13 GB)\n"
              "4. **Gemma 4 26B A4B**: unsloth/gemma-4-26B-A4B-it-qat-GGUF, the UD-Q4_K_XL file "
              "(~14 GB)\n\n"
              "Inline Suggestions\n"
              "5. **Sweep Next-Edit 1.5B**: sweepai/sweep-next-edit-1.5B\n"
              "6. **Qwen2.5 Coder 1.5B**: ggml-org/Qwen2.5-Coder-1.5B-Q8_0-GGUF\n\n"
              "!!Without the file, an app gets an error the first time it uses the model.!!",
}
FALLBACK_ICON = "applications-system-symbolic"

SETUP_ENTRY = re.compile(r'^\s*"([^"|]+)\|([^"|]+)\|([^"]+)"\s*$', re.M)


@dataclass
class Setting:
    domain: str  # "machine" or "user"
    path: tuple
    kind: str  # bool, choice, text, pick (from a data list), list
    title: str
    subtitle: str = ""
    nullable: bool = False
    choices: list = field(default_factory=list)
    options: list = field(default_factory=list)  # known items of a list
    ports: bool = False  # a list of port numbers
    data: str = ""  # for kind pick: which list (DATA_CHOICES)
    #--- From descriptions.json
    description: str = ""  # shown when the row expands
    note: str = ""  # a caution under the summary
    icon: list = field(default_factory=list)  # icon names or .desktop ids to try
    labels: dict = field(default_factory=dict)  # choice value -> label
    default: object = None  # the template's value


@dataclass
class Group:
    title: str
    description: str = ""
    settings: list = field(default_factory=list)
    links: list = field(default_factory=list)  # dms.Link, after the settings


@dataclass
class Page:
    domain: str
    title: str
    description: str = ""
    groups: list = field(default_factory=list)
    section: str = ""  # sidebar section (SECTIONS), set by arrange
    icon: str = ""


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
        if isinstance(b.value, nixfile.AttrSet) and path not in GROUPED:
            yield from leaves(b.value, path)
        else:
            yield path, b, prefix


def build(domain, template_text, choices, labels, list_choices=None):
    list_choices = list_choices or {}
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
                                           lead_text if not parent else [], header_title, header_desc,
                                           list_choices))

    for p in pages:
        p.groups = [g for g in p.groups if g.settings]
    return [p for p in pages if p.groups]


def make_setting(domain, path, b, values, choices, labels, doc, lead, header_title, header_desc,
                 list_choices):
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
    s.default = value
    if dotted in choices:
        s.kind, s.choices = "choice", choices[dotted]
    elif isinstance(value, bool):
        s.kind = "bool"
    elif path in GROUPED:
        s.kind = "groups"
    elif isinstance(value, list):
        s.kind = "list"
        s.ports = path in PORT_LISTS
        m = re.search(r"Known names:\s*(.+)", desc)
        if dotted in list_choices:
            s.options = list(list_choices[dotted])
        elif m:
            s.options = [o.strip() for o in m.group(1).split(",")]
        if m:
            s.subtitle = desc[: m.start()].strip()
    elif path in DATA_CHOICES:
        s.kind, s.data = "pick", DATA_CHOICES[path]
    else:
        s.nullable = value is None
    return s


def arrange(pages, links=()):
    """Lays the settings out: the curated PAGES first, in their order, holding the
    settings they name; every other setting stays on its template page (renamed by
    PAGE_TITLES, moved by MOVES), sorted by name. `links` (dms.Link) join the
    group their page and group name, made if missing. Pages left empty are
    dropped; app pages sort A-Z."""
    pool = {}  # path -> (setting, template page, template group)
    for page in pages:
        page.title = PAGE_TITLES.get(page.title, page.title)
        for group in page.groups:
            for s in group.settings:
                pool[s.path] = (s, page, group)

    out = []
    placed = set()
    for title, (section, icon, description, groups) in PAGES.items():
        if groups is None:
            continue
        page = Page("machine" if section == "computer" else "user", title, description,
                    section=section, icon=icon)
        for group_title, group_desc, paths in groups:
            group = Group(group_title, group_desc)
            for dotted in paths:
                path = tuple(dotted.split("."))
                if path in pool:
                    group.settings.append(pool[path][0])
                    placed.add(path)
            page.groups.append(group)
        out.append(page)

    by_title = {p.title: p for p in out}
    for page in pages:
        for group in page.groups:
            group.settings = [s for s in group.settings if s.path not in placed]
    for path, (s, _, source) in pool.items():
        if path in placed or path not in MOVES:
            continue
        title, group_title = MOVES[path]
        target = next((p for p in pages if p.title == title), None) or by_title.get(title)
        if target is None:
            continue
        source.settings.remove(s)
        group = next((g for g in target.groups if g.title == group_title), None)
        if group is None:
            group = Group(group_title)
            target.groups.append(group)
        group.settings.append(s)

    for page in pages:
        if page.title in by_title:
            # A template page with the same name as a curated one adds its groups there
            by_title[page.title].groups += [g for g in page.groups if g.settings]
            continue
        page.groups = [g for g in page.groups if g.settings]
        for group in page.groups:
            group.settings.sort(key=lambda s: s.title.casefold())
        info = PAGES.get(page.title)
        if info:
            page.section, page.icon, page.description = info[0], info[1], info[2] or page.description
        elif page.domain == "machine":
            page.section = "computer"
        elif any(s.kind == "bool" for g in page.groups for s in g.settings):
            page.section = "apps"
        else:
            page.section = "personal"
        page.icon = page.icon or FALLBACK_ICON
        out.append(page)

    for link in links:
        page = next((p for p in out if p.title == link.page), None)
        if page is None:
            info = PAGES.get(link.page, ("desktop", FALLBACK_ICON, "", []))
            page = Page("user", link.page, info[2], section=info[0], icon=info[1])
            out.append(page)
        group = next((g for g in page.groups if g.title == link.group), None)
        if group is None:
            group = Group(link.group)
            page.groups.append(group)
        group.links.append(link)

    out = [p for p in out if any(g.settings or g.links for g in p.groups)]
    for page in out:
        page.groups = [g for g in page.groups if g.settings or g.links]
    order = {key: i for i, (key, _) in enumerate(SECTIONS)}
    curated = list(PAGES)
    return sorted(out, key=lambda p: (order.get(p.section, len(order)),
                                      curated.index(p.title) if p.section != "apps" and p.title in curated
                                      else len(curated),
                                      p.title.casefold()))
