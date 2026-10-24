// Edits one keybind: the config's own (its title, key and on/off) or one of the
// user's custom- binds (also what it runs: a command, or a niri action). A bind
// with {pick: true} starts by picking a window to launch or focus.
import QtQuick
import QtQuick.Layouts

Sheet {
    id: ed
    required property var view
    required property var kb  // KeybindsPage: actions, clashes, setOverride
    required property var bind  // a row from kb.rows, or {} for a new bind
    readonly property bool isNew: !bind.id
    readonly property bool custom: isNew || bind.custom
    title: isNew ? "New Keybind" : `Edit ${bind.title}`
    onBack: view.sheet = null

    readonly property var modifiers: ["Mod", "Ctrl", "Alt", "Shift"]
    property var mods: []
    property bool useAction: false
    property string actionName: ""
    property string actionQuery: ""
    property var picked: null
    property bool picking: false
    property var windows: null
    property bool recording: false

    Component.onCompleted: {
        const parts = (bind.key || "").split("+")
        keyField.text = parts.length ? parts[parts.length - 1] : ""
        mods = modifiers.filter(m => parts.slice(0, -1).some(p => p.toLowerCase() === m.toLowerCase()))
        titleField.text = bind.title || ""
        if (bind.custom) {
            const o = bind.raw
            useAction = !!o.action
            actionName = o.action || ""
            argField.text = o.argument || ""
            commandField.text = o.spawn ? kb.joinCommand(o.spawn) : ""
        }
        if (bind.pick)
            pick()
    }

    readonly property string key: mods.concat([keyField.text.trim()]).filter(p => p).join("+")
    readonly property var clash: keyField.text.trim() ? kb.clashes(key, bind.id || "") : []

    function toggleMod(m) {
        mods = mods.includes(m) ? mods.filter(x => x !== m) : modifiers.filter(x => x === m || mods.includes(x))
    }

    //--------------------------------------------------------------------//
    //-- Recording a key
    //--------------------------------------------------------------------//
    //--- Qt key codes to the names niri's binds use (xkb keysyms)
    readonly property var keyNames: ({
        [Qt.Key_Return]: "Return", [Qt.Key_Enter]: "KP_Enter", [Qt.Key_Space]: "space", [Qt.Key_Tab]: "Tab",
        [Qt.Key_Escape]: "Escape", [Qt.Key_Backspace]: "BackSpace", [Qt.Key_Delete]: "Delete",
        [Qt.Key_Insert]: "Insert", [Qt.Key_Home]: "Home", [Qt.Key_End]: "End",
        [Qt.Key_PageUp]: "Page_Up", [Qt.Key_PageDown]: "Page_Down", [Qt.Key_Left]: "Left",
        [Qt.Key_Right]: "Right", [Qt.Key_Up]: "Up", [Qt.Key_Down]: "Down", [Qt.Key_Minus]: "Minus",
        [Qt.Key_Plus]: "Plus", [Qt.Key_Equal]: "Equal", [Qt.Key_Comma]: "Comma", [Qt.Key_Period]: "Period",
        [Qt.Key_Slash]: "Slash", [Qt.Key_Backslash]: "Backslash", [Qt.Key_Semicolon]: "Semicolon",
        [Qt.Key_Apostrophe]: "Apostrophe", [Qt.Key_BracketLeft]: "BracketLeft",
        [Qt.Key_BracketRight]: "BracketRight", [Qt.Key_QuoteLeft]: "grave", [Qt.Key_Print]: "Print"
    })
    function keyName(e) {
        if (e.key >= Qt.Key_A && e.key <= Qt.Key_Z || e.key >= Qt.Key_0 && e.key <= Qt.Key_9)
            return String.fromCharCode(e.key)
        if (e.key >= Qt.Key_F1 && e.key <= Qt.Key_F24)
            return `F${e.key - Qt.Key_F1 + 1}`
        return keyNames[e.key] || ""
    }
    Item {
        id: recorder
        focus: ed.recording
        Keys.onPressed: e => {
            if (!ed.recording)
                return
            const name = ed.keyName(e)
            if (!name)
                return  // a modifier alone, or a key with no name here
            e.accepted = true
            keyField.text = name
            const m = []
            if (e.modifiers & Qt.ControlModifier) m.push("Ctrl")
            if (e.modifiers & Qt.AltModifier) m.push("Alt")
            if (e.modifiers & Qt.ShiftModifier) m.push("Shift")
            if (m.length)
                ed.mods = ed.modifiers.filter(x => x === "Mod" && ed.mods.includes("Mod") || m.includes(x))
            ed.recording = false
        }
    }

    //--------------------------------------------------------------------//
    //-- Picking a window
    //--------------------------------------------------------------------//
    function pick() {
        picking = true
        view.say("Click the window to make a keybind for")
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
            else {
                windows = null
                view.say(`Couldn't list the windows: ${reply.error}`)
            }
        })
    }

    function use(w) {
        windows = null
        picked = w
        useAction = false
        if (!titleField.text)
            titleField.text = w.name
        Backend.call("launchCommand", { appId: w.appId }, reply => {
            const cmd = reply.ok ? reply.data : []
            commandField.text = kb.joinCommand(cmd)
            view.say(cmd.length ? `Picked ${w.name}` : `Picked ${w.name}; type the command that starts it`)
        })
    }

    function regex(text) {
        return "^" + text.replace(/[\\.+*?()|[\]{}^$]/g, "\\$&") + "$"
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

    //--------------------------------------------------------------------//
    //-- Saving
    //--------------------------------------------------------------------//
    function slug(text) {
        const s = text.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "")
        return s || "keybind"
    }

    function save() {
        const title = titleField.text.trim()
        if (!keyField.text.trim()) {
            view.say("Pick a key")
            return
        }
        if (!title) {
            view.say("Give the keybind a name")
            return
        }
        if (clash.length) {
            view.say(`${key} is already ${kb.titleOf(clash[0])}; turn that off or pick another key`)
            return
        }
        if (!custom) {
            const o = {}
            if (key !== bind.default.key)
                o.key = key
            if (title !== bind.default.title)
                o.title = title
            if (bind.enable !== bind.default.enable)
                o.enable = bind.enable
            kb.setOverride(bind.id, o)
            view.sheet = null
            return
        }
        const o = { key, title }
        if (useAction) {
            if (!kb.actions.includes(actionName)) {
                view.say("Choose a niri action")
                return
            }
            o.action = actionName
            if (argField.text.trim())
                o.argument = argField.text.trim()
        } else {
            let cmd = splitCommand(commandField.text)
            if (!cmd.length) {
                view.say("Type the command to run")
                return
            }
            if (picked && picked.appId && focusOpen.checked && cmd[0] !== "nirius")
                cmd = ["nirius", "focus-or-spawn", "--app-id", regex(picked.appId)].concat(cmd)
            o.spawn = cmd
        }
        if (!isNew && bind.enable === false)
            o.enable = false
        let id = bind.id
        if (isNew) {
            id = `custom-${slug(title)}`
            for (let n = 2; id in kb.now; n++)
                id = `custom-${slug(title)}-${n}`
        }
        kb.setOverride(id, o)
        view.sheet = null
    }

    actions: [
        Pill { text: "Cancel"; quiet: true; onClicked: ed.view.sheet = null },
        Pill {
            visible: !ed.custom && ed.bind.changed
            text: "Back to Default"
            quiet: true
            onClicked: {
                ed.kb.setOverride(ed.bind.id, null)
                ed.view.sheet = null
            }
        },
        Pill { text: ed.isNew ? "Add" : "Done"; onClicked: ed.save() }
    ]

    //--------------------------------------------------------------------//
    //-- Form
    //--------------------------------------------------------------------//
    Card {
        Label { text: "Name" }
        Field { id: titleField; placeholder: "What the cheatsheet (Mod+/) calls it" }

        Label { text: "Keys"; Layout.topMargin: 4 }
        Flow {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: ed.modifiers
                Chip {
                    required property string modelData
                    text: modelData === "Mod" ? "Mod (Super)" : modelData
                    accent: ed.mods.includes(modelData)
                    icon: ed.mods.includes(modelData) ? "check" : ""
                    onTapped: ed.toggleMod(modelData)
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Field { id: keyField; placeholder: "A key: T, Return, F5, XF86AudioPlay…" }
            Pill {
                text: ed.recording ? "Press a Key…" : "Record"
                quiet: !ed.recording
                onClicked: {
                    ed.recording = !ed.recording
                    if (ed.recording)
                        recorder.forceActiveFocus()
                }
            }
        }
        Text {
            text: ed.recording ? "Press the key, with Ctrl, Alt or Shift if you like. Add Mod with its chip: "
                                 + "niri keeps Mod combinations for itself."
                 : ed.clash.length ? `${ed.key} is already ${ed.clash.map(ed.kb.titleOf).join(", ")}.`
                 : ed.kb.dmsSets(ed.key) ? `${ed.key}: the shell's own shortcut on this key wins.`
                 : ed.key
            color: ed.clash.length ? Theme.error : ed.kb.dmsSets(ed.key) ? Theme.caution : Theme.dim
            font.pixelSize: 13
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
        Text {
            visible: !ed.custom
            text: `Default: ${ed.bind.default ? ed.bind.default.key + " · " + ed.bind.default.title : ""}`
            color: Theme.dim
            font.pixelSize: 13
            Layout.fillWidth: true
        }
    }

    //--- What a config bind does stays the config's
    Card {
        visible: !ed.custom
        Label { text: "What It Does" }
        Text {
            text: ed.bind.action || ""
            color: Theme.text
            font.family: "monospace"
            font.pixelSize: 13
            wrapMode: Text.WrapAnywhere
            Layout.fillWidth: true
        }
        Text {
            text: "Set in the config. Add your own keybind to run something else."
            color: Theme.dim
            font.pixelSize: 13
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }

    Card {
        visible: ed.custom
        Label { text: "What It Does" }
        Flow {
            Layout.fillWidth: true
            spacing: 6
            Chip { text: "Run a Command"; accent: !ed.useAction; onTapped: ed.useAction = false }
            Chip { text: "Niri Action"; accent: ed.useAction; onTapped: ed.useAction = true }
        }

        //--- A command, filled in from a picked window
        ColumnLayout {
            visible: !ed.useAction
            Layout.fillWidth: true
            spacing: 8
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
            Field { id: commandField; placeholder: "Command, e.g. obsidian or kitty -e btop" }
            RowLayout {
                visible: !!ed.picked && !!ed.picked.appId
                Layout.fillWidth: true
                spacing: 12
                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true
                    Text { text: "Focus It If Open"; color: Theme.text; font.pixelSize: 15 }
                    Text {
                        text: ed.picked ? `Goes to an open ${ed.picked.name} window instead of starting another (nirius)` : ""
                        color: Theme.dim
                        font.pixelSize: 13
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
                Toggle { id: focusOpen; checked: true; onToggled: on => checked = on }
            }
        }

        //--- One of niri's actions, with an optional argument
        ColumnLayout {
            visible: ed.useAction
            Layout.fillWidth: true
            spacing: 8
            Field {
                icon: "search"
                placeholder: ed.actionName || "Find an action: focus, move, workspace…"
                onTextChanged: ed.actionQuery = text
            }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: ed.kb.actions.filter(a => !ed.actionQuery || a.includes(ed.actionQuery.toLowerCase()))
                                          .filter(a => !["spawn", "spawn-sh", "quit"].includes(a)).slice(0, 40)
                    Chip {
                        required property string modelData
                        text: modelData
                        accent: modelData === ed.actionName
                        onTapped: ed.actionName = modelData
                    }
                }
            }
            Label { text: "Argument" }
            Field { id: argField; placeholder: "If the action takes one: 3, 50%, +10%…" }
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
