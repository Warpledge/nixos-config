"""The Window Rules page (Niri tab): pick an open window, choose what niri does
with it, and the rule is added to modules/wm/niri/home/core/window-rules.json,
which rules.nix turns into niri's window rules; a rebuild applies it. Every
rule in that file can be edited or removed here. The rules that need Nix
(theme colours, the translucent app list, a machine's own rules) are listed
read-only from the copy rules.nix writes to ~/.config/omni-settings/."""

import json
import os

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gio, GLib, Gtk  # noqa: E402

import ui  # noqa: E402
from windowrulestate import (GROUPS, KIND, KINDS, RULES_FILE, SIZES, add_rule, app_name,  # noqa: E402
                             group_of, listing, load, match_pattern, plain, properties, property_text,
                             regex, rule_title, save, size_text, tag_kind, tag_text, window_name)


#--------------------------------------------------------------------#
#-- niri
#--------------------------------------------------------------------#
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


def app_icon(app_id, size):
    """The app's own icon, else the generic app icon at the same size, so every
    row's icon lines up."""
    app = plain(app_id)
    return (app and ui.app_image([f"{app}.desktop", app.lower()], size=size)
            or ui.app_image(["application-x-executable"], size=size)
            or Gtk.Image(icon_name=ui.first_icon("application-x-executable-symbolic"),
                         pixel_size=size))


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
        self.show_ids = False

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
        self.open_list = Gtk.ListBox(selection_mode=Gtk.SelectionMode.NONE, css_classes=["boxed-list"],
                                     margin_start=6, margin_end=6, margin_top=6, margin_bottom=6)
        self.open_list.connect("row-activated", lambda _, row: self._use(row.niri_window))
        # A fixed width, or the rows' wrapping labels shrink the popover to a sliver
        scroll = Gtk.ScrolledWindow(child=self.open_list, propagate_natural_height=True,
                                    max_content_height=480, width_request=460,
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
            row.set_subtitle_lines(1)
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
        add_rule(rules, match, name, prop, value)
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
        rules, from_nix, waiting = listing(self.path)
        self.pending.set_visible(waiting or self.dirty)

        options = Adw.PreferencesGroup(title="Rules", description="Later rules win where two set the same thing.")
        ids = Adw.SwitchRow(title="Show App IDs", active=self.show_ids,
                            subtitle="The patterns each rule matches, as niri reads them")
        ids.connect("notify::active", lambda r, _: self._toggle_ids(r.get_active()))
        options.add(ids)
        self._add_group(options)

        grouped = {g[0]: [] for g in GROUPS}
        for i, r in enumerate(rules):
            if "include" not in r:
                grouped[group_of(r)].append((r, i))
        for title, description, icon, kind in GROUPS:
            items = grouped[title]
            if not items:
                continue
            group = Adw.PreferencesGroup(title=ui.esc(title), description=ui.esc(description),
                                         header_suffix=ui.chip(str(len(items)), kind))
            for rule, index in items:
                group.add(self._rule_row(rule, index))
            self._add_group(group)
        if from_nix:
            group = Adw.PreferencesGroup(title="Set in Nix",
                                         description="Theme styling, the translucent app list and this "
                                                     "computer's own rules. These are edited in the config's "
                                                     "Nix files, not here.",
                                         header_suffix=ui.chip(str(len(from_nix)), "neutral"))
            for rule in from_nix:
                group.add(self._rule_row(rule, None))
            self._add_group(group)

    def _add_group(self, group):
        self.add(group)
        self.list_groups.append(group)

    def _toggle_ids(self, on):
        self.show_ids = on
        GLib.idle_add(lambda: self.refresh() and False)

    def _tags(self, rule):
        """The rule's tags as markup, each coloured by its group."""
        colors = getattr(self.window, "colors", None) or {}
        tags = []
        for prop, value in properties(rule):
            text = ui.esc(tag_text(prop, value))
            color = colors.get(tag_kind(prop))
            if color:
                tags.append(f'<span foreground="{color}" weight="bold">{text}</span>')
            else:
                tags.append(f"<b>{text}</b>")
        return "  ·  ".join(tags)

    def _rule_row(self, rule, index):
        """One rule: its name, what it does as tags, and the windows it matches
        when expanded."""
        matches, excludes = rule.get("matches") or [], rule.get("excludes") or []
        row = Adw.ExpanderRow(title=ui.esc(rule_title(rule)), subtitle=self._tags(rule))
        row.set_subtitle_lines(2)
        one_app = len(matches) == 1 and "app-id" in matches[0]
        row.add_prefix(app_icon(matches[0]["app-id"] if one_app else "", 32))
        if rule.get("note"):
            note = ui.label(rule["note"], ("dim-label",), margin_start=12, margin_end=12, margin_top=8,
                            margin_bottom=8)
            row.add_row(note)
        for m in matches:
            row.add_row(self._match_row(m, "Matches"))
        for m in excludes:
            row.add_row(self._match_row(m, "Left out"))
        if index is not None and self.editable:
            remove = Gtk.Button(icon_name="user-trash-symbolic", valign=Gtk.Align.CENTER,
                                css_classes=["flat"], tooltip_text="Remove this rule")
            remove.connect("clicked", lambda _: self._remove(index))
            row.add_suffix(remove)
            edit = Gtk.Button(icon_name="document-edit-symbolic", valign=Gtk.Align.CENTER,
                              css_classes=["flat"], tooltip_text="Edit this rule")
            edit.connect("clicked", lambda _: self._edit(index))
            row.add_suffix(edit)
        # Suffixes stack leftwards, so the count goes in last to sit leftmost
        count = len(matches)
        if count != 1:
            row.add_suffix(Gtk.Label(label="all windows" if not matches else f"{count} windows",
                                     css_classes=["dim-label", "caption"], valign=Gtk.Align.CENTER))
        return row

    def _match_row(self, match, kind):
        row = Adw.ActionRow(title=ui.esc(window_name(match)), title_lines=1)
        if self.show_ids:
            row.set_subtitle(f"<tt>{ui.esc(match_pattern(match))}</tt>")
        if kind != "Matches":
            row.add_suffix(ui.chip(kind, "warning"))
        row.add_prefix(app_icon(match.get("app-id", ""), 24))
        return row

    def _edit(self, index):
        rules = load(self.path)
        if not 0 <= index < len(rules) or "include" in rules[index]:
            return

        def saved(rule):
            again = load(self.path)
            if 0 <= index < len(again):
                again[index] = rule
                if self._save(again):
                    self.window.toast(f"Saved {rule_title(rule)}")
        RuleDialog(rules[index], self.workspaces, self.outputs, saved).present(self.window)


#--------------------------------------------------------------------#
#-- Editing a rule
#--------------------------------------------------------------------#
class RuleDialog(Adw.Dialog):
    """Edits one rule from window-rules.json: its name and note, the windows it
    matches or leaves out, and what it does. Properties this page has no
    control for are kept as they are, or removed."""

    def __init__(self, rule, workspaces, outputs, on_save):
        super().__init__(title=f"Edit {rule_title(rule)}", content_width=620, content_height=720)
        self.rule, self.on_save = rule, on_save
        self.workspaces, self.outputs = workspaces, outputs
        self.match_rows = {"matches": [], "excludes": []}
        self.props = []  # (prop, getter, rows); getter None once removed

        cancel = Gtk.Button(label="Cancel")
        cancel.connect("clicked", lambda _: self.close())
        save = Gtk.Button(label="Save", css_classes=["suggested-action"])
        save.connect("clicked", lambda _: self._save())
        header = Adw.HeaderBar(show_end_title_buttons=False, show_start_title_buttons=False)
        header.pack_start(cancel)
        header.pack_end(save)
        self.page = Adw.PreferencesPage()
        self.toasts = Adw.ToastOverlay(child=self.page)
        view = Adw.ToolbarView(content=self.toasts)
        view.add_top_bar(header)
        self.set_child(view)

        about = Adw.PreferencesGroup()
        self.name_row = Adw.EntryRow(title="Name", text=rule.get("name", ""))
        self.note_row = Adw.EntryRow(title="Note", text=rule.get("note", ""))
        about.add(self.name_row)
        about.add(self.note_row)
        self.page.add(about)

        self.does = Adw.PreferencesGroup(title="What It Does")
        for prop, value in properties(rule):
            self._prop(prop, value)
        missing = [k for k in KINDS if k[0] not in rule]
        if missing:
            add_row = Adw.ComboRow(title="Add", model=Gtk.StringList.new([k[1] for k in missing]))
            plus = Gtk.Button(icon_name="list-add-symbolic", valign=Gtk.Align.CENTER, css_classes=["flat"],
                              tooltip_text="Add this to the rule")
            plus.connect("clicked", lambda _: self._add_prop(missing, add_row))
            add_row.add_suffix(plus)
            self.add_row = add_row
            self.does.add(add_row)
        self.page.add(self.does)

        for key, title, blurb in (("matches", "Windows", "Regular expressions; a window matching any "
                                                         "entry gets the rule."),
                                  ("excludes", "Left Out", "Windows matching these never get the rule.")):
            group = Adw.PreferencesGroup(title=title, description=blurb)
            plus = Gtk.Button(icon_name="list-add-symbolic", css_classes=["flat"],
                              tooltip_text="Add a window")
            plus.connect("clicked", lambda _, k=key, g=group: self._add_match(k, g, {"app-id": ""}))
            group.set_header_suffix(plus)
            for m in rule.get(key) or []:
                self._add_match(key, group, m)
            self.page.add(group)

    #--- Windows
    def _add_match(self, key, group, match):
        """One match: an app ID row and a title row; other keys are kept."""
        app = Adw.EntryRow(title="App ID", text=match.get("app-id", ""))
        title = Adw.EntryRow(title="Title", text=match.get("title", ""))
        extra = {k: v for k, v in match.items() if k not in ("app-id", "title")}
        remove = Gtk.Button(icon_name="user-trash-symbolic", valign=Gtk.Align.CENTER, css_classes=["flat"],
                            tooltip_text="Remove this window")
        app.add_suffix(remove)
        rows = [app, title]
        if extra:
            rows.append(Adw.ActionRow(title=ui.esc(match_pattern(extra)), subtitle="Kept as it is"))
        for r in rows:
            group.add(r)
        entry = [app, title, extra, rows]
        self.match_rows[key].append(entry)

        def removed(_):
            for r in rows:
                group.remove(r)
            self.match_rows[key].remove(entry)
        remove.connect("clicked", removed)

    def _matches(self, key):
        out = []
        for app, title, extra, _ in self.match_rows[key]:
            m = {}
            if app.get_text().strip():
                m["app-id"] = app.get_text().strip()
            if title.get_text().strip():
                m["title"] = title.get_text().strip()
            m.update(extra)
            if m:
                out.append(m)
        return out

    #--- Properties
    def _add_prop(self, missing, add_row):
        kind = missing[add_row.get_selected()]
        if any(p == kind[0] and g for p, g, _ in self.props):
            return
        default = {"on": True, "choice": kind[4][0][1] if kind[4] else True, "size": {"proportion": 0.5},
                   "opacity": 0.9, "workspace": "", "output": ""}[kind[3]]
        self._prop(kind[0], default, before=add_row)

    def _prop(self, prop, value, before=None):
        kind = KIND.get(prop)
        title = kind[1] if kind else prop.replace("-", " ").capitalize()
        control = kind[3] if kind else ("on" if isinstance(value, bool) else "")
        rows = []
        if control == "choice":
            labels = [l for l, _ in kind[4]]
            values = [v for _, v in kind[4]]
            row = Adw.ComboRow(title=ui.esc(title), model=Gtk.StringList.new(labels),
                               selected=values.index(value) if value in values else 0)
            getter = lambda: values[row.get_selected()]  # noqa: E731
            rows.append(row)
        elif control == "on" or isinstance(value, bool):
            row = Adw.SwitchRow(title=ui.esc(title), active=bool(value))
            getter = row.get_active
            rows.append(row)
        elif control == "size" and isinstance(value, dict):
            labels = [l for l, _ in SIZES]
            index = next((i for i, (_, v) in enumerate(SIZES) if v == value), None)
            if index is None:
                index = labels.index("Pixels")
            row = Adw.ComboRow(title=ui.esc(title), model=Gtk.StringList.new(labels), selected=index)
            px = Adw.SpinRow.new_with_range(50, 8000, 10)
            px.set_title("Pixels")
            px.set_value(value.get("fixed", 800))
            if index == labels.index("Pixels") and "proportion" in value:
                # A proportion this page has no name for: keep it until changed
                px.set_value(800)
                row.set_subtitle(f"Now {size_text(value)}")
            px.set_visible(SIZES[row.get_selected()][1] is None)
            row.connect("notify::selected", lambda *_: px.set_visible(SIZES[row.get_selected()][1] is None))
            original = value

            def getter():
                chosen = SIZES[row.get_selected()][1]
                if chosen is not None:
                    return chosen
                if row.get_subtitle() and "proportion" in original:
                    return original
                return {"fixed": int(px.get_value())}
            px.connect("notify::value", lambda *_: row.set_subtitle(""))
            rows += [row, px]
        elif control == "opacity":
            row = Adw.SpinRow.new_with_range(0.05, 1.0, 0.05)
            row.set_title(title)
            row.set_digits(2)
            row.set_value(float(value))
            getter = lambda: round(row.get_value(), 2)  # noqa: E731
            rows.append(row)
        elif control in ("workspace", "output"):
            names = self.workspaces if control == "workspace" else self.outputs
            row = Adw.EntryRow(title=ui.esc(title), text=str(value))
            if names:
                row.set_tooltip_text("Known now: " + ", ".join(names))
            getter = lambda: row.get_text().strip() or None  # noqa: E731
            rows.append(row)
        else:
            row = Adw.ActionRow(title=ui.esc(title), subtitle=ui.esc(tag_text(prop, value)))
            getter = lambda: value  # noqa: E731
            rows.append(row)
        remove = Gtk.Button(icon_name="user-trash-symbolic", valign=Gtk.Align.CENTER, css_classes=["flat"],
                            tooltip_text="Take this out of the rule")
        rows[0].add_suffix(remove)
        entry = [prop, getter, rows]
        self.props.append(entry)
        for r in rows:
            if before is not None:
                self.does.remove(before)
                self.does.add(r)
                self.does.add(before)
            else:
                self.does.add(r)

        def removed(_):
            for r in rows:
                self.does.remove(r)
            entry[1] = None
        remove.connect("clicked", removed)

    #--- Saving
    def _save(self):
        rule = {}
        name = self.name_row.get_text().strip()
        note = self.note_row.get_text().strip()
        if name:
            rule["name"] = name
        if note:
            rule["note"] = note
        rule["matches"] = self._matches("matches")
        excludes = self._matches("excludes")
        if excludes:
            rule["excludes"] = excludes
        for prop, getter, _ in self.props:
            if getter is None:
                continue
            value = getter()
            if value is None:
                continue
            rule[prop] = value
        if not properties(rule):
            self.toasts.add_toast(Adw.Toast(title="Give the rule something to do, or remove it"))
            return
        self.close()
        self.on_save(rule)


