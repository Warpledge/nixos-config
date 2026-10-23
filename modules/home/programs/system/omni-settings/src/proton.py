"""The Docs tab's Proton pages. Launch Options lists options to copy into a
game's Steam launch options, or Heroic's and Lutris's environment and wrapper
fields; Proton Versions lists the Proton and Wine builds each launcher has. This
config's wrappers come first; the nix-vn and nix-rpgm presets are read off
PATH, as `nixm launch-params` does, so the list follows nix-vn.nix and
nix-rpgm.nix. The variables were checked against the `proton` scripts of
GE-Proton 11-9, dwproton 11.0-14 and Proton-CachyOS."""

import os
import re

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gdk, Gio, GLib, Gtk  # noqa: E402

import ui  # noqa: E402

PROTONPLUS = "com.vysp3r.ProtonPlus"

#--- Variables shown as already set for every game, read off this session
SESSION_PREFIXES = ("PROTON_", "DXVK_", "VKD3D_", "WINE", "MANGOHUD", "ENABLE_LAYER_", "SDL_VIDEODRIVER")

#--- (option, the command it needs on PATH, what it does)
WRAPPERS = [
    ("nix-performance %command%", "nix-performance",
     "GameMode, MangoHud and the newest FSR 4 (AMD) or DLSS (NVIDIA). Leaves out Steam's "
     "overlay, which in-game purchases need."),
    ("nix-gamescope %command%", "nix-gamescope",
     "Fullscreen in gamescope at the monitor's resolution and refresh rate, with "
     "nix-performance inside."),
    ("nix-gamescope --mangoapp -- %command%", "nix-gamescope",
     "The same with gamescope's own FPS overlay, which replaces MangoHud there."),
    ("nix-gamescope -w 1920 -h 1080 -F fsr -- %command%", "nix-gamescope",
     "Renders at 1080p and upscales to the monitor with FSR 1. Flags before -- override the "
     "detected ones."),
    ("nix-gamescope -r 60 -- %command%", "nix-gamescope", "Caps the game at 60 frames a second."),
    ("nix-gamescope --force-grab-cursor -- %command%", "nix-gamescope",
     "Locks the pointer inside the game, for mouse-look that escapes the window."),
    ("tml-prelaunch && DOTNET_DefaultStackSize=51200000 gamemoderun %command%", "tml-prelaunch",
     "tModLoader with the bigger stack and the server garbage collector big modpacks need."),
]

#--- (group, description, [(option, what it does)]). Variables go before
#--- %command% (or in the launcher's environment table), arguments after it.
OPTIONS = [
    ("Proton", "Valve's own Proton reads PROTON_USE_WINED3D, PROTON_NO_D3D11, PROTON_NO_FSYNC and "
               "PROTON_LOG; the rest need GE, DW or CachyOS Proton.", [
        ("PROTON_ENABLE_WAYLAND=0", "XWayland instead of Wine's Wayland driver, which this config turns "
                                    "on for every game. Fixes white or split login windows and some crashes."),
        ("PROTON_USE_WINED3D=1", "OpenGL instead of Vulkan for Direct3D 9 to 11: slower, but old games "
                                 "that crash or stay black under DXVK often work."),
        ("PROTON_NO_D3D11=1", "Hides Direct3D 11, for games that run better on their Direct3D 9 path."),
        ("PROTON_NO_FSYNC=1", "Turns off fsync, to rule it out when a game crashes or hangs at random."),
        ("PROTON_NO_ESYNC=1", "GE and DW Proton: turns off esync, the same check."),
        ("PROTON_NO_NTSYNC=1", "GE-Proton: turns off NTSync, which it uses whenever the kernel has it."),
        ("PROTON_PREFER_SDL=1", "Reads controllers through SDL instead of Steam Input, for a pad that "
                                "isn't found or acts twice."),
        ("PROTON_LOG=1", "Writes steam-<game id>.log to your home folder, for troubleshooting."),
    ]),
    ("Upscaling", "GE, DW and CachyOS Proton only.", [
        ("PROTON_FSR4_UPGRADE=1", "Swaps in the newest FSR 4 for RX 9000 cards. This config turns it on "
                                  "for every game; =0 turns it off, a version number pins one."),
        ("PROTON_FSR4_INDICATOR=1", "Shows FSR 4's watermark, to check it's working."),
        ("PROTON_DLSS_UPGRADE=1", "Swaps in the newest DLSS on NVIDIA cards."),
        ("PROTON_DLSS_INDICATOR=1", "Shows DLSS's on-screen indicator."),
        ("PROTON_XESS_UPGRADE=1", "Swaps in the newest XeSS. On for every game here already."),
    ]),
    ("Graphics & Performance", "", [
        ("ENABLE_LAYER_MESA_ANTI_LAG=1", "Mesa's Anti-Lag on AMD: less input lag when the graphics card "
                                         "is the bottleneck."),
        ('DXVK_CONFIG="dxgi.maxFrameRate=60"', "Caps the frame rate of Direct3D 10 and 11 games; edit "
                                               "the number."),
        ("VKD3D_FRAME_RATE=60", "Caps the frame rate of DirectX 12 games."),
        ("DXVK_HUD=fps", "DXVK's own frame counter. This config shows its shader compiling (compiler) "
                         "for every game."),
        ("MANGOHUD=1", "The MangoHud overlay in Vulkan and DXVK games."),
        ("gamemoderun %command%", "GameMode alone: the performance governor and a higher priority."),
        ("mangohud %command%", "MangoHud alone, OpenGL games included."),
    ]),
    ("Compatibility", "", [
        ("LANG=ja_JP.UTF-8", "Japanese locale, for Japanese games and visual novels that show garbled text."),
        ("STEAMDECK=1 SteamOS=1", "Tells the game it runs on a Steam Deck, which some need to start or "
                                  "log in under Proton."),
        ("PULSE_LATENCY_MSEC=60", "A bigger audio buffer, for crackling sound."),
        ("env -u WAYLAND_DISPLAY %command%", "Hides Wayland from a native game or launcher, so it runs "
                                             "on XWayland."),
        ("SDL_VIDEODRIVER=x11", "Native SDL games on XWayland, for ones that misbehave on Wayland."),
    ]),
    ("Game Arguments", "These go after %command%; each engine reads its own.", [
        ("-dx11", "Unreal and many other engines: Direct3D 11, often steadier under Proton than 12."),
        ("-dx12", "Unreal: Direct3D 12, which some games need for ray tracing."),
        ("-vulkan", "Unreal: Vulkan."),
        ("-force-d3d11", "Unity: Direct3D 11."),
        ("-force-vulkan", "Unity: Vulkan."),
        ("-popupwindow", "Unity: a borderless window."),
        ("--no-sandbox", "RPG Maker MV and MZ, and other NW.js games, that hang on a black screen."),
        ("--in-process-gpu", "RPG Maker MV and MZ: for crashes in the GPU process."),
    ]),
]

RES = re.compile(r"-r (\d+)x(\d+)")


def presets(command):
    """[(name, "WxH")] for the `command`-<suffix> presets on PATH, smallest first."""
    found = {}
    for d in os.environ.get("PATH", "").split(":"):
        try:
            names = os.listdir(d)
        except OSError:
            continue
        for name in names:
            path = os.path.join(d, name)
            if not name.startswith(command + "-") or name in found or not os.access(path, os.X_OK):
                continue
            try:
                with open(path, errors="replace") as f:
                    m = RES.search(f.read(4096))
            except OSError:
                continue
            if m:
                found[name] = (int(m.group(1)), int(m.group(2)))
    return [(n, f"{w}x{h}") for n, (w, h) in sorted(found.items(), key=lambda i: i[1])]


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


#--------------------------------------------------------------------#
#-- Proton Versions
#--------------------------------------------------------------------#
HOME = os.path.expanduser("~")
STEAM = os.path.join(HOME, ".local", "share", "Steam")
#--- (launcher, what it calls them, folders each build is a subfolder of)
TOOL_DIRS = [
    ("Steam", "Added by hand or by ProtonPlus",
     [os.path.join(HOME, ".steam", "root", "compatibilitytools.d"),
      os.path.join(STEAM, "compatibilitytools.d")]),
    ("Heroic", "Heroic's own downloads",
     [os.path.join(HOME, ".config", "heroic", "tools", "proton"),
      os.path.join(HOME, ".config", "heroic", "tools", "wine")]),
    ("Lutris", "Lutris's own downloads",
     [os.path.join(HOME, ".local", "share", "lutris", "runners", "proton"),
      os.path.join(HOME, ".local", "share", "lutris", "runners", "wine")]),
]
DEFAULT_TOOL = re.compile(r'"CompatToolMapping"\s*\{\s*"0"\s*\{\s*"name"\s*"([^"]*)"')
DISPLAY_NAME = re.compile(r'"display_name"\s*"([^"]*)"')


def installed(folders):
    """[(name, folder)] for the builds in `folders`, newest name first."""
    seen, out = set(), []
    for folder in folders:
        try:
            names = os.listdir(folder)
        except OSError:
            continue
        for name in names:
            path = os.path.join(folder, name)
            real = os.path.realpath(path)
            if real in seen or not os.path.isdir(path) or name.startswith("."):
                continue
            seen.add(real)
            out.append((display_name(path) or name, path))
    return sorted(out, key=lambda t: t[0].lower(), reverse=True)


def display_name(path):
    try:
        with open(os.path.join(path, "compatibilitytool.vdf"), errors="replace") as f:
            m = DISPLAY_NAME.search(f.read())
        return m.group(1) if m else None
    except OSError:
        return None


def steam_default():
    """The internal name of the build Steam runs every game with, or None."""
    try:
        with open(os.path.join(STEAM, "config", "config.vdf"), errors="replace") as f:
            m = DEFAULT_TOOL.search(f.read())
        return m.group(1) or None if m else None
    except OSError:
        return None


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
