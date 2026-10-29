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
        on_error: "#1e1e2e"
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
    // Tints of primary: DMS's schemes can make secondary_container the card colour
    // and outline_variant the background, so neither shows a hover or a choice
    readonly property color hover: Qt.tint(cardHover, Qt.alpha(primary, 0.16))
    readonly property color selected: Qt.tint(card, Qt.alpha(primary, 0.3))
    readonly property color inkSelected: text
    readonly property color error: col("error")
    readonly property color inkError: col("on_error")
    // Not inverse_surface: matugen makes it light in dark mode, and a tip's yellow
    // caution and primary app names vanish on it
    readonly property color toast: col("surface_container_highest")
    readonly property color inkToast: col("on_surface")
    // Matugen has no success or warning role, and tertiary needn't be yellow; DMS's
    // terminal green and yellow (dank16 color2 and color3) follow the theme
    property string green: ""
    property string yellow: ""
    readonly property color success: green || "#a6e3a1"
    readonly property color caution: yellow || "#f9e2af"

    //--- Page accents: primary's hue turned in 30° steps, leaving out any within 45°
    //--- of a status colour so a page never reads as a state; ordered so the hues
    //--- next to each other in the list sit far apart on the wheel
    readonly property var accentHues: {
        const base = Math.max(0, primary.hslHue)  // -1 for a grey primary
        const status = [success, caution, error].map(c => c.hslHue).filter(h => h >= 0)
        const near = (a, b) => Math.min(Math.abs(a - b), 1 - Math.abs(a - b)) < 0.125
        const hues = []
        for (let k = 0; k < 12; k++) {
            const h = (base + k / 12) % 1
            if (k === 0 || !status.some(s => near(h, s)))
                hues.push(h)
        }
        const half = Math.ceil(hues.length / 2), out = []
        for (let i = 0; i < half; i++) {
            out.push(hues[i])
            if (i + half < hues.length)
                out.push(hues[i + half])
        }
        return out
    }
    //--- A grey scheme would leave them all grey, so keep a little saturation
    function pageAccent(n) {
        const h = accentHues[n % accentHues.length]
        return Qt.hsla(h, Math.max(0.3, primary.hslSaturation), primary.hslLightness, 1)
    }
    //--- A page's place in accentHues from its id, so it keeps its colour as pages
    //--- around it come and go
    function accentIndex(id) {
        let h = 0
        for (let i = 0; i < id.length; i++)
            h = (h * 31 + id.charCodeAt(i)) | 0
        return Math.abs(h) % accentHues.length
    }
    //--- The accent of the page `item` sits in (the nearest `pageAccent` above it),
    //--- or primary outside one, as in sheets and dialogs
    function accentOf(item) {
        for (let p = item; p; p = p.parent)
            if (p.pageAccent !== undefined)
                return p.pageAccent
        return primary
    }

    //--- Status tones for rows, badges and chips: "error", "success", "caution", or "" for none
    function toneColor(tone) {
        return tone === "error" ? error : tone === "success" ? success : tone === "caution" ? caution : primary
    }
    function toneFill(tone, base) { return Qt.tint(base, Qt.alpha(toneColor(tone), 0.2)) }

    //--- Rows: a wash of the page's accent and an accent border, the same as the
    //--- collapsed group cards (SettingsPage.qml)
    function rowFill(accent, lit) { return Qt.alpha(accent, lit ? 0.13 : 0.07) }
    function rowBorder(accent, open) { return Qt.alpha(accent, open ? 0.35 : 0.2) }

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
                const y = (d.dank16 || {}).color3 || {}
                theme.yellow = y[d.mode] || y.default || ""
            } catch (e) {
                theme.c = {}
                theme.green = ""
                theme.yellow = ""
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
        "computer": "computer", "dialog-information": "info", "draw-brush": "brush",
        "drive-harddisk": "backup",
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
        "security-high": "shield", "speedometer": "speed", "system-lock-screen": "lock",
        "system-reboot": "restart_alt",
        "system-run": "rocket_launch", "system-search": "search",
        "system-shutdown": "power_settings_new", "system-software-install": "install_desktop",
        "system-users": "group", "text-x-generic": "description", "user-available": "chat",
        "utilities-system-monitor": "monitoring", "utilities-terminal": "terminal",
        "vcs-branch": "commit", "view-list": "checklist","video-display": "desktop_windows",
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

    //--- An app icon's path for the first of `names` an icon theme or .desktop file has,
    //--- "" for none, or undefined until `lookups` gets to it: a theme lookup takes up to
    //--- 100 ms and Qt doesn't keep it, so each runs once, a few a frame
    property var iconPaths: ({})
    property var iconQueue: []  // changed in place, so bindings don't wait on it
    function appIcon(names) {
        const list = [].concat(names || [])
        if (!list.length)
            return ""
        const key = list.join("\n")
        const path = iconPaths[key]
        if (path === undefined)
            queueIcons([list])
        return path
    }
    function queueIcons(lists) {
        for (const l of lists) {
            const key = [].concat(l || []).join("\n")
            if (key && iconPaths[key] === undefined && !iconQueue.includes(key))
                iconQueue.push(key)
        }
        if (iconQueue.length)
            lookups.start()
    }
    function lookUp(key) {
        for (const n of key.split("\n")) {
            const entry = DesktopEntries.byId(n.replace(/\.desktop$/, ""))
            const path = Quickshell.iconPath(entry ? entry.icon : n, true)
            if (path)
                return path
        }
        return ""
    }
    Timer {
        id: lookups
        interval: 16
        repeat: true
        onTriggered: {
            const until = Date.now() + 6
            while (theme.iconQueue.length && Date.now() < until) {
                const key = theme.iconQueue.shift()
                theme.iconPaths[key] = theme.lookUp(key)
            }
            theme.iconPathsChanged()
            if (!theme.iconQueue.length)
                stop()
        }
    }
    //--- .desktop files load after start-up and change on a rebuild: look again for
    //--- the icons not found
    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            const missed = Object.keys(theme.iconPaths).filter(k => theme.iconPaths[k] === "")
            for (const k of missed)
                delete theme.iconPaths[k]
            theme.queueIcons(missed.map(k => k.split("\n")))
        }
    }

    //--- descriptions.json marks app names **like this** and cautions !!like this!!
    function rich(text) {
        const esc = String(text || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
        return esc.replace(/\*\*(.+?)\*\*/g, `<b><font color="${primary}">$1</font></b>`)
                  .replace(/!!(.+?)!!/g, `<b><font color="${caution}">$1</font></b>`)
                  .replace(/\n/g, "<br>")
    }
    //--- The same text without its marks, for a tooltip
    function plain(text) { return String(text || "").replace(/\*\*|!!/g, "") }
}
