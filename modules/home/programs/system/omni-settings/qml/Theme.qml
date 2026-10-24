// Colours from DMS's matugen file, glyphs for the backend's icon names
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: theme

    property var c: ({})

    //--- Catppuccin Mocha Mauve, until DMS has written its colours
    readonly property var fallback: ({
        surface_container: "#1e1e2e", surface_container_high: "#313244",
        surface_container_highest: "#45475a", on_surface: "#cdd6f4",
        on_surface_variant: "#a6adc8", outline_variant: "#45475a",
        primary: "#cba6f7", on_primary: "#1e1e2e", primary_container: "#4f3d6b",
        on_primary_container: "#ead7ff", secondary_container: "#45475a",
        on_secondary_container: "#cdd6f4", tertiary: "#f9e2af", error: "#f38ba8",
        on_error: "#1e1e2e", inverse_surface: "#cdd6f4", inverse_on_surface: "#1e1e2e"
    })
    function col(name) { return c[name] || fallback[name] }

    readonly property color bg: col("surface_container")
    readonly property color card: col("surface_container_high")
    readonly property color cardHover: col("surface_container_highest")
    readonly property color text: col("on_surface")
    readonly property color dim: col("on_surface_variant")
    readonly property color line: col("outline_variant")
    readonly property color primary: col("primary")
    readonly property color inkPrimary: col("on_primary")
    readonly property color primaryContainer: col("primary_container")
    readonly property color inkContainer: col("on_primary_container")
    readonly property color selected: col("secondary_container")
    readonly property color inkSelected: col("on_secondary_container")
    readonly property color caution: col("tertiary")
    readonly property color error: col("error")
    readonly property color inkError: col("on_error")
    readonly property color toast: col("inverse_surface")
    readonly property color inkToast: col("inverse_on_surface")
    // Matugen has no success role; DMS's terminal green (dank16 color2) follows the theme
    property string green: ""
    readonly property color success: green || "#a6e3a1"

    //--- Status tones for rows, badges and chips: "error", "success", "caution", or "" for none
    function toneColor(tone) {
        return tone === "error" ? error : tone === "success" ? success : tone === "caution" ? caution : primary
    }
    function toneFill(tone, base) { return Qt.tint(base, Qt.alpha(toneColor(tone), 0.2)) }

    FileView {
        path: Quickshell.env("HOME") + "/.cache/DankMaterialShell/dms-colors.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text())
                theme.c = d.colors[d.mode] || d.colors.dark || {}
                const g = (d.dank16 || {}).color2 || {}
                theme.green = g[d.mode] || g.default || ""
            } catch (e) {
                theme.c = {}
                theme.green = ""
            }
        }
    }

    //--- Material Symbols for the icon names api.py sends
    readonly property var glyphs: ({
        "accessories-dictionary": "menu_book", "accessories-text-editor": "edit_note",
        "application-x-addon": "extension", "application-x-executable": "terminal",
        "applications-engineering": "build", "applications-games": "sports_esports",
        "applications-graphics": "palette", "applications-multimedia": "movie",
        "applications-science": "science", "applications-system": "settings",
        "audio-speakers": "speaker", "audio-volume-high": "volume_up",
        "audio-x-generic": "music_note", "avatar-default": "person", "bluetooth": "devices",
        "computer": "computer", "dialog-information": "info", "drive-harddisk": "backup",
        "edit-paste": "content_paste", "emblem-default": "check_circle",
        "face-smile-big": "mood", "flatpak": "widgets", "focus-windows": "select_window",
        "folder": "folder", "folder-download": "download", "go-home": "home", "help-browser": "lightbulb",
        "input-gaming": "sports_esports", "input-keyboard": "keyboard", "input-mouse": "mouse",
        "multimedia-player": "play_circle", "network-server": "dns",
        "network-vpn": "vpn_lock", "network-wired": "lan", "network-wireless": "wifi",
        "network-workgroup": "lan", "night-light": "nightlight",
        "package-x-generic": "package_2", "phone": "smartphone",
        "preferences-desktop-font": "font_download",
        "preferences-desktop-keyboard-shortcuts": "keyboard_command_key",
        "preferences-desktop-locale": "language", "preferences-desktop-theme": "palette",
        "preferences-desktop-wallpaper": "wallpaper",
        "preferences-system-notifications": "notifications",
        "preferences-system-time": "schedule", "preferences-system-windows": "view_quilt",
        "security-high": "shield", "system-lock-screen": "lock",
        "system-run": "rocket_launch", "system-search": "search",
        "system-shutdown": "power_settings_new", "system-software-install": "install_desktop",
        "system-users": "group", "user-available": "chat",
        "utilities-system-monitor": "monitoring", "utilities-terminal": "terminal",
        "vcs-branch": "commit", "video-display": "desktop_windows",
        "view-app-grid": "apps", "view-continuous": "view_agenda",
        "view-dual": "splitscreen_left", "view-fullscreen": "fullscreen",
        "view-grid": "view_quilt", "view-more-horizontal": "more_horiz",
        "view-paged": "view_carousel", "view-pin": "push_pin", "web-browser": "public",
        "window-new": "view_quilt", "x-office-document": "description"
    })

    //--- The first of `names` (a name or a list) with a glyph, else `fallback`
    function glyph(names, fallback) {
        for (const n of [].concat(names || [])) {
            const g = glyphs[String(n).replace(/-symbolic$/, "")]
            if (g)
                return g
        }
        return fallback || "settings"
    }

    //--- An app icon's path for the first of `names` an icon theme or .desktop file has
    function appIcon(names) {
        for (const n of [].concat(names || [])) {
            const entry = DesktopEntries.byId(String(n).replace(/\.desktop$/, ""))
            const path = Quickshell.iconPath(entry ? entry.icon : n, true)
            if (path)
                return path
        }
        return ""
    }

    //--- descriptions.json marks app names **like this** and cautions !!like this!!
    function rich(text) {
        const esc = String(text || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
        return esc.replace(/\*\*(.+?)\*\*/g, `<b><font color="${primary}">$1</font></b>`)
                  .replace(/!!(.+?)!!/g, `<b><font color="${caution}">$1</font></b>`)
                  .replace(/\n/g, "<br>")
    }
}
