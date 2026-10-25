// Keybinds (Niri tab): the config's niri binds by group with the user's changes
// (their keybinds setting, a pending change like any other), and their own binds.
// The binds come from the copy core/keybinds.nix writes (api.py's keybinds).
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    property var applied: null  // the last build's binds, actions and changes
    property var dmsKeys: []
    property string error: ""
    property bool loaded: false
    readonly property bool niri: !!view.info && view.info.wm === "niri"
    readonly property var setting: view.info ? view.info.keybinds : null
    readonly property bool ready: !niri || loaded
    spacing: 6

    Component.onCompleted: if (niri) load()

    //--- A rebuild writes a new copy of the binds
    Connections {
        target: Jobs
        function onEnded() { if (page.niri) page.load() }
    }

    function load() {
        Backend.call("keybinds", {}, reply => {
            loaded = true
            if (reply.ok) {
                applied = reply.data.applied
                dmsKeys = reply.data.dmsKeys
                error = ""
            } else
                error = reply.error
        })
    }

    //--------------------------------------------------------------------//
    //-- Values
    //--------------------------------------------------------------------//
    //--- The keybinds setting with pending changes ({id: change}), or as saved
    function overrides(saved) {
        const v = !setting ? null : saved ? view.scopedValue(setting) : view.valueOf(setting)
        return v && typeof v === "object" && !Array.isArray(v) ? v : {}
    }
    readonly property var now: overrides(false)
    readonly property var saved: overrides(true)
    readonly property bool waiting: !!applied && !view.same(saved, applied.overrides || {})
    readonly property var actions: applied ? applied.actions : []

    function setOverride(id, change) {
        const out = Object.assign({}, now)
        if (change && Object.keys(change).length)
            out[id] = change
        else
            delete out[id]
        view.change(setting, out)
    }

    //--- An action as text: the command a spawn runs, or the action and its argument
    function actionText(action) {
        if (!action)
            return ""
        if (action.spawn !== undefined)
            return Array.isArray(action.spawn) ? joinCommand(action.spawn) : String(action.spawn)
        const name = Object.keys(action)[0] || ""
        const arg = action[name]
        return arg === null || typeof arg === "object" ? name : `${name} ${arg}`
    }

    function joinCommand(words) {
        return words.map(w => /^[\w@%+=:,./-]+$/.test(w) ? w : `"${w.replace(/(["\\])/g, "\\$1")}"`).join(" ")
    }

    //--- Every bind as it will be once pending changes apply
    readonly property var rows: {
        if (!applied)
            return []
        const out = []
        for (const b of applied.binds) {
            if (b.custom)
                continue
            const o = now[b.id] || {}
            out.push({ id: b.id, group: b.group, custom: false, hidden: b.hidden,
                       title: o.title !== undefined ? o.title : b.default.title,
                       key: o.key !== undefined ? o.key : b.default.key,
                       enable: o.enable !== undefined ? o.enable : b.default.enable,
                       default: b.default, action: actionText(b.action), changed: b.id in now,
                       savedChange: b.id in saved })
        }
        for (const [id, o] of Object.entries(now)) {
            if (!id.startsWith("custom-"))
                continue
            out.push({ id, group: "Yours", custom: true, hidden: false, title: o.title || id, key: o.key || "",
                       enable: o.enable !== false, default: null, raw: o, changed: true,
                       savedChange: id in saved,
                       action: o.spawn ? joinCommand(o.spawn) : `${o.action || ""}${o.argument ? " " + o.argument : ""}` })
        }
        return out
    }

    //--- Enabled binds by lowercased key, for clash checks
    readonly property var byKey: {
        const out = {}
        for (const r of rows)
            if (r.enable && r.key) {
                const k = r.key.toLowerCase()
                out[k] = (out[k] || []).concat([r.id])
            }
        return out
    }
    function clashes(key, id) {
        return (byKey[key.toLowerCase()] || []).filter(i => i !== id)
    }
    function titleOf(id) {
        const r = rows.find(r => r.id === id)
        return r ? r.title : id
    }
    function dmsSets(key) {
        return dmsKeys.some(k => k.toLowerCase() === key.toLowerCase())
    }

    //--------------------------------------------------------------------//
    //-- Search and groups
    //--------------------------------------------------------------------//
    property string query: ""
    property bool changedOnly: false
    function found(r) {
        if (changedOnly && !r.changed)
            return false
        const q = query.trim().toLowerCase()
        return !q || [r.title, r.key, r.action, r.group, r.id].join("\n").toLowerCase().includes(q)
    }
    //--- Groups in this order, then any other a module names; binds by title
    readonly property var groupOrder: ["Yours", "Apps", "Windows", "Focus", "Movement", "Columns", "Resize",
                                       "Workspaces", "Monitors", "Shell", "Media"]
    readonly property var shownGroups: {
        const groups = {}
        for (const r of rows.filter(found))
            groups[r.group] = (groups[r.group] || []).concat([r])
        const rank = g => groupOrder.includes(g) ? groupOrder.indexOf(g) : groupOrder.length
        return Object.keys(groups).sort((a, b) => rank(a) - rank(b) || a.localeCompare(b))
            .map(g => ({ title: g, binds: groups[g].sort((a, b) => a.title.localeCompare(b.title, undefined, { numeric: true })) }))
    }

    //--------------------------------------------------------------------//
    //-- Changes
    //--------------------------------------------------------------------//
    property var editing: null  // the row being edited, or {} for a new bind
    function edit(row) {
        editing = row
        view.sheet = editorSheet
    }
    Component {
        id: editorSheet
        KeybindEditor { view: page.view; kb: page; bind: page.editing }
    }

    function toggle(row, on) {
        if (row.custom) {
            const o = Object.assign({}, row.raw)
            if (on)
                delete o.enable
            else
                o.enable = false
            setOverride(row.id, o)
            return
        }
        const o = Object.assign({}, now[row.id] || {})
        if (on === row.default.enable)
            delete o.enable
        else
            o.enable = on
        setOverride(row.id, o)
    }

    function reset(row) {
        if (row.custom)
            view.ask({ heading: `Remove ${row.title}?`, body: "Your keybind comes out on Apply.",
                       buttons: [{ label: "Remove", value: "remove", danger: true }] },
                     () => setOverride(row.id, null))
        else
            setOverride(row.id, null)
    }

    function rebuild() {
        view.ask({
            heading: "Rebuild now?",
            body: "Rebuilds from your settings files as they are (nixos-rebuild switch), which gives niri "
                  + "the keybinds saved here.",
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
            RowLayout {
                spacing: 14
                Layout.fillWidth: true
                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    Text {
                        text: !page.niri
                            ? `These are niri's keybinds, and this computer runs ${page.view.info && page.view.info.wm || "another"} window manager.`
                            : "Change a key, turn a keybind off, or add your own. Changes are yours alone and "
                              + "wait for Apply, like any other setting."
                        color: Theme.dim
                        font.pixelSize: 13
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }
            Flow {
                visible: !!page.applied
                Layout.fillWidth: true
                spacing: 8
                Pill { text: "New Keybind"; onClicked: page.edit({}) }
                Pill { text: "Pick a Window"; quiet: true; onClicked: page.edit({ pick: true }) }
            }
        }
    }

    Text {
        visible: page.error !== "" || (page.niri && page.loaded && !page.applied && page.error === "")
        text: page.error || "Rebuild once to list the keybinds: this build doesn't write the list this page reads."
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
        subtitle: "Saved keybind changes reach niri with the next rebuild."
        button: page.view.info && page.view.info.canApply && page.view.info.admin ? "Rebuild" : ""
        onClicked: if (button) page.rebuild()
    }

    //--------------------------------------------------------------------//
    //-- The binds
    //--------------------------------------------------------------------//
    Field {
        visible: !!page.applied
        icon: "search"
        placeholder: "Search keybinds, keys and actions"
        onTextChanged: page.query = text
        onEscaped: text = ""
    }
    Flow {
        visible: !!page.applied
        Layout.fillWidth: true
        Layout.leftMargin: 4
        spacing: 6
        Chip {
            text: "Changed Only"
            icon: page.changedOnly ? "check" : ""
            accent: page.changedOnly
            onTapped: page.changedOnly = !page.changedOnly
        }
    }
    Text {
        visible: page.dmsKeys.length > 0
        text: `The shell's Keyboard Shortcuts page also binds ${page.dmsKeys.join(", ")}; those win over the keybinds here.`
        color: Theme.dim
        font.pixelSize: 13
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        Layout.leftMargin: 6
    }
    Text {
        visible: !!page.applied && page.shownGroups.length === 0
        text: "No keybinds match."
        color: Theme.dim
        font.pixelSize: 13
        Layout.leftMargin: 6
        Layout.topMargin: 6
    }

    Repeater {
        model: page.shownGroups
        ColumnLayout {
            id: group
            required property var modelData
            Layout.fillWidth: true
            spacing: 6
            RowLayout {
                Layout.topMargin: 10
                Layout.leftMargin: 6
                spacing: 8
                Text { text: group.modelData.title; color: Theme.primary; font.pixelSize: 15; font.weight: Font.DemiBold }
                Chip { tappable: false; text: String(group.modelData.binds.length); accent: true }
            }
            Repeater {
                model: group.modelData.binds
                BindRow { required property var modelData; bind: modelData }
            }
        }
    }

    //--- One bind: its title, key, what it does, and its switch
    component BindRow: Rectangle {
        id: row
        property var bind
        readonly property var clash: bind.enable && bind.key ? page.clashes(bind.key, bind.id) : []
        Layout.fillWidth: true
        implicitHeight: bindCol.implicitHeight + 20
        radius: 14
        color: hover.hovered ? Theme.hover : Theme.card
        opacity: bind.enable ? 1 : 0.6
        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: page.edit(row.bind) }
        RowLayout {
            id: bindCol
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 8
            spacing: 10
            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                Text {
                    text: row.bind.title
                    color: Theme.text
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: row.bind.action
                    color: Theme.dim
                    font.family: "monospace"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: 4
                    Chip { tappable: false; text: row.bind.key || "No key"; accent: true }
                    Chip {
                        tappable: false
                        visible: row.bind.changed && !row.bind.custom
                        text: row.bind.savedChange ? "Changed" : "Changed, not saved"
                        tone: "caution"
                    }
                    Chip {
                        tappable: false
                        visible: !row.bind.custom && row.bind.key !== row.bind.default.key
                        text: row.bind.default ? `was ${row.bind.default.key}` : ""
                    }
                    Chip { tappable: false; visible: row.bind.hidden; text: "Not on the cheatsheet" }
                    Chip {
                        tappable: false
                        visible: row.clash.length > 0
                        text: `Same key as ${row.clash.map(page.titleOf).join(", ")}`
                        tone: "error"
                    }
                    Chip {
                        tappable: false
                        visible: !!row.bind.key && page.dmsSets(row.bind.key)
                        text: "The shell's shortcut wins"
                        tone: "caution"
                    }
                }
            }
            IconButton {
                visible: row.bind.changed
                icon: row.bind.custom ? "delete" : "undo"
                onClicked: page.reset(row.bind)
            }
            Toggle { checked: row.bind.enable; onToggled: on => page.toggle(row.bind, on) }
        }
    }
}
