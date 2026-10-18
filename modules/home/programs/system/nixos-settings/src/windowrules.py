"""The Window Rules page (Niri tab): pick an open window, choose what niri does
with it, and the rule is added to modules/wm/niri/home/core/window-rules.json,
which rules.nix appends after its own rules; a rebuild applies it. The rules
niri already has are listed read-only from the copy rules.nix writes to
~/.config/nixos-settings/, sorted into groups by what they do."""

import json
import os

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gio, GLib, Gtk  # noqa: E402

import ui  # noqa: E402

RULES_FILE = os.path.join("modules", "wm", "niri", "home", "core", "window-rules.json")
APPLIED_FILE = os.path.join(GLib.get_user_config_dir(), "nixos-settings", "niri-window-rules.json")

#--- Characters niri's (Rust) regex treats as special
SPECIAL = set("\\.+*?()|[]{}^$")

#--- (label, value) for the width and height choices; None is a pixel size
SIZES = [("One Third", {"proportion": 0.33333}), ("Half", {"proportion": 0.5}),
         ("Two Thirds", {"proportion": 0.66667}), ("Full", {"proportion": 1.0}),
         ("Pixels", None), ("The Window's Own", {})]

#--- (rule property, title, group, control, choices). Controls: "on" sets true,
#--- "choice" picks from the choices, "size", "opacity", "workspace", "output"
KINDS = [
    ("open-floating", "Open Floating", "Floating", "on", []),
    ("default-column-width", "Width", "Size & Position", "size", []),
    ("default-window-height", "Height", "Size & Position", "size", []),
    ("open-maximized", "Open Maximized", "Size & Position", "on", []),
    ("open-fullscreen", "Open Fullscreen", "Size & Position", "on", []),
    ("open-on-workspace", "Open on Workspace", "Placement", "workspace", []),
    ("open-on-output", "Open on Monitor", "Placement", "output", []),
    ("open-focused", "Focus When Opened", "Focus", "choice",
     [("Don't Focus", False), ("Always Focus", True)]),
    ("opacity", "Opacity", "Appearance", "opacity", []),
    ("block-out-from", "Hide From Screen Capture", "Privacy", "choice",
     [("Screenshots and Recording", "screen-capture"), ("Recording Only", "screencast")]),
    ("variable-refresh-rate", "Variable Refresh Rate", "Performance", "on", []),
]
KIND = {k[0]: k for k in KINDS}

#--- Groups for the properties only the config's own rules set
EXTRA_GROUPS = {"default-floating-position": "Size & Position", "open-maximized-to-edges": "Size & Position",
                "geometry-corner-radius": "Appearance", "clip-to-geometry": "Appearance",
                "draw-border-with-background": "Appearance", "shadow": "Appearance",
                "focus-ring": "Appearance", "border": "Appearance", "tab-indicator": "Appearance"}

GROUPS = [("Floating", "Windows that open above the tiled ones."),
          ("Size & Position", "How big a window opens, and where."),
          ("Placement", "The workspace or monitor a window opens on."),
          ("Focus", "Whether a window takes the keyboard when it opens."),
          ("Appearance", "Opacity, corners, borders and shadows."),
          ("Privacy", "Windows blacked out in screenshots and screen recordings."),
          ("Performance", "Windows that turn on variable refresh rate while shown."),
          ("Other", "")]

NOT_PROPERTIES = ("name", "matches", "excludes")


#--------------------------------------------------------------------#
#-- Reading and writing
#--------------------------------------------------------------------#
def clean(value):
    """`value` without the unset (null) options and empty lists niri-flake fills in."""
    if isinstance(value, dict):
        out = {}
        for k, v in value.items():
            c = clean(v)
            if c is None or c == [] or (isinstance(v, dict) and v and c == {}):
                continue
            out[k] = c
        return out
    if isinstance(value, list):
        return [clean(v) for v in value]
    return value


def bare(rule):
    """A rule as rules.nix hands it to niri: without its name."""
    return clean({k: v for k, v in rule.items() if k != "name"})


def load(path):
    try:
        with open(path) as f:
            data = json.load(f)
        return data if isinstance(data, list) else []
    except (OSError, ValueError):
        return []


def save(path, rules):
    with open(path, "w") as f:
        f.write(json.dumps(rules, indent=2) + "\n")


def regex(text):
    """`text` matched exactly, as a niri regular expression."""
    return "^" + "".join("\\" + c if c in SPECIAL else c for c in text) + "$"


def niri(args, done):
    """Runs `niri msg --json <args>` off the main loop; done(result, error).
    A result that isn't JSON (a cancelled pick) comes back as None."""
    try:
        proc = Gio.Subprocess.new(["niri", "msg", "--json", *args],
                                  Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE)
    except GLib.Error as e:
        done(None, e.message)
        return

    def finished(p, res):
        try:
            _, out, err = p.communicate_utf8_finish(res)
        except GLib.Error as e:
            done(None, e.message)
            return
        if not p.get_successful():
            done(None, (err or out or "").strip() or "niri msg failed")
            return
        try:
            done(json.loads(out), None)
        except ValueError:
            done(None, None)
    proc.communicate_utf8_async(None, None, finished)


#--------------------------------------------------------------------#
#-- Describing a rule
#--------------------------------------------------------------------#
def size_text(value):
    if value == {}:
        return "the window's own"
    if "fixed" in value:
        return f"{value['fixed']} px"
    p = value.get("proportion")
    for label, v in SIZES:
        if v and abs(v.get("proportion", -1) - (p or 0)) < 0.001:
            return label.lower()
    return f"{round((p or 0) * 100)}%" if p is not None else json.dumps(value)


def property_text(prop, value):
    kind = KIND.get(prop)
    if prop in ("default-column-width", "default-window-height") and isinstance(value, dict):
        return f"{kind[1]}: {size_text(value)}"
    if prop == "opacity":
        return f"Opacity {round(value * 100)}%"
    if kind and kind[3] == "choice":
        label = next((l for l, v in kind[4] if v == value), str(value))
        return f"{kind[1]}: {label}"
    if kind and kind[3] in ("workspace", "output"):
        return f"{kind[1]} {value}"
    title = kind[1] if kind else prop.replace("-", " ").capitalize()
    if value is True:
        return title
    if value is False:
        return f"{title}: off"
    if prop == "default-floating-position" and isinstance(value, dict):
        return f"Position: {value.get('x', 0)}, {value.get('y', 0)} from {value.get('relative-to', 'top-left')}"
    if isinstance(value, dict):
        value = ", ".join(f"{k.replace('-', ' ')} {v if isinstance(v, (str, int, float)) else json.dumps(v)}"
                          for k, v in value.items())
    return f"{title}: {value}"


def pretty(pattern):
    """An exact-match regex (^name$) as the plain name it matches."""
    if len(pattern) > 1 and pattern[0] == "^" and pattern[-1] == "$":
        inner, out, i = pattern[1:-1], "", 0
        while i < len(inner):
            c = inner[i]
            if c == "\\" and i + 1 < len(inner) and inner[i + 1] in SPECIAL:
                out, i = out + inner[i + 1], i + 2
                continue
            if c in SPECIAL:
                return pattern
            out, i = out + c, i + 1
        return out
    return pattern


def match_text(match):
    parts = []
    if "app-id" in match:
        parts.append(pretty(match["app-id"]))
    if "title" in match:
        parts.append(f"titled {pretty(match['title'])}")
    for k, v in match.items():
        if k not in ("app-id", "title"):
            parts.append(k.replace("-", " ") if v is True else f"{k.replace('-', ' ')} {v}")
    return ", ".join(parts) or "any window"


def rule_title(rule):
    matches = rule.get("matches") or []
    if rule.get("name"):
        return rule["name"]
    if not matches:
        return "Every Window"
    if len(matches) == 1:
        return match_text(matches[0])
    return f"{len(matches)} Kinds of Window"


def properties(rule):
    return [(k, v) for k, v in rule.items() if k not in NOT_PROPERTIES]


def group_of(rule):
    props = [k for k, _ in properties(rule)]
    for prop, _, group, _, _ in KINDS:
        if prop in props:
            return group
    return next((EXTRA_GROUPS[p] for p in props if p in EXTRA_GROUPS), "Other")


#--------------------------------------------------------------------#
#-- Page
#--------------------------------------------------------------------#
class WindowRulesPage(Adw.PreferencesPage):
    def __init__(self, window):
        super().__init__()
        self.window = window
        self.path = os.path.join(window.cfg.flake, RULES_FILE)
        self.picked = None
        self.workspaces, self.outputs = [], []
        self.list_groups = []
        self.dirty = False  # saved here since the page was made

        top = Adw.PreferencesGroup()
        if window.wm != "niri":
            top.add(ui.hero("window-new-symbolic", "Window Rules",
                            f"These rules are niri's, and this computer runs {window.wm or 'another'} "
                            "window manager."))
            self.add(top)
            return
        self.editable = window.admin and window.direct and os.access(self.path, os.W_OK)
        buttons = Gtk.Box(spacing=8, halign=Gtk.Align.CENTER, margin_top=6)
        pick = Gtk.Button(css_classes=["pill", "suggested-action"], sensitive=self.editable,
                          child=Adw.ButtonContent(icon_name="find-location-symbolic", label="Pick a Window"),
                          tooltip_text="Click any window to fill in the rule for it")
        pick.connect("clicked", self._pick)
        self.open_list = Gtk.ListBox(selection_mode=Gtk.SelectionMode.NONE, css_classes=["boxed-list"])
        self.open_list.connect("row-activated", lambda _, row: self._use(row.niri_window))
        scroll = Gtk.ScrolledWindow(child=self.open_list, propagate_natural_height=True,
                                    max_content_height=420, min_content_width=360,
                                    hscrollbar_policy=Gtk.PolicyType.NEVER)
        self.popover = Gtk.Popover(child=scroll)
        self.popover.connect("notify::visible", self._list_windows)
        windows = Gtk.MenuButton(css_classes=["pill"], popover=self.popover, sensitive=self.editable,
                                 child=Adw.ButtonContent(icon_name="view-list-symbolic",
                                                         label="Open Windows"),
                                 tooltip_text="Choose from the windows open now")
        buttons.append(pick)
        buttons.append(windows)
        blurb = ("Pick a window, choose what niri should do with it, and the rule joins the list "
                 "below. A rebuild applies it.")
        if not self.editable:
            blurb = "Only an admin who can edit the config's files can add window rules."
        top.add(ui.hero("window-new-symbolic", "Window Rules", blurb, extra=buttons))
        self.add(top)

        self._form()
        self.pending = Adw.PreferencesGroup()
        row = Adw.ActionRow(title="Not Applied Yet",
                            subtitle="Rebuild to give niri the rules changed here.")
        row.add_prefix(Gtk.Image(icon_name="emblem-synchronizing-symbolic", css_classes=["hero-icon"]))
        rebuild = Gtk.Button(label="Rebuild", valign=Gtk.Align.CENTER, css_classes=["suggested-action"],
                             visible=window.can_apply and window.admin)
        rebuild.connect("clicked", lambda _: window.confirm_rebuild())
        row.add_suffix(rebuild)
        self.pending.add(row)
        self.add(self.pending)
        self.refresh()
        niri(["workspaces"], self._got_workspaces)
        niri(["outputs"], self._got_outputs)

    #--- The new rule's form
    def _form(self):
        self.form = Adw.PreferencesGroup(title="New Rule", sensitive=self.editable,
                                         description="Filled in from the window you pick; the app ID "
                                                     "and title are regular expressions.")
        self.name_row = Adw.EntryRow(title="Name")
        self.app_row = Adw.EntryRow(title="App ID")
        self.title_switch = Adw.SwitchRow(title="Match the Title Too",
                                          subtitle="For one window of an app, like a dialog or popout")
        self.title_row = Adw.EntryRow(title="Title", visible=False)
        self.title_switch.connect("notify::active",
                                  lambda *_: self.title_row.set_visible(self.title_switch.get_active()))
        self.kind_row = Adw.ComboRow(title="Rule", model=Gtk.StringList.new([k[1] for k in KINDS]))
        self.kind_row.connect("notify::selected", lambda *_: self._kind_changed())
        self.choice_row = Adw.ComboRow(title="Value")
        self.size_row = Adw.ComboRow(title="Size", model=Gtk.StringList.new([l for l, _ in SIZES]))
        self.size_row.connect("notify::selected", lambda *_: self._kind_changed())
        self.pixels_row = Adw.SpinRow.new_with_range(50, 8000, 10)
        self.pixels_row.set_title("Pixels")
        self.pixels_row.set_value(800)
        self.opacity_row = Adw.SpinRow.new_with_range(0.05, 1.0, 0.05)
        self.opacity_row.set_title("Opacity")
        self.opacity_row.set_digits(2)
        self.opacity_row.set_value(0.9)
        self.place_row = Adw.ComboRow(title="Where")
        self.place_entry = Adw.EntryRow(title="Workspace name")
        add = Gtk.Button(label="Add Rule", halign=Gtk.Align.CENTER, margin_top=12,
                         css_classes=["pill", "suggested-action"])
        add.connect("clicked", lambda _: self._add())
        for row in (self.name_row, self.app_row, self.title_switch, self.title_row, self.kind_row,
                    self.choice_row, self.size_row, self.pixels_row, self.opacity_row, self.place_row,
                    self.place_entry):
            self.form.add(row)
        self.form.add(add)
        self.add(self.form)
        self._kind_changed()

    def _kind(self):
        return KINDS[max(0, self.kind_row.get_selected())]

    def _kind_changed(self):
        prop, _, _, control, choices = self._kind()
        self.choice_row.set_visible(control == "choice")
        if control == "choice" and getattr(self, "_choices_for", None) != prop:
            self._choices_for = prop
            self.choice_row.set_model(Gtk.StringList.new([l for l, _ in choices]))
        self.size_row.set_visible(control == "size")
        self.pixels_row.set_visible(control == "size" and SIZES[self.size_row.get_selected()][1] is None)
        self.pixels_row.set_title("Width in pixels" if prop == "default-column-width" else "Height in pixels")
        if self.picked and control == "size":
            size = (self.picked.get("layout") or {}).get("window_size") or []
            if len(size) == 2:
                self.pixels_row.set_value(size[0 if prop == "default-column-width" else 1])
        self.opacity_row.set_visible(control == "opacity")
        names = self.workspaces if control == "workspace" else self.outputs if control == "output" else []
        self.place_row.set_visible(bool(names))
        self.place_entry.set_visible(control in ("workspace", "output") and not names)
        self.place_entry.set_title("Workspace name" if control == "workspace" else "Monitor name")
        if names:
            self.place_row.set_model(Gtk.StringList.new(names))
            self.place_row.set_title("Workspace" if control == "workspace" else "Monitor")

    def _got_workspaces(self, result, _):
        self.workspaces = sorted({w["name"] for w in result or [] if w.get("name")},
                                 key=lambda n: (len(n), n))
        self._kind_changed()

    def _got_outputs(self, result, _):
        self.outputs = sorted((result or {}).keys())
        self._kind_changed()

    #--- Picking a window
    def _pick(self, _):
        self.window.toast("Click the window to make a rule for")
        niri(["pick-window"], self._picked)

    def _picked(self, result, err):
        if err:
            self.window.toast(f"Couldn't pick a window: {err}")
        elif isinstance(result, dict):
            self._use(result)
        self.window.present()

    def _list_windows(self, popover, _):
        if not popover.get_visible():
            return
        self.open_list.remove_all()
        niri(["windows"], self._got_windows)

    def _got_windows(self, result, err):
        if err:
            self.open_list.append(Adw.ActionRow(title="Couldn't list the windows", subtitle=ui.esc(err)))
            return
        own = self.window.get_application().get_application_id()
        for w in sorted(result or [], key=lambda w: ((w.get("app_id") or "").lower(), w.get("title") or "")):
            if w.get("app_id") == own:
                continue
            row = Adw.ActionRow(title=ui.esc(w.get("title") or w.get("app_id") or "Untitled"),
                                subtitle=ui.esc(w.get("app_id") or "no app ID"), activatable=True)
            row.set_title_lines(1)
            image = ui.app_image([f"{w.get('app_id')}.desktop", w.get("app_id") or ""], size=24)
            row.add_prefix(image or Gtk.Image(icon_name="window-new-symbolic"))
            row.niri_window = w
            self.open_list.append(row)

    def _use(self, w):
        self.popover.popdown()
        self.picked = w
        app_id, title = w.get("app_id") or "", w.get("title") or ""
        self.name_row.set_text(app_name(app_id) or app_id or title)
        self.app_row.set_text(regex(app_id) if app_id else "")
        self.title_row.set_text(regex(title) if title else "")
        self.title_switch.set_subtitle(ui.esc(title) if title else "This window has no title")
        self.title_switch.set_active(not app_id)
        self._kind_changed()
        self.window.toast(f"Picked {self.name_row.get_text()}")

    #--- Adding and removing
    def _value(self):
        prop, _, _, control, choices = self._kind()
        if control == "on":
            return True
        if control == "choice":
            return choices[max(0, self.choice_row.get_selected())][1]
        if control == "size":
            value = SIZES[self.size_row.get_selected()][1]
            return {"fixed": int(self.pixels_row.get_value())} if value is None else value
        if control == "opacity":
            return round(self.opacity_row.get_value(), 2)
        names = self.workspaces if control == "workspace" else self.outputs
        if names:
            return names[max(0, self.place_row.get_selected())]
        return self.place_entry.get_text().strip() or None

    def _add(self):
        app_id = self.app_row.get_text().strip()
        title = self.title_row.get_text().strip() if self.title_switch.get_active() else ""
        if not app_id and not title:
            self.window.toast("Pick a window, or type an app ID or title")
            return
        value = self._value()
        if value is None:
            self.window.toast("Type the name it should open on")
            return
        match = {}
        if app_id:
            match["app-id"] = app_id
        if title:
            match["title"] = title
        name = self.name_row.get_text().strip() or app_id or title
        prop = self._kind()[0]
        rules = load(self.path)
        # One rule per window: a second rule type for it joins the first
        rule = next((r for r in rules if r.get("matches") == [match] and not r.get("excludes")), None)
        if rule is None:
            rule = {"name": name, "matches": [match]}
            rules.append(rule)
        else:
            rule["name"] = name
        rule[prop] = value
        if not self._save(rules):
            return
        self.window.toast(f"{property_text(prop, value)} added for {name}")

    def _remove(self, index):
        rules = load(self.path)
        if not 0 <= index < len(rules):
            return
        rule = rules.pop(index)
        if not self._save(rules):
            return
        toast = Adw.Toast(title=GLib.markup_escape_text(f"Removed {rule_title(rule)}"),
                          button_label="Undo", timeout=6)

        def undo(_):
            again = load(self.path)
            again.insert(min(index, len(again)), rule)
            self._save(again)
        toast.connect("button-clicked", undo)
        self.window.toasts.add_toast(toast)

    def _save(self, rules):
        try:
            save(self.path, rules)
        except OSError as e:
            self.window.toast(f"Couldn't save the rules: {e.strerror}")
            return False
        self.dirty = True
        self.refresh()
        return True

    #--- The list
    def refresh(self):
        for g in self.list_groups:
            self.remove(g)
        self.list_groups = []
        added = load(self.path)
        applied = [clean(r) for r in load(APPLIED_FILE)]
        # The applied list holds the added rules too; take each out once
        builtin, waiting = list(applied), False
        for r in added:
            if bare(r) in builtin:
                builtin.remove(bare(r))
            else:
                waiting = True
        self.pending.set_visible(waiting or self.dirty)

        grouped = {g: [] for g, _ in GROUPS}
        for i, r in enumerate(added):
            grouped[group_of(r)].append((r, i))
        for r in builtin:
            grouped[group_of(r)].append((r, None))
        for title, description in GROUPS:
            items = grouped[title]
            if not items:
                continue
            group = Adw.PreferencesGroup(title=ui.esc(f"{title} ({len(items)})"),
                                         description=ui.esc(description))
            for rule, index in items:
                group.add(self._rule_row(rule, index))
            self.add(group)
            self.list_groups.append(group)
        if not added and not builtin:
            group = Adw.PreferencesGroup()
            group.add(Adw.ActionRow(title="No window rules yet",
                                    subtitle="The config's own rules show here after a rebuild."))
            self.add(group)
            self.list_groups.append(group)

    def _rule_row(self, rule, index):
        """One rule: what it does under its name, and the windows it matches."""
        matches, excludes = rule.get("matches") or [], rule.get("excludes") or []
        summary = " · ".join(property_text(k, v) for k, v in properties(rule))
        many = len(matches) + len(excludes) > 1
        if many:
            row = Adw.ExpanderRow(title=ui.esc(rule_title(rule)),
                                  subtitle=ui.esc(f"{summary} · {len(matches)} "
                                                  + ("match" if len(matches) == 1 else "matches")
                                                  + (f", {len(excludes)} left out" if excludes else "")))
            for m in matches:
                row.add_row(Adw.ActionRow(title=ui.esc(match_text(m)), subtitle="Matches"))
            for m in excludes:
                row.add_row(Adw.ActionRow(title=ui.esc(match_text(m)), subtitle="Left out"))
        else:
            where = match_text(matches[0]) if matches else "every window"
            if rule.get("name"):
                summary = f"{summary} · {where}" if summary else where
            row = Adw.ActionRow(title=ui.esc(rule_title(rule)), subtitle=ui.esc(summary))
        row.set_subtitle_lines(3)
        if index is not None:
            row.add_suffix(ui.chip("Added Here", "accent"))
            row.set_tooltip_text("Added on this page; saved in " + RULES_FILE)
            if self.editable:
                remove = Gtk.Button(icon_name="user-trash-symbolic", valign=Gtk.Align.CENTER,
                                    css_classes=["flat"], tooltip_text="Remove this rule")
                remove.connect("clicked", lambda _: self._remove(index))
                row.add_suffix(remove)
        return row


def app_name(app_id):
    """The name an app's .desktop file gives, if it has one under its app ID."""
    if not app_id:
        return ""
    try:
        info = ui.DesktopAppInfo.new(f"{app_id}.desktop")
    except (TypeError, GLib.Error):
        info = None
    return info.get_name() if info else ""
