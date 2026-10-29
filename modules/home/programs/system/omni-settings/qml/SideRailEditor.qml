// Edits one side rail app: a shared one's width, or one of the user's custom-
// apps (a web page opened as a Helium app window, or a command and the app ID
// its window opens with, filled from a picked window).
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
    onBack: view.sheet = null

    property bool web: true
    property bool picking: false

    Component.onCompleted: {
        nameField.text = app.name || ""
        widthField.text = app.raw && app.raw.width ? String(app.raw.width) : ""
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

    function pick() {
        picking = true
        view.say("Click the window to put on the rail")
        Backend.call("pickWindow", {}, reply => {
            picking = false
            if (!reply.ok) {
                view.say(`Couldn't pick a window: ${reply.error}`)
                return
            }
            const w = reply.data
            if (!w)
                return
            appIdField.text = w.appId
            if (!nameField.text)
                nameField.text = w.name
            Backend.call("launchCommand", { appId: w.appId }, r => {
                const cmd = r.ok ? r.data : []
                commandField.text = joinCommand(cmd)
                view.say(cmd.length ? `Picked ${w.name}` : `Picked ${w.name}; type the command that starts it`)
            })
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
        const kept = Object.assign({}, app.raw || {})
        if (!custom) {
            if (width && width !== fallbackWidth)
                kept.width = width
            else
                delete kept.width
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
    Card {
        visible: ed.custom
        Label { text: "Name" }
        Field { id: nameField; placeholder: "What the rail calls it" }
        Label { text: "Icon"; Layout.topMargin: 4 }
        Field { id: iconField; placeholder: "An icon name (firefox) or a Material Symbol (forum)" }
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
            Pill {
                text: ed.picking ? "Click a Window…" : "Pick a Window"
                quiet: true
                enabled: !ed.picking
                onClicked: ed.pick()
            }
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
