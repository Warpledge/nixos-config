// Edits one side rail app: a shared one's width, or one of the user's custom-
// apps (a web page opened as a Helium app window, or a command and the app ID
// its window opens with), filled from an open window, with its icon a theme
// icon, the app's own, a Material Symbol or an image file.
import QtQuick
import QtQuick.Layouts

Sheet {
    id: ed
    required property var view
    required property var rail  // SideRailPage: now, defaultWidth, setOverride
    required property var app  // a row from rail.rows, or {} for a new app
    readonly property bool isNew: !app.id
    readonly property bool custom: isNew || app.custom
    title: isNew ? "New Rail App" : `Edit ${app.name}`
    subtitle: "Side rail app · yours alone · waits for Apply"
    onBack: view.sheet = null

    property bool web: true
    property bool picking: false
    property bool keep: false

    Component.onCompleted: {
        nameField.text = app.name || ""
        widthField.text = app.raw && app.raw.width ? String(app.raw.width) : ""
        keep = app.raw && app.raw.keepRunning !== undefined ? app.raw.keepRunning : fallbackKeep
        minutesField.text = app.raw && app.raw.unloadAfter ? String(app.raw.unloadAfter) : ""
        if (app.custom) {
            const o = app.raw
            web = !!o.url
            urlField.text = o.url || ""
            commandField.text = o.command ? joinCommand(o.command) : ""
            appIdField.text = o.appId || ""
            iconField.text = o.icon || ""
        }
    }

    //--- The width the rail resets to when this one is left empty
    readonly property int fallbackWidth: {
        if (!custom && rail.built) {
            const a = rail.built.shared.find(s => s.id === app.id)
            if (a)
                return a.width
        }
        return rail.defaultWidth
    }

    //--- Unloading as apps.nix sets it before the user's change
    readonly property var sharedApp: !custom && rail.built ? rail.built.shared.find(s => s.id === app.id) || null : null
    readonly property bool fallbackKeep: !!(sharedApp && sharedApp.keepRunning)
    readonly property int fallbackMinutes: sharedApp && sharedApp.unloadAfter ? sharedApp.unloadAfter : rail.defaultUnload

    property var windows: null  // the open windows, while listed
    property string ownIcon: ""  // the picked app's icon from its .desktop file

    function pick() {
        picking = true
        view.say("Click the window to put on the rail")
        Backend.call("pickWindow", {}, reply => {
            picking = false
            if (!reply.ok)
                view.say(`Couldn't pick a window: ${reply.error}`)
            else if (reply.data)
                use(reply.data)
        })
    }

    function listWindows() {
        if (windows) {
            windows = null
            return
        }
        windows = []
        Backend.call("niriWindows", {}, reply => {
            if (reply.ok)
                windows = reply.data
        })
    }

    //--- Fills the form from a window: a Helium app window back to its page
    //--- (apps.nix names those chrome-<host>__<path>-Default), else the app
    function use(w) {
        windows = null
        if (!nameField.text)
            nameField.text = w.name
        const page = /^chrome-(.+?)__(.*)-Default$/.exec(w.appId || "")
        if (page) {
            web = true
            const local = /^(localhost|127\.0\.0\.1)$/.test(page[1])
            urlField.text = `${local ? "http" : "https"}://${page[1]}/${page[2].replace(/_/g, "/")}`
            view.say(local ? `Picked ${w.name}; add the page's port to the address` : `Picked ${w.name}`)
            return
        }
        web = false
        appIdField.text = w.appId
        Backend.call("appIcon", { appId: w.appId }, r => {
            ownIcon = r.ok ? r.data : ""
            if (ownIcon && !iconField.text)
                iconField.text = ownIcon
        })
        Backend.call("launchCommand", { appId: w.appId }, r => {
            const cmd = r.ok ? r.data : []
            commandField.text = joinCommand(cmd)
            view.say(cmd.length ? `Picked ${w.name}` : `Picked ${w.name}; type the command that starts it`)
        })
    }

    function useOwnIcon() {
        Backend.call("appIcon", { appId: appIdField.text.trim() }, r => {
            ownIcon = r.ok ? r.data : ""
            if (ownIcon)
                iconField.text = ownIcon
            else
                view.say("This app's .desktop file names no icon")
        })
    }

    readonly property var symbols: ["public", "travel_explore", "smart_toy", "forum", "chat", "mail",
        "calendar_month", "description", "note_stack", "code", "terminal", "memory", "cloud",
        "monitoring", "newspaper", "movie", "music_note", "photo_library", "sports_esports",
        "shopping_cart", "school", "translate", "map", "bookmark", "home", "settings"]

    property bool fetchingIcon: false
    function useSiteIcon() {
        fetchingIcon = true
        Backend.call("siteIcon", { url: urlField.text.trim() }, r => {
            fetchingIcon = false
            if (r.ok)
                iconField.text = r.data
            else
                view.say(`No site icon: ${r.error}`)
        })
    }

    function chooseIconFile() {
        Backend.call("pickIconFile", {}, r => {
            if (!r.ok)
                view.say(`Couldn't choose a file: ${r.error}`)
            else if (r.data)
                iconField.text = r.data
        })
    }

    function joinCommand(words) {
        return words.map(w => /^[\w@%+=:,./-]+$/.test(w) ? w : `"${w.replace(/(["\\])/g, "\\$1")}"`).join(" ")
    }

    //--- A command line as words, with "double" or 'single' quotes keeping spaces
    function splitCommand(text) {
        const words = []
        const re = /"((?:[^"\\]|\\.)*)"|'([^']*)'|(\S+)/g
        let m
        while ((m = re.exec(text)) !== null)
            words.push(m[1] !== undefined ? m[1].replace(/\\(.)/g, "$1") : m[2] !== undefined ? m[2] : m[3])
        return words
    }

    function slug(text) {
        const s = text.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "")
        return s || "app"
    }

    function save() {
        const typed = widthField.text.trim()
        const width = typed === "" ? 0 : parseInt(typed, 10)
        if (typed !== "" && !(width > 0)) {
            view.say("The width is a number of pixels, like 900")
            return
        }
        const typedMinutes = minutesField.text.trim()
        const minutes = typedMinutes === "" ? 0 : Number(typedMinutes)
        if (typedMinutes !== "" && !(Number.isInteger(minutes) && minutes > 0)) {
            view.say("The time is a whole number of minutes, like 15")
            return
        }
        const kept = Object.assign({}, app.raw || {})
        if (!custom) {
            if (width && width !== fallbackWidth)
                kept.width = width
            else
                delete kept.width
            if (keep !== fallbackKeep)
                kept.keepRunning = keep
            else
                delete kept.keepRunning
            if (minutes && minutes !== fallbackMinutes)
                kept.unloadAfter = minutes
            else
                delete kept.unloadAfter
            rail.setOverride(app.id, kept)
            view.sheet = null
            return
        }
        const name = nameField.text.trim()
        if (!name) {
            view.say("Give the app a name")
            return
        }
        const o = { name }
        if (web) {
            const url = urlField.text.trim()
            if (!/^https?:\/\/\S+$/.test(url)) {
                view.say("Type the page's address, starting with https://")
                return
            }
            o.url = url
        } else {
            const cmd = splitCommand(commandField.text)
            if (!cmd.length || !appIdField.text.trim()) {
                view.say("Pick a window, or type the command and the app ID its window opens with")
                return
            }
            o.command = cmd
            o.appId = appIdField.text.trim()
        }
        if (iconField.text.trim())
            o.icon = iconField.text.trim()
        if (width)
            o.width = width
        if (keep)
            o.keepRunning = true
        if (minutes && minutes !== fallbackMinutes)
            o.unloadAfter = minutes
        if (kept.enable === false)
            o.enable = false
        if (kept.order !== undefined)
            o.order = kept.order
        let id = app.id
        if (isNew) {
            id = `custom-${slug(name)}`
            for (let n = 2; id in rail.now; n++)
                id = `custom-${slug(name)}-${n}`
        }
        rail.setOverride(id, o)
        view.sheet = null
    }

    actions: [
        Pill { text: "Cancel"; quiet: true; onClicked: ed.view.sheet = null },
        Pill {
            visible: !ed.custom && !!ed.app.changed
            text: "Back to Default"
            quiet: true
            onClicked: {
                ed.rail.setOverride(ed.app.id, null)
                ed.view.sheet = null
            }
        },
        Pill { text: ed.isNew ? "Add" : "Done"; onClicked: ed.save() }
    ]

    //--------------------------------------------------------------------//
    //-- Form
    //--------------------------------------------------------------------//
    //--- Fill the form from a window that's open now
    Card {
        visible: ed.custom
        Label { text: "From an Open Window" }
        Flow {
            Layout.fillWidth: true
            spacing: 8
            Pill { text: ed.picking ? "Click a Window…" : "Pick a Window"; quiet: true; enabled: !ed.picking; onClicked: ed.pick() }
            Pill { text: ed.windows ? "Hide Open Windows" : "Open Windows"; quiet: true; onClicked: ed.listWindows() }
        }
        Repeater {
            model: ed.windows || []
            ListRow {
                required property var modelData
                compact: true
                icon: "view_quilt"
                app: modelData.appId ? [modelData.appId, modelData.appId.toLowerCase()] : []
                title: modelData.title || modelData.name || "Untitled"
                subtitle: modelData.appId || "no app ID"
                onClicked: ed.use(modelData)
            }
        }
    }

    Card {
        visible: ed.custom
        Label { text: "Name" }
        Field { id: nameField; placeholder: "What the rail calls it" }
        Label { text: "Icon"; Layout.topMargin: 4 }
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Badge { icon: iconField.text.trim() || "apps"; app: iconField.text.trim() ? [iconField.text.trim()] : [] }
            Field { id: iconField; placeholder: "An icon name, a Material Symbol (forum) or an image file" }
        }
        Flow {
            Layout.fillWidth: true
            spacing: 8
            Pill {
                visible: !ed.web && appIdField.text.trim() !== ""
                text: "App's Own Icon"
                quiet: true
                onClicked: ed.useOwnIcon()
            }
            Pill {
                visible: ed.web
                text: ed.fetchingIcon ? "Getting Icon…" : "Site's Icon"
                quiet: true
                enabled: !ed.fetchingIcon
                onClicked: ed.useSiteIcon()
            }
            Pill { text: "Choose File…"; quiet: true; onClicked: ed.chooseIconFile() }
        }
        //--- Material Symbols, the set DMS draws its own icons from
        Flow {
            Layout.fillWidth: true
            spacing: 4
            Repeater {
                model: ed.symbols
                Rectangle {
                    id: sym
                    required property string modelData
                    width: 34
                    height: 34
                    radius: 10
                    color: iconField.text === modelData ? Theme.selected : symHover.hovered ? Theme.hover : "transparent"
                    Icon { anchors.centerIn: parent; icon: sym.modelData; size: 20 }
                    HoverHandler { id: symHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: iconField.text = sym.modelData }
                }
            }
        }
    }

    Card {
        visible: ed.custom
        Label { text: "What It Opens" }
        Flow {
            Layout.fillWidth: true
            spacing: 6
            Chip { text: "Web Page"; accent: ed.web; onTapped: ed.web = true }
            Chip { text: "App"; accent: !ed.web; onTapped: ed.web = false }
        }
        Field { id: urlField; visible: ed.web; placeholder: "https://… (opens as a Helium app window)" }
        ColumnLayout {
            visible: !ed.web
            Layout.fillWidth: true
            spacing: 8
            Field { id: commandField; placeholder: "Command, e.g. obsidian" }
            Field { id: appIdField; placeholder: "App ID its window opens with, e.g. obsidian" }
        }
    }

    Card {
        Label { text: "Width" }
        Field { id: widthField; placeholder: `${ed.fallbackWidth} pixels unless set` }
        Text {
            text: "Where Reset to Default on the rail goes back to. Dragging with Mod and the right mouse "
                  + "button changes it until then."
            color: Theme.dim
            font.pixelSize: 13
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }

    Card {
        Label { text: "Unloading" }
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true
                Text { text: "Keep Running"; color: Theme.text; font.pixelSize: 15 }
                Text {
                    text: ed.keep ? "Stays open while the rail hides it"
                                  : "Closes after sitting hidden, and reopens when picked"
                    color: Theme.dim
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
            Toggle { checked: ed.keep; onToggled: on => ed.keep = on }
        }
        Field { id: minutesField; visible: !ed.keep; placeholder: `${ed.fallbackMinutes} minutes hidden unless set` }
        Text {
            text: "The rail's right-click menu changes both until Reset to Default."
            color: Theme.dim
            font.pixelSize: 13
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }

    component Label: Text {
        color: Theme.dim
        font.pixelSize: 13
        font.weight: Font.DemiBold
        Layout.leftMargin: 4
    }

    component Card: Rectangle {
        default property alias content: cardCol.data
        Layout.fillWidth: true
        implicitHeight: cardCol.implicitHeight + 28
        radius: 16
        color: Theme.card
        ColumnLayout {
            id: cardCol
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8
        }
    }
}
