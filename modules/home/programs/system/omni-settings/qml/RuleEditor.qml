// Edits one rule from window-rules.json: its name and note, the windows it
// matches or leaves out, and what it does. Properties the page has no control
// for are kept as they are, or removed. Saved through api.py's saveWindowRule.
import QtQuick
import QtQuick.Layouts

Sheet {
    id: ed
    required property var view
    required property var wr  // the page's windowRules reply: kinds, sizes, places
    required property var rule  // one rule from it, with `raw`
    signal saved(var reply)
    title: `Edit ${rule.title}`
    onBack: view.sheet = null

    readonly property int pixelsIndex: wr.sizes.findIndex(s => s.value === null)
    property var matches: []
    property var excludes: []
    property var props: []
    readonly property var missing: wr.kinds.filter(k => !props.some(e => e.prop === k.prop))

    Component.onCompleted: {
        const raw = ed.rule.raw
        nameField.text = raw.name || ""
        noteField.text = raw.note || ""
        noteField.input.cursorPosition = 0
        matches = (raw.matches || []).map(matchEntry)
        excludes = (raw.excludes || []).map(matchEntry)
        props = ed.rule.props.map(p => entry(p.prop, p.value, p.text))
    }

    function same(a, b) { return JSON.stringify(a) === JSON.stringify(b) }

    //--- A match as an app ID, a title, and the other keys kept as they are
    function matchEntry(m) {
        const extra = Object.assign({}, m)
        delete extra["app-id"]
        delete extra.title
        return { app: m["app-id"] || "", title: m.title || "", extra,
                 extraText: Object.keys(extra).map(k => `${k}=${extra[k]}`).join("  ") }
    }

    //--- A property and the state of its control
    function entry(prop, value, text) {
        const k = wr.kinds.find(k => k.prop === prop)
        const title = k ? k.title : prop.charAt(0).toUpperCase() + prop.slice(1).replace(/-/g, " ")
        const control = k ? k.control : typeof value === "boolean" ? "on" : ""
        const e = { prop, value, title, control, text: text || "", choices: k ? k.choices : [] }
        if (control === "on")
            e.on = !!value
        else if (control === "choice")
            e.choice = Math.max(0, e.choices.findIndex(c => same(c.value, value)))
        else if (control === "size") {
            e.size = wr.sizes.findIndex(s => s.value !== null && same(s.value, value))
            if (e.size < 0)  // a proportion the page has no name for stays until changed
                e.size = value && value.fixed !== undefined ? pixelsIndex : -1
            e.px = String(value && value.fixed || 800)
        } else if (["opacity", "workspace", "output"].includes(control))
            e.typed = String(value)
        return e
    }

    //--- Delegates get copies of the entries, so changes go through the list by position
    function setProp(i, key, v) { props[i][key] = v }
    function setMatch(list, i, key, v) { list[i][key] = v }

    function addProp(k) {
        const defaults = { on: true, choice: k.choices.length ? k.choices[0].value : true,
                           size: { proportion: 0.5 }, opacity: 0.9, workspace: "", output: "" }
        props = props.concat([entry(k.prop, defaults[k.control], "")])
    }

    //--- The value an entry sets, or undefined (and a toast) when it isn't valid
    function valueOf(e) {
        if (e.control === "on")
            return e.on
        if (e.control === "choice")
            return e.choices[e.choice].value
        if (e.control === "size") {
            if (e.size < 0)
                return e.value
            if (e.size !== pixelsIndex)
                return wr.sizes[e.size].value
            const px = parseInt(e.px)
            if (px >= 50 && px <= 8000)
                return { fixed: px }
            view.say(`${e.title}: type a size from 50 to 8000 pixels`)
            return undefined
        }
        if (e.control === "opacity") {
            const o = parseFloat(e.typed)
            if (o >= 0.05 && o <= 1)
                return Math.round(o * 100) / 100
            view.say("Type an opacity from 0.05 to 1")
            return undefined
        }
        if (e.control === "workspace" || e.control === "output") {
            if (e.typed.trim())
                return e.typed.trim()
            view.say(`${e.title}: type the name it should open on`)
            return undefined
        }
        return e.value
    }

    function matchList(list) {
        return list.map(m => {
            const out = {}
            if (m.app.trim())
                out["app-id"] = m.app.trim()
            if (m.title.trim())
                out.title = m.title.trim()
            return Object.assign(out, m.extra)
        }).filter(m => Object.keys(m).length)
    }

    function save() {
        const out = {}
        if (nameField.text.trim())
            out.name = nameField.text.trim()
        if (noteField.text.trim())
            out.note = noteField.text.trim()
        out.matches = matchList(matches)
        const left = matchList(excludes)
        if (left.length)
            out.excludes = left
        for (const e of props) {
            const v = valueOf(e)
            if (v === undefined)
                return
            out[e.prop] = v
        }
        if (!props.length) {
            view.say("Give the rule something to do, or remove it")
            return
        }
        Backend.call("saveWindowRule", { index: ed.rule.index, original: ed.rule.raw, rule: out }, reply => {
            const v = ed.view
            ed.saved(reply)  // before closing, which destroys this sheet
            if (reply.ok)
                v.sheet = null
        })
    }

    actions: [
        Pill { text: "Cancel"; quiet: true; onClicked: ed.view.sheet = null },
        Pill { text: "Save"; onClicked: ed.save() }
    ]

    Label { text: "Name" }
    Field { id: nameField; placeholder: "What the list calls it" }
    Label { text: "Note" }
    Field { id: noteField; placeholder: "Why the rule is there" }

    //--- What it does
    Section { text: "What It Does" }
    Repeater {
        model: ed.props
        PropEditor { required property var modelData; required property int index; e: modelData; at: index }
    }
    Label { visible: ed.missing.length > 0; text: "Add"; Layout.topMargin: 4 }
    Flow {
        visible: ed.missing.length > 0
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: ed.missing
            Chip { required property var modelData; text: modelData.title; icon: "add"; onTapped: ed.addProp(modelData) }
        }
    }

    //--- Windows matched and left out
    MatchGroup {
        title: "Windows"
        description: "Regular expressions; a window matching any entry gets the rule."
        list: ed.matches
        onAdd: ed.matches = ed.matches.concat([ed.matchEntry({})])
        onRemove: i => ed.matches = ed.matches.filter((_, j) => j !== i)
        onEdit: (i, key, value) => ed.setMatch(ed.matches, i, key, value)
    }
    MatchGroup {
        title: "Left Out"
        description: "Windows matching these never get the rule."
        list: ed.excludes
        onAdd: ed.excludes = ed.excludes.concat([ed.matchEntry({})])
        onRemove: i => ed.excludes = ed.excludes.filter((_, j) => j !== i)
        onEdit: (i, key, value) => ed.setMatch(ed.excludes, i, key, value)
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
        implicitHeight: cardCol.implicitHeight + 24
        radius: 14
        color: Theme.card
        ColumnLayout {
            id: cardCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8
        }
    }

    //--- One property: its title, a remove button and its control
    component PropEditor: Card {
        id: pe
        property var e
        property int at
        property bool switched: e.on || false
        property int pick: e.control === "choice" ? e.choice : e.control === "size" ? e.size : 0
        onSwitchedChanged: ed.setProp(at, "on", switched)
        onPickChanged: if (e.control === "choice") ed.setProp(at, "choice", pick); else if (e.control === "size") ed.setProp(at, "size", pick)
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: pe.e.title
                color: Theme.text
                font.pixelSize: 15
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }
            Toggle { visible: pe.e.control === "on"; checked: pe.switched; onToggled: on => pe.switched = on }
            IconButton { icon: "delete"; onClicked: ed.props = ed.props.filter((_, j) => j !== pe.at) }
        }
        Flow {
            visible: ["choice", "size"].includes(pe.e.control)
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: pe.e.control === "choice" ? pe.e.choices.map(c => c.label)
                     : pe.e.control === "size" ? ed.wr.sizes.map(s => s.label) : []
                Chip {
                    required property var modelData
                    required property int index
                    text: modelData
                    accent: index === pe.pick
                    onTapped: pe.pick = index
                }
            }
            Chip { tappable: false; visible: pe.e.control === "size" && pe.pick === -1; accent: true; text: `Now ${pe.e.text.replace(/^(Width|Height) /, "")}` }
        }
        Field {
            visible: pe.e.control === "size" && pe.pick === ed.pixelsIndex
            text: pe.e.px || ""
            placeholder: "Pixels"
            onTextChanged: ed.setProp(pe.at, "px", text)
        }
        Field {
            id: typedField
            visible: ["opacity", "workspace", "output"].includes(pe.e.control)
            text: pe.e.typed || ""
            placeholder: pe.e.control === "opacity" ? "0.05 to 1" : pe.e.control === "workspace" ? "Workspace name" : "Monitor name"
            onTextChanged: ed.setProp(pe.at, "typed", text)
        }
        Flow {
            readonly property var names: pe.e.control === "workspace" ? ed.wr.workspaces
                                       : pe.e.control === "output" ? ed.wr.outputs : []
            visible: names.length > 0
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: parent.names
                Chip {
                    required property var modelData
                    text: modelData
                    accent: typedField.text === modelData
                    onTapped: typedField.text = modelData
                }
            }
        }
        Text {
            visible: pe.e.control === ""
            text: `${pe.e.text}. Kept as it is; set in the file.`
            color: Theme.dim
            font.pixelSize: 13
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }

    //--- A list of matches, each an app ID and a title
    component MatchGroup: ColumnLayout {
        id: mg
        property string title
        property string description
        property var list: []
        signal add
        signal remove(int i)
        signal edit(int i, string key, string value)
        Layout.fillWidth: true
        spacing: 6
        RowLayout {
            Layout.fillWidth: true
            Section { text: mg.title }
            Item { Layout.fillWidth: true }
            IconButton { Layout.topMargin: 10; icon: "add"; onClicked: mg.add() }
        }
        Text {
            text: mg.description
            color: Theme.dim
            font.pixelSize: 13
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            Layout.leftMargin: 6
        }
        Repeater {
            model: mg.list
            Card {
                id: mc
                required property var modelData
                required property int index
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        RowLayout {
                            Label { text: "App ID"; Layout.preferredWidth: 52 }
                            Field { text: mc.modelData.app; onTextChanged: mg.edit(mc.index, "app", text) }
                        }
                        RowLayout {
                            Label { text: "Title"; Layout.preferredWidth: 52 }
                            Field { text: mc.modelData.title; onTextChanged: mg.edit(mc.index, "title", text) }
                        }
                    }
                    IconButton { icon: "delete"; onClicked: mg.remove(mc.index) }
                }
                Text {
                    visible: mc.modelData.extraText !== ""
                    text: `${mc.modelData.extraText}, kept as it is`
                    color: Theme.dim
                    font.family: "monospace"
                    font.pixelSize: 13
                    wrapMode: Text.WrapAnywhere
                    Layout.fillWidth: true
                }
            }
        }
    }
}
