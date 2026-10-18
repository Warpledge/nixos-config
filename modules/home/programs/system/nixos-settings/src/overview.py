"""The Overview page: what this computer runs, updates, earlier versions it can
switch back to, and shortcuts into the shell's own settings."""

import os

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gio, GLib, Gtk  # noqa: E402

import closure  # noqa: E402
import ui  # noqa: E402

#--- DMS tabs shown as buttons on the Overview, in this order
QUICK = ["display_config", "keybinds", "mouse_touchpad", "theme", "wallpaper", "dankbar_settings",
         "notifications", "network_wifi", "audio"]
HISTORY = 8


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
                                        subtitle=ui.esc(f"From {ui.day(info.updated)} ({ui.ago(info.updated)})"))
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

        #--- Shell settings
        by_tab = {l.tab: l for l in links}
        quick = [by_tab[t] for t in QUICK if t in by_tab]
        if quick:
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
            self.add(group)

        #--- Actions
        group = Adw.PreferencesGroup(title="Maintenance")
        rebuild = Adw.ActionRow(title="Rebuild Now", activatable=True,
                                subtitle="Build and switch to the settings files as they are, "
                                         "for example after editing them by hand")
        rebuild.add_prefix(Gtk.Image(icon_name=ui.first_icon("view-refresh-symbolic"), valign=Gtk.Align.CENTER))
        rebuild.add_suffix(Gtk.Image(icon_name="go-next-symbolic", valign=Gtk.Align.CENTER))
        rebuild.connect("activated", lambda _: window.confirm_rebuild())
        rebuild.set_sensitive(window.admin)
        group.add(rebuild)
        free, total = info.disk
        space = f" {closure.human_size(free)} of {closure.human_size(total)} free now." if free else ""
        collect = Adw.ActionRow(title="Clean Up Old Versions", activatable=True, subtitle_lines=3,
                                subtitle=ui.esc("Garbage collection: deletes old versions and every file "
                                                "only they use, to free disk space." + space))
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
        if GLib.find_program_in_path("gitkraken"):
            git = Adw.ActionRow(title="Manage Git", activatable=True,
                                subtitle="Pull, commit and push the config folder in GitKraken")
            git.add_prefix(Gtk.Image(icon_name=ui.first_icon("gitkraken", "vcs-normal", "folder-remote-symbolic"),
                                     valign=Gtk.Align.CENTER))
            git.add_suffix(Gtk.Image(icon_name=ui.link_icon(), valign=Gtk.Align.CENTER, css_classes=["dim-label"]))
            git.connect("activated", lambda _: self._open_gitkraken())
            group.add(git)
        self.add(group)

        #--- Earlier versions
        gens = info.generations[:HISTORY]
        if gens:
            group = Adw.PreferencesGroup(title="Versions",
                                         description="Each rebuild makes a new version; the boot menu "
                                                     "keeps the last ten. Switching back doesn't change "
                                                     "your settings files, so the next rebuild uses them again.")
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

    def _open_gitkraken(self):
        try:
            Gio.Subprocess.new(["gitkraken", "--path", self.window.cfg.flake], Gio.SubprocessFlags.NONE)
        except GLib.Error as e:
            self.window.toast(f"Couldn't open GitKraken: {e.message}")

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
                              subtitle=ui.esc(", ".join(c.name for c in changes[:6])
                                              + ("…" if len(changes) > 6 else "")))
        for c in changes:
            row = Adw.ActionRow(title=ui.esc(c.name),
                                subtitle=ui.esc(f"{ui.day(c.old)}  →  {ui.day(c.new)}"))
            if c.link:
                button = Gtk.Button(icon_name=ui.link_icon(), css_classes=["flat"], valign=Gtk.Align.CENTER,
                                    tooltip_text="See the changes on GitHub")
                button.connect("clicked", lambda _, url=c.link: ui.open_uri(self.window, url))
                row.add_suffix(button)
            exp.add_row(row)
        self.updates_group.add(exp)
        go = Adw.ButtonRow(title="Update Now", start_icon_name=ui.first_icon("software-update-available-symbolic"),
                           css_classes=["suggested-action"])
        go.connect("activated", lambda _: self.window.confirm_update(new_lock, changes))
        self.updates_group.add(go)
        self.results = [exp, go]
