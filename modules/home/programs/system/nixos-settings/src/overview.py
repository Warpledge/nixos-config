"""The Overview page: what this computer runs, updates, earlier versions it can
switch back to, and shortcuts into the shell's own settings."""

import os

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gdk, Gtk  # noqa: E402

import closure  # noqa: E402
import runview  # noqa: E402
import ui  # noqa: E402

#--- DMS tabs shown as buttons on the Overview, in this order
QUICK = ["display_config", "keybinds", "mouse_touchpad", "theme", "wallpaper", "dankbar_settings",
         "notifications", "network_wifi", "audio"]
HISTORY = 8


def quick_links(window, links):
    """Buttons for the DMS settings tabs in QUICK, or None when DMS has none."""
    by_tab = {l.tab: l for l in links}
    quick = [by_tab[t] for t in QUICK if t in by_tab]
    if not quick:
        return None
    group = Adw.PreferencesGroup(title="Shell Settings",
                                 description="Open DankMaterialShell's settings on one page.")
    wrap = Adw.WrapBox(child_spacing=10, line_spacing=10)
    for link in quick:
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        box.append(Gtk.Image(icon_name=ui.first_icon(link.icon), pixel_size=24))
        box.append(Gtk.Label(label=link.title, wrap=True, justify=Gtk.Justification.CENTER,
                             max_width_chars=14))
        button = Gtk.Button(child=box, css_classes=["card", "quick-link"],
                            tooltip_text=link.subtitle)
        button.connect("clicked", lambda _, l=link: window.open_dms(l))
        wrap.append(button)
    group.add(wrap)
    return group


class ShellPage(Adw.PreferencesPage):
    """The Niri tab's start page: DankMaterialShell's settings in one place."""
    def __init__(self, window, links):
        super().__init__()
        top = Adw.PreferencesGroup()
        top.add(ui.hero(ui.first_icon("view-app-grid-symbolic"), "Shell",
                        "DankMaterialShell, the bar, launcher and lock screen niri runs with. "
                        "The pages below hold the rest of its settings."))
        self.add(top)
        group = quick_links(window, links)
        if group:
            self.add(group)


class Overview(Adw.PreferencesPage):
    def __init__(self, window, info, wm, links):
        super().__init__()
        self.window = window
        self.info = info
        self.updates = None

        #--- Hero
        chips = [ui.chip(wm.capitalize() if wm != "niri" else "niri", "accent"),
                 ui.chip(f"Linux {info.kernel}", "neutral")]
        if info.generation:
            chips.append(ui.chip(f"Version {info.generation}", "neutral"))
        logo = Gtk.Image(icon_name=ui.first_icon("distributor-logo-nixos", "nix-snowflake",
                                                 "computer-symbolic"), pixel_size=96)
        top = Adw.PreferencesGroup()
        top.add(ui.hero(logo, info.hostname, info.pretty, symbolic=False, extra=ui.chips_box(chips)))
        self.add(top)

        #--- Waiting for a restart
        if info.pending or info.new_kernel:
            group = Adw.PreferencesGroup()
            if info.pending:
                title, sub = "Restart to finish", f"Version {info.pending} starts the next time you restart."
            else:
                title, sub = "Restart to use the new kernel", f"Linux {info.new_kernel} is installed."
            row = Adw.ActionRow(title=title, subtitle=ui.esc(sub))
            row.add_prefix(Gtk.Image(icon_name=ui.first_icon("system-reboot-symbolic"),
                                     css_classes=["accent"], valign=Gtk.Align.CENTER))
            button = Gtk.Button(label="Restart", valign=Gtk.Align.CENTER, css_classes=["suggested-action"])
            button.connect("clicked", lambda _: window.restart())
            row.add_suffix(button)
            group.add(row)
            self.add(group)

        #--- Updates
        self.updates_group = Adw.PreferencesGroup(title="Updates")
        self.status_row = Adw.ActionRow(title="Sources",
                                        subtitle=ui.esc(f"Flake inputs, locked {ui.day(info.updated)} "
                                                        f"({ui.ago(info.updated)})"))
        self.status_row.add_prefix(Gtk.Image(icon_name=ui.first_icon("software-update-available-symbolic",
                                                                     "emblem-synchronizing-symbolic"),
                                             valign=Gtk.Align.CENTER))
        self.check_button = Gtk.Button(label="Check for Updates", valign=Gtk.Align.CENTER)
        self.check_button.connect("clicked", lambda _: self.check())
        self.check_spinner = Adw.Spinner(visible=False, valign=Gtk.Align.CENTER)
        self.status_row.add_suffix(self.check_spinner)
        self.status_row.add_suffix(self.check_button)
        self.updates_group.add(self.status_row)
        self.results = []
        if not window.admin:
            self.check_button.set_sensitive(False)
            self.check_button.set_tooltip_text("Only an admin can update this computer")
        self.add(self.updates_group)

        #--- Actions
        group = Adw.PreferencesGroup(title="Maintenance")
        rebuild = Adw.ActionRow(title="Rebuild Now", activatable=True,
                                subtitle="nixos-rebuild switch on your settings files as they are, "
                                         "for example after editing them by hand")
        rebuild.add_prefix(Gtk.Image(icon_name=ui.first_icon("view-refresh-symbolic"), valign=Gtk.Align.CENTER))
        rebuild.add_suffix(Gtk.Image(icon_name="go-next-symbolic", valign=Gtk.Align.CENTER))
        rebuild.connect("activated", lambda _: window.confirm_rebuild())
        rebuild.set_sensitive(window.admin)
        group.add(rebuild)
        free, total = info.disk
        space = f" {closure.human_size(free)} of {closure.human_size(total)} free now." if free else ""
        collect = Adw.ActionRow(title="Clean Up Old Versions", activatable=True, subtitle_lines=3,
                                subtitle=ui.esc("Garbage collection: deletes old generations and the store "
                                                "files only they use." + space))
        collect.add_prefix(Gtk.Image(icon_name=ui.first_icon("user-trash-symbolic"), valign=Gtk.Align.CENTER))
        collect.add_suffix(Gtk.Image(icon_name="go-next-symbolic", valign=Gtk.Align.CENTER))
        collect.connect("activated", lambda _: window.confirm_collect())
        collect.set_sensitive(window.admin)
        group.add(collect)
        folder = Adw.ActionRow(title="Open the Config Folder", activatable=True,
                               subtitle=ui.esc(window.cfg.flake))
        folder.add_prefix(Gtk.Image(icon_name=ui.first_icon("folder-open-symbolic"), valign=Gtk.Align.CENTER))
        folder.add_suffix(Gtk.Image(icon_name=ui.link_icon(), valign=Gtk.Align.CENTER, css_classes=["dim-label"]))
        folder.connect("activated", lambda _: window.open_folder())
        group.add(folder)
        failed = runview.last_failed()
        if failed:
            title, when, heading, _, _ = failed
            row = Adw.ActionRow(title="Last Failed Run", activatable=True, subtitle_lines=2,
                                subtitle=ui.esc(f"{title}, {ui.when(when).lower()}: {heading}"))
            row.add_prefix(Gtk.Image(icon_name=ui.first_icon("dialog-warning-symbolic"), valign=Gtk.Align.CENTER,
                                     css_classes=["warning"]))
            row.add_suffix(Gtk.Image(icon_name="go-next-symbolic", valign=Gtk.Align.CENTER))
            row.connect("activated", lambda _: self._show_failed(row))
            group.add(row)
        self.add(group)

        #--- Shell settings; under niri they're on the Niri tab's Shell page
        if wm != "niri":
            group = quick_links(window, links)
            if group:
                self.add(group)

        #--- Earlier versions
        gens = info.generations[:HISTORY]
        if gens:
            group = Adw.PreferencesGroup(title="Versions",
                                         description="Generations: each rebuild saves one, and the boot menu "
                                                     "keeps the last ten. Switching back leaves your settings "
                                                     "files as they are.")
            running_path = os.path.realpath(closure.CURRENT)
            booted_path = os.path.realpath(closure.BOOTED)
            default_path = os.path.realpath(closure.SYSTEM_PROFILE)
            for g in gens:
                parts = [ui.when(g.when)]
                if g.version:
                    parts.append(f"NixOS {g.version.split('.')[0]}.{g.version.split('.')[1]}"
                                 if g.version.count(".") >= 2 else f"NixOS {g.version}")
                if g.kernel:
                    parts.append(f"Linux {g.kernel}")
                row = Adw.ActionRow(title=f"Version {g.number}", subtitle=ui.esc(" · ".join(parts)))
                tags = Gtk.Box(spacing=6, valign=Gtk.Align.CENTER)
                if g.path == running_path:
                    tags.append(ui.chip("Running", "success"))
                if g.path == default_path and g.path != running_path:
                    tags.append(ui.chip("Next start", "accent"))
                if g.path == booted_path and g.path != running_path:
                    tags.append(ui.chip("Started with", "neutral"))
                row.add_suffix(tags)
                if g.path != running_path:
                    compare = Gtk.Button(icon_name=ui.first_icon("view-dual-symbolic", "edit-find-symbolic"),
                                         css_classes=["flat"], valign=Gtk.Align.CENTER,
                                         tooltip_text="What's different from the running version")
                    compare.connect("clicked", lambda _, g=g: window.compare_version(g))
                    row.add_suffix(compare)
                    use = Gtk.Button(label="Switch", valign=Gtk.Align.CENTER, sensitive=window.admin,
                                     tooltip_text="Switch to this version" if window.admin
                                     else "Only an admin can switch versions")
                    use.connect("clicked", lambda _, g=g: window.confirm_rollback(g))
                    row.add_suffix(use)
                group.add(row)
            self.add(group)

    def _show_failed(self, row):
        failed = runview.last_failed()
        if not failed:
            return
        title, when, heading, reason, log = failed
        dialog = Adw.Dialog(title="Last Failed Run", content_width=640, content_height=640)
        page = Adw.PreferencesPage()
        top = Adw.PreferencesGroup(title=ui.esc(heading),
                                   description=ui.esc(f"{title}, {ui.when(when).lower()}. {reason}"))
        page.add(top)
        group = Adw.PreferencesGroup(title="Log")
        text = Gtk.TextView(editable=False, cursor_visible=False, monospace=True, top_margin=10,
                            bottom_margin=10, left_margin=12, right_margin=12,
                            wrap_mode=Gtk.WrapMode.WORD_CHAR, css_classes=["log-view"])
        text.get_buffer().set_text(log)
        scroll = Gtk.ScrolledWindow(child=text, min_content_height=320, css_classes=["card"],
                                    hscrollbar_policy=Gtk.PolicyType.NEVER)
        group.add(scroll)
        copy = Gtk.Button(icon_name="edit-copy-symbolic", css_classes=["flat"], tooltip_text="Copy the log")
        copy.connect("clicked", lambda _: (Gdk.Display.get_default().get_clipboard().set(log),
                                           self.window.toast("Log copied")))
        group.set_header_suffix(copy)
        page.add(group)
        forget = Gtk.Button(label="Forget It", css_classes=["destructive-action"])

        def forgotten(_):
            try:
                os.remove(runview.FAILED_LOG)
            except OSError:
                pass
            row.set_visible(False)
            dialog.close()
        forget.connect("clicked", forgotten)
        bar = Gtk.ActionBar()
        bar.pack_end(forget)
        view = Adw.ToolbarView(content=page)
        view.add_top_bar(Adw.HeaderBar())
        view.add_bottom_bar(bar)
        dialog.set_child(view)
        dialog.present(self.window)

    #--------------------------------------------------------------------#
    #-- Update check
    #--------------------------------------------------------------------#
    def check(self):
        self.check_button.set_visible(False)
        self.check_spinner.set_visible(True)
        self.status_row.set_subtitle("Looking up the newest version of each source; "
                                     "this takes about half a minute.")
        for row in self.results:
            self.updates_group.remove(row)
        self.results = []
        self.window.check_updates(self._checked)

    def _checked(self, result, error):
        self.check_spinner.set_visible(False)
        self.check_button.set_visible(True)
        self.check_button.set_label("Check Again")
        info = self.info
        if error is not None:
            self.status_row.set_subtitle(ui.esc(f"Couldn't check: {error}"))
            return
        new_lock, changes = result
        if not changes:
            self.status_row.set_subtitle(ui.esc(f"Up to date. Sources from {ui.day(info.updated)}."))
            return
        newest = max(c.new for c in changes)
        self.status_row.set_subtitle(ui.esc(f"{len(changes)} of this config's sources have newer "
                                            f"versions, up to {ui.day(newest)}."))
        exp = Adw.ExpanderRow(title=f"What's New ({len(changes)})",
                              subtitle=ui.esc("Untick a source to leave it as it is. "
                                              + ", ".join(c.name for c in changes[:6])
                                              + ("…" if len(changes) > 6 else "")), subtitle_lines=2)
        picks = {}
        go = Adw.ButtonRow(title="Update Now", start_icon_name=ui.first_icon("software-update-available-symbolic"),
                           css_classes=["suggested-action"])

        def picked(*_):
            n = sum(1 for check in picks.values() if check.get_active())
            go.set_title("Update Now" if n == len(changes) else f"Update {n} of {len(changes)}")
            go.set_sensitive(n > 0)
        for c in changes:
            row = Adw.ActionRow(title=ui.esc(c.name), activatable=True,
                                subtitle=ui.esc(f"{ui.day(c.old)}  →  {ui.day(c.new)}"))
            check = Gtk.CheckButton(active=True, valign=Gtk.Align.CENTER)
            check.connect("toggled", picked)
            row.add_prefix(check)
            row.set_activatable_widget(check)
            picks[c.name] = check
            if c.link:
                button = Gtk.Button(icon_name=ui.link_icon(), css_classes=["flat"], valign=Gtk.Align.CENTER,
                                    tooltip_text="See the changes on GitHub")
                button.connect("clicked", lambda _, url=c.link: ui.open_uri(self.window, url))
                row.add_suffix(button)
            exp.add_row(row)
        self.updates_group.add(exp)
        go.connect("activated", lambda _: self.window.confirm_update(
            new_lock, changes, [n for n, check in picks.items() if check.get_active()]))
        self.updates_group.add(go)
        self.results = [exp, go]
