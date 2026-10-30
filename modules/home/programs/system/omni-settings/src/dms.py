"""DankMaterialShell's own settings: which of its settings tabs the app links to
and on which page, and DMS's search index, so the app's search finds DMS
settings too. Links run `dms ipc call settings openWith <tab>`; DMS always
opens its full settings window, on that tab."""

import json
import os
import re
import shutil
from dataclasses import dataclass


@dataclass
class Link:
    tab: str  # tab id, from `dms ipc call settings tabs`
    title: str
    subtitle: str
    page: str  # the app page and group it shows in
    group: str
    icon: str
    needs: str = ""  # niri, printing or battery: shown only then


#--- Left out: Default Apps (mimeapps.list is the config's), Users, Greeter and
#--- System Updater (Omni Settings and the config own those). Mouse & Touchpad
#--- and Keyboard write niri/dms/input.kdl, which only niri loads.
LINKS = [
    Link("display_config", "Monitors", "Resolution, refresh rate, scale and arrangement",
         "Displays", "", "video-display-symbolic", "niri"),
    Link("display_gamma", "Night Light", "Warmer colors in the evening, plus gamma and contrast",
         "Displays", "", "night-light-symbolic"),
    Link("display_widgets", "Bars per Monitor", "Which bar and widgets each screen shows",
         "Displays", "", "view-grid-symbolic"),
    Link("keybinds", "Keyboard Shortcuts", "Add or change shortcuts; yours win over the config's",
         "Input & Sound", "Keyboard", "preferences-desktop-keyboard-shortcuts-symbolic", "niri"),
    Link("keyboard", "Keyboard", "Key repeat, Num Lock and more layouts to switch between",
         "Input & Sound", "Keyboard", "input-keyboard-symbolic", "niri"),
    Link("locale", "Shell Language", "The language and date format the shell uses",
         "Input & Sound", "Keyboard", "preferences-desktop-locale-symbolic"),
    Link("mouse_touchpad", "Mouse & Touchpad", "Pointer speed, acceleration, scrolling and tap to click",
         "Input & Sound", "Mouse & Touchpad", "input-mouse-symbolic", "niri"),
    Link("theme", "Theme & Colors", "Corner radius, transparency and blur. The color theme, fonts, "
         "icons and pointer come from this config and reset on rebuild",
         "Appearance", "Shell Look", "preferences-desktop-theme-symbolic"),
    Link("typography", "Text & Motion", "Font scale and weight, animation speed",
         "Appearance", "Shell Look", "preferences-desktop-font-symbolic"),
    Link("wallpaper", "Wallpaper Options", "Fill mode, transitions and a wallpaper per monitor",
         "Appearance", "Wallpaper", "preferences-desktop-wallpaper-symbolic"),
    Link("audio", "Sound Devices", "Output and input devices", "Input & Sound", "Sound",
         "audio-speakers-symbolic"),
    Link("sounds", "System Sounds", "Sounds for login, notifications and volume changes",
         "Input & Sound", "Sound", "audio-volume-high-symbolic"),
    Link("printers", "Printers", "Add and manage printers", "Input & Sound", "Printers",
         "printer-symbolic", "printing"),
    Link("network_wifi", "Wi-Fi", "Networks, saved passwords and hotspot",
         "Connections", "Networks", "network-wireless-symbolic"),
    Link("network_ethernet", "Ethernet", "Wired connections", "Connections", "Networks",
         "network-wired-symbolic"),
    Link("network_vpn", "VPN Connections", "WireGuard and OpenVPN profiles kept by NetworkManager",
         "Connections", "Networks", "network-vpn-symbolic"),
    Link("network_status", "Network Status", "Connections, addresses and speeds",
         "Connections", "Networks", "network-workgroup-symbolic"),
    Link("dankbar_settings", "Bar", "Position, size and auto-hide", "Desktop Shell", "Bar",
         "view-continuous-symbolic"),
    Link("dankbar_widgets", "Bar Widgets", "What the bar shows, and in what order",
         "Desktop Shell", "Bar", "view-app-grid-symbolic"),
    Link("dankbar_appearance", "Bar Appearance", "Transparency, corners, spacing and icon size",
         "Desktop Shell", "Bar", "applications-graphics-symbolic"),
    Link("workspaces", "Workspaces", "The workspace indicator and the app icons in it",
         "Desktop Shell", "Bar", "view-paged-symbolic"),
    Link("dock", "Dock", "Pinned apps, position and auto-hide", "Desktop Shell", "Dock & Launcher",
         "view-more-horizontal-symbolic"),
    Link("launcher", "App Launcher", "Layout, hidden apps and what search covers",
         "Desktop Shell", "Dock & Launcher", "system-search-symbolic"),
    Link("notifications", "Notifications", "Do Not Disturb, timeouts and history",
         "Desktop Shell", "Notifications", "preferences-system-notifications-symbolic"),
    Link("osd", "On-Screen Pop-ups", "Volume, brightness and Caps Lock indicators",
         "Desktop Shell", "Notifications", "dialog-information-symbolic"),
    Link("time_weather", "Clock & Weather", "Time and date format, weather location and units",
         "Desktop Shell", "Widgets", "preferences-system-time-symbolic"),
    Link("desktop_widgets", "Desktop Widgets", "Widgets drawn on the wallpaper",
         "Desktop Shell", "Widgets", "view-grid-symbolic"),
    Link("dank_dash", "Dashboard", "The panel of widgets from the bar", "Desktop Shell", "Widgets",
         "view-dual-symbolic"),
    Link("media_player", "Media Player", "The now-playing widget and its visualizer",
         "Desktop Shell", "Widgets", "multimedia-player-symbolic"),
    Link("clipboard", "Clipboard History", "How much it keeps and how pasting works",
         "Desktop Shell", "Widgets", "edit-paste-symbolic"),
    Link("compositor_layout", "Window Gaps & Borders", "Gaps, borders and rounded window corners",
         "Desktop Shell", "Windows", "focus-windows-symbolic"),
    Link("window_rules", "Window Rules", "How particular apps' windows open",
         "Desktop Shell", "Windows", "preferences-system-windows-symbolic"),
    Link("autostart", "Autostart", "Apps that start when you log in", "Desktop Shell", "Windows",
         "system-run-symbolic"),
    Link("running_apps", "Running App Names", "How the bar names and groups running apps",
         "Desktop Shell", "Windows", "application-x-executable-symbolic"),
    Link("multiplexers", "Terminal Sessions", "tmux and zellij sessions in the launcher",
         "Desktop Shell", "Windows", "utilities-terminal-symbolic"),
    Link("frame", "Screen Frame", "A border joining the bar and dock round the screen edges",
         "Desktop Shell", "Extras", "view-fullscreen-symbolic"),
    Link("dank_island", "Island", "A pill at the screen edge for the clock and notifications",
         "Desktop Shell", "Extras", "view-pin-symbolic"),
    Link("plugins", "Plugins", "Add and set up shell plugins", "Desktop Shell", "Extras",
         "application-x-addon-symbolic"),
    Link("power_sleep", "Power & Sleep", "When to lock, turn screens off and suspend",
         "Power & Lock", "", "system-shutdown-symbolic"),
    Link("lock_screen", "Lock Screen", "Clock, layout, notifications and unlock options",
         "Power & Lock", "", "system-lock-screen-symbolic"),
    Link("battery", "Battery", "Charge limit, low-battery alerts and power profiles",
         "Power & Lock", "", "battery-good-symbolic", "battery"),
]

#--- SettingsTabs.qml's tabIndex for each tab (DMS 1.6), for a DMS whose file
#--- can't be read; tab_indexes() reads the installed one
TAB_INDEX = {
    "wallpaper": 0, "time_weather": 1, "keybinds": 2, "dankbar_settings": 3, "workspaces": 4,
    "dock": 5, "dankbar_appearance": 6, "network_status": 7, "printers": 8, "launcher": 9,
    "theme": 10, "lock_screen": 11, "plugins": 12, "about": 13, "typography": 14, "sounds": 15,
    "media_player": 16, "notifications": 17, "osd": 18, "running_apps": 19, "updater": 20,
    "power_sleep": 21, "dankbar_widgets": 22, "clipboard": 23, "display_config": 24,
    "display_gamma": 25, "display_widgets": 26, "desktop_widgets": 27, "audio": 29, "locale": 30,
    "greeter": 31, "multiplexers": 32, "frame": 33, "default_apps": 34, "users": 35,
    "autostart": 36, "compositor_layout": 37, "window_rules": 38, "network_ethernet": 39,
    "network_wifi": 40, "network_vpn": 41, "battery": 42, "dank_dash": 43, "mouse_touchpad": 44,
    "keyboard": 45, "dank_island": 46, "network_cellular": 47,
}
TAB_ENTRY = re.compile(r'"id":\s*"([a-z_]+)"(?:(?!"id":).)*?"tabIndex":\s*(\d+)', re.S)


def binary():
    return shutil.which("dms")


def share():
    """DMS's QML folder, found from the `dms` command."""
    path = binary()
    if not path:
        return None
    root = os.path.join(os.path.dirname(os.path.dirname(os.path.realpath(path))), "share", "quickshell", "dms")
    return root if os.path.isdir(root) else None


def tab_indexes(root):
    try:
        with open(os.path.join(root, "Common", "SettingsTabs.qml")) as f:
            found = {tab: int(i) for tab, i in TAB_ENTRY.findall(f.read())}
    except OSError:
        found = {}
    return found or TAB_INDEX


def links(wm, printing, battery):
    """The links that apply here."""
    ok = {"": True, "niri": wm == "niri", "printing": printing, "battery": battery}
    return [l for l in LINKS if ok.get(l.needs, True)]


@dataclass
class Entry:
    label: str
    description: str
    keywords: str
    link: Link


def search_index(shown, wm):
    """DMS's own settings search index, for the tabs in `shown` (links)."""
    root = share()
    if root is None:
        return []
    try:
        with open(os.path.join(root, "translations", "settings_search_index.json")) as f:
            data = json.load(f)
    except (OSError, ValueError):
        return []
    by_index = {i: tab for tab, i in tab_indexes(root).items()}
    by_tab = {l.tab: l for l in shown}
    skip = {"isNiri": wm != "niri", "isHyprland": wm != "hyprland", "isMango": True,
            "isHyprlandOrNiri": wm not in ("niri", "hyprland"), "greeterAvailable": True}
    out = []
    for e in data if isinstance(data, list) else []:
        link = by_tab.get(by_index.get(e.get("tabIndex")))
        if link is None or skip.get(e.get("conditionKey"), False):
            continue
        label = str(e.get("label", "")).replace("%1", "").strip()
        if not label or label == link.title:
            continue
        out.append(Entry(label, str(e.get("description", "")), " ".join(e.get("keywords", [])), link))
    return out
