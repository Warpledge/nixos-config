// Side Rail (Niri tab): the Mod+A rail's apps with the user's changes (their
// sideRail setting, a pending change like any other), and their own apps.
// The shared apps come from the copy dms/default.nix writes (api.py's sideRail).
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    property var built: null  // {geometry, shared, changes} from the last build
    property string error: ""
    property bool loaded: false
    readonly property bool niri: !!view.info && view.info.wm === "niri"
    readonly property var setting: view.info ? view.info.sideRail : null
    readonly property bool ready: !niri || loaded
    spacing: 6

    Component.onCompleted: if (niri) load()

    //--- A rebuild writes a new copy of the apps
    Connections {
        target: Jobs
        function onEnded() { if (page.niri) page.load() }
    }

    function load() {
        Backend.call("sideRail", {}, reply => {
            loaded = true
            if (reply.ok) {
                built = reply.data
                error = ""
            } else
                error = reply.error
        })
    }

    //--------------------------------------------------------------------//
    //-- Values
    //--------------------------------------------------------------------//
    //--- The sideRail setting with pending changes ({id: change}), or as saved
    function overrides(saved) {
        const v = !setting ? null : saved ? view.scopedValue(setting) : view.valueOf(setting)
        return v && typeof v === "object" && !Array.isArray(v) ? v : {}
    }
    readonly property var now: overrides(false)
    readonly property var saved: overrides(true)
    readonly property bool waiting: !!built && !view.same(saved, built.changes || {})
    readonly property int defaultWidth: built ? built.geometry.width : 0
    // 30 until a rebuild writes the geometry that has it
    readonly property int defaultUnload: built && built.geometry.unloadAfter ? built.geometry.unloadAfter : 30

    function setOverride(id, change) {
        const out = Object.assign({}, now)
        if (change && Object.keys(change).length)
            out[id] = change
        else
            delete out[id]
        view.change(setting, out)
    }

    //--- Every app as the rail will list it once pending changes apply, as apps.nix orders them
    readonly property var rows: {
        if (!built)
            return []
        const shared = built.shared.map((a, i) => {
            const c = now[a.id] || {}
            return { id: a.id, name: a.name, icon: a.icon, custom: false,
                     web: a.command[0] === "helium", what: a.command.join(" "),
                     enable: c.enable !== false, width: c.width || a.width, defaultOrder: i,
                     keepRunning: c.keepRunning !== undefined ? c.keepRunning : !!a.keepRunning,
                     unloadAfter: c.unloadAfter || a.unloadAfter || defaultUnload,
                     order: c.order !== undefined ? c.order : i, changed: a.id in now,
                     savedChange: a.id in saved, raw: c }
        })
        const custom = Object.keys(now).filter(id => id.startsWith("custom-")).sort().map(id => {
            const c = now[id]
            return { id, name: c.name || id, icon: c.icon || "apps", custom: true, web: !!c.url,
                     what: c.url || (c.command || []).join(" "),
                     enable: c.enable !== false, width: c.width || defaultWidth, defaultOrder: 1000,
                     keepRunning: !!c.keepRunning, unloadAfter: c.unloadAfter || defaultUnload,
                     order: c.order !== undefined ? c.order : 1000, changed: true,
                     savedChange: id in saved, raw: c }
        })
        return shared.concat(custom).sort((a, b) => a.order - b.order)
    }

    //--- Swaps a row with its neighbour, writing an order only where it moved
    function move(row, step) {
        const list = rows.slice()
        const i = list.findIndex(r => r.id === row.id)
        const j = i + step
        if (i < 0 || j < 0 || j >= list.length)
            return
        list[i] = list[j]
        list[j] = row
        const out = Object.assign({}, now)
        list.forEach((r, k) => {
            const o = Object.assign({}, out[r.id] || {})
            if (k === r.defaultOrder)
                delete o.order
            else
                o.order = k
            if (Object.keys(o).length)
                out[r.id] = o
            else
                delete out[r.id]
        })
        view.change(setting, out)
    }

    function change(row, key, value) {
        const o = Object.assign({}, now[row.id] || {})
        if (value === undefined)
            delete o[key]
        else
            o[key] = value
        setOverride(row.id, o)
    }

    function toggle(row, on) {
        change(row, "enable", on ? undefined : false)
    }

    function reset(row) {
        if (row.custom)
            view.ask({ heading: `Remove ${row.name}?`, body: "It comes off the rail on Apply.",
                       buttons: [{ label: "Remove", value: "remove", danger: true }] },
                     () => setOverride(row.id, null))
        else
            setOverride(row.id, null)
    }

    property var editing: null  // the row being edited, or {} for a new app
    function edit(row) {
        editing = row
        view.sheet = editorSheet
    }
    Component {
        id: editorSheet
        SideRailEditor { view: page.view; rail: page; app: page.editing }
    }

    function rebuild() {
        view.ask({
            heading: "Rebuild now?",
            body: "Rebuilds from your settings files as they are (nixos-rebuild switch), which gives the "
                  + "rail the apps saved here.",
            buttons: [{ label: "Preview", value: "build", quiet: true },
                      { label: "At Next Restart", value: "boot", quiet: true },
                      { label: "Rebuild Now", value: "switch" }]
        }, mode => view.startJob("rebuild", { mode }))
    }

    //--------------------------------------------------------------------//
    //-- Hero
    //--------------------------------------------------------------------//
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: hero.implicitHeight + 28
        radius: 16
        color: Theme.card
        ColumnLayout {
            id: hero
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12
            Text {
                visible: !page.niri
                text: `The side rail is niri's, and this computer runs ${page.view.info && page.view.info.wm || "another"} window manager.`
                color: Theme.caution
                font.pixelSize: 14
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            Text {
                visible: !!page.built
                text: "Mod+A shows the rail. Drag an app wider or narrower with Mod and the right mouse button, "
                      + "or right-click its icon for presets; the width set here is where Reset goes back to."
                color: Theme.dim
                font.pixelSize: 13
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            Flow {
                visible: !!page.built
                Layout.fillWidth: true
                spacing: 8
                Pill { text: "New App"; onClicked: page.edit({}) }
            }
        }
    }

    Text {
        visible: page.error !== "" || (page.niri && page.loaded && !page.built && page.error === "")
        text: page.error || "Rebuild once to list the rail's apps: this build doesn't write the list this page reads."
        color: page.error ? Theme.error : Theme.dim
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        Layout.margins: 6
    }

    ListRow {
        visible: page.waiting
        Layout.topMargin: 6
        icon: "sync"
        tone: "caution"
        title: "Not Applied Yet"
        info: "Saved rail changes reach the rail with the next rebuild."
        button: page.view.info && page.view.info.canApply && page.view.info.admin ? "Rebuild" : ""
        onClicked: if (button) page.rebuild()
    }

    Repeater {
        model: page.rows
        AppRow { required property var modelData; row: modelData; first: index === 0; last: index === page.rows.length - 1 }
    }

    //--- One app: its icon, name, what it opens, order buttons and switch
    component AppRow: Rectangle {
        id: r
        property var row
        property bool first
        property bool last
        required property int index
        Layout.fillWidth: true
        implicitHeight: rowCol.implicitHeight + 20
        radius: 14
        color: hover.hovered ? Theme.hover : Theme.card
        opacity: row.enable ? 1 : 0.6
        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: page.edit(r.row) }
        RowLayout {
            id: rowCol
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 8
            spacing: 10
            Badge { icon: r.row.icon; app: [r.row.icon] }
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                Text {
                    text: r.row.name
                    color: Theme.text
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: r.row.what
                    color: Theme.dim
                    font.family: "monospace"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 4
                    Chip { tappable: false; text: `${r.row.width}px`; accent: true }
                    Chip { tappable: false; text: r.row.web ? "Web page" : "App" }
                    Chip { tappable: false; text: r.row.keepRunning ? "Keeps running" : `Unloads after ${r.row.unloadAfter} min` }
                    Chip {
                        tappable: false
                        visible: r.row.changed && !r.row.custom
                        text: r.row.savedChange ? "Changed" : "Changed, not saved"
                        tone: "caution"
                    }
                }
            }
            IconButton { icon: "arrow_upward"; tip: "Move up"; enabled: !r.first; onClicked: page.move(r.row, -1) }
            IconButton { icon: "arrow_downward"; tip: "Move down"; enabled: !r.last; onClicked: page.move(r.row, 1) }
            IconButton {
                visible: r.row.changed
                icon: r.row.custom ? "delete" : "undo"
                tip: r.row.custom ? "Remove" : "Back to default"
                onClicked: page.reset(r.row)
            }
            Toggle { checked: r.row.enable; onToggled: on => page.toggle(r.row, on) }
        }
    }
}
