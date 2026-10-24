"""The Docs tab's Proton pages; what they list is in protonstate.py."""

import os

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gdk, Gio, GLib, Gtk  # noqa: E402

import ui  # noqa: E402
from protonstate import (HOME, OPTIONS, PROTONPLUS, SESSION_PREFIXES, STEAM, TOOL_DIRS,  # noqa: E402
                         WRAPPERS, installed, presets, steam_default)


class ProtonPage(Adw.PreferencesPage):
    def __init__(self, window):
        super().__init__()
        self.window = window

        top = Adw.PreferencesGroup()
        top.add(ui.hero(ui.first_icon("input-gaming-symbolic", "applications-games-symbolic"), "Launch Options",
                        "Launch options for Steam, Heroic and Lutris. Click one to copy it."))
        self.add(top)

        how = Adw.PreferencesGroup(
            title="Where They Go",
            description="In Steam, right-click a game, then Properties, then Launch Options. Variables go "
                        "before %command% and game arguments after it. Heroic and Lutris take variables "
                        "in their environment table and a wrapper in their wrapper field, both without "
                        "%command%.")
        how.add(self._row("PROTON_ENABLE_WAYLAND=0 nix-performance %command% -dx11",
                          "An example with all three, to start from."))
        self.add(how)

        #--- Already set for every game
        session = sorted(f"{k}={v}" for k, v in os.environ.items() if k.startswith(SESSION_PREFIXES))
        if session:
            group = Adw.PreferencesGroup(title="Set for Every Game",
                                         description="Already in this session's environment; a value "
                                                     "in a game's options overrides one.")
            chips = ui.chips_box([ui.chip(s, "neutral") for s in session])
            chips.set_halign(Gtk.Align.START)
            group.add(chips)
            self.add(group)

        #--- This config's wrappers
        rows = [self._row(o, t) for o, needs, t in WRAPPERS if GLib.find_program_in_path(needs)]
        if rows:
            group = Adw.PreferencesGroup(title="This Config's Wrappers",
                                         description="Commands that run the game for you. Anything that "
                                                     "preloads a library goes before them.")
            for r in rows:
                group.add(r)
            self.add(group)

        if GLib.find_program_in_path("nix-vn"):
            group = Adw.PreferencesGroup(
                title="Visual Novels",
                description="nix-vn runs the game in gamescope at its own resolution and upscales it "
                            "to the monitor with NVL; Super+H cycles the filters. Pick the game's "
                            "resolution, not the monitor's.")
            group.add(self._row("nix-vn -r WxH %command%", "Any resolution: replace WxH, like 1366x768."))
            for name, res in presets("nix-vn"):
                group.add(self._row(f"{name} %command%", f"A game made for {res}."))
            self.add(group)

        if GLib.find_program_in_path("nix-rpgm"):
            group = Adw.PreferencesGroup(
                title="RPG Maker",
                description="nix-rpgm reads the engine from the game's folder and upscales it like "
                            "nix-vn. A black screen with sound means the game's window is bigger "
                            "than the resolution used.")
            group.add(self._row("nix-rpgm %command%", "Takes the resolution from the engine (XP, VX, "
                                                       "VX Ace, MV, MZ, 2000 and 2003)."))
            group.add(self._row("nix-rpgm -r WxH %command%", "For a game that resizes its own window: "
                                                              "replace WxH."))
            for name, res in presets("nix-rpgm"):
                group.add(self._row(f"{name} %command%", f"Forces {res}."))
            self.add(group)

        for title, description, options in OPTIONS:
            group = Adw.PreferencesGroup(title=ui.esc(title), description=ui.esc(description))
            for option, text in options:
                group.add(self._row(option, text))
            self.add(group)

    def _row(self, option, text):
        row = Adw.ActionRow(title=f"<tt>{ui.esc(option)}</tt>", subtitle=ui.esc(text), activatable=True,
                            title_lines=2, subtitle_lines=3, tooltip_text="Copy")
        row.add_suffix(Gtk.Image(icon_name="edit-copy-symbolic", valign=Gtk.Align.CENTER,
                                 css_classes=["dim-label"]))
        row.connect("activated", lambda _: self._copy(option))
        return row

    def _copy(self, option):
        Gdk.Display.get_default().get_clipboard().set(option)
        self.window.toast(f"Copied {option}")


class ProtonVersionsPage(Adw.PreferencesPage):
    def __init__(self, window):
        super().__init__()
        self.window = window
        top = Adw.PreferencesGroup()
        protonplus = None
        if GLib.find_program_in_path("protonplus"):
            icon = ui.first_icon(PROTONPLUS, "list-add-symbolic")
            protonplus = Gtk.Button(halign=Gtk.Align.CENTER, margin_top=6,
                                    css_classes=["pill", "suggested-action"],
                                    child=Adw.ButtonContent(icon_name=icon, label="Open ProtonPlus"),
                                    tooltip_text="Install and update Proton and Wine builds")
            protonplus.connect("clicked", lambda _: self._open_protonplus())
        top.add(ui.hero(ui.first_icon("system-software-install-symbolic", "input-gaming-symbolic"),
                        "Proton Versions",
                        "The Proton and Wine builds each launcher can run games with. Pick one per "
                        "game in the launcher, or Steam's default under Settings, Compatibility.",
                        extra=protonplus))
        self.add(top)

        default = steam_default()
        nix = [t for t in os.environ.get("OMNI_SETTINGS_COMPAT_TOOLS", "").split(";") if t]
        if nix:
            group = Adw.PreferencesGroup(title="From This Config",
                                         description="Added to Steam by programs.steam.extraCompatPackages, "
                                                     "and updated with the flake.")
            for tool in nix:
                name, _, version = tool.partition(" ")
                group.add(self._tool_row(version or name, name, None, default))
            self.add(group)

        for launcher, where, folders in TOOL_DIRS:
            tools = installed(folders)
            if launcher == "Steam":
                tools += [(n, p) for n, p in installed([os.path.join(STEAM, "steamapps", "common")])
                          if n.lower().startswith("proton")]
            if not tools and launcher != "Steam":
                continue
            group = Adw.PreferencesGroup(title=launcher, description=where if tools else "")
            if not tools:
                group.add(Adw.ActionRow(title="No builds yet",
                                        subtitle="Steam lists its own Proton once it has downloaded one."))
            for name, path in tools:
                group.add(self._tool_row(name, path.replace(HOME, "~", 1), path, default))
            self.add(group)

    def _tool_row(self, name, subtitle, path, default):
        row = Adw.ActionRow(title=ui.esc(name), subtitle=ui.esc(subtitle), subtitle_lines=1)
        if default and (default == name or (path and default == os.path.basename(path))):
            row.add_suffix(ui.chip("Steam default", "accent"))
        if path:
            button = Gtk.Button(icon_name=ui.first_icon("folder-open-symbolic"), css_classes=["flat"],
                                valign=Gtk.Align.CENTER, tooltip_text="Open its folder")
            button.connect("clicked", lambda _: Gtk.FileLauncher.new(Gio.File.new_for_path(path))
                           .launch(self.window, None, None, None))
            row.add_suffix(button)
        return row

    def _open_protonplus(self):
        try:
            info = ui.DesktopAppInfo.new(f"{PROTONPLUS}.desktop")
        except (TypeError, GLib.Error):
            info = None
        try:
            if info is not None:
                info.launch([], self.window.get_display().get_app_launch_context())
            else:
                Gio.Subprocess.new(["protonplus"], Gio.SubprocessFlags.NONE)
        except GLib.Error as e:
            self.window.toast(f"Couldn't open ProtonPlus: {e.message}")
