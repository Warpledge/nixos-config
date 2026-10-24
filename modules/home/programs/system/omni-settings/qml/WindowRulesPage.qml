// Window Rules (Niri tab): the rules in window-rules.json by group, a form that
// adds one for a picked window, and the rules Nix sets (api.py's windowRules)
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    property var wr: null
    property string error: ""
    property bool showIds: false
    property bool picking: false
    property var windows: null  // the Open Windows list, null while closed
    readonly property bool niri: !!view.info && view.info.wm === "niri"
    readonly property bool editable: !!wr && wr.editable
    spacing: 6

    Component.onCompleted: if (niri) load()

    function load() {
        Backend.call("windowRules", {}, reply => {
            if (reply.ok) {
                wr = reply.data
                error = ""
            } else
                error = reply.error
        })
    }

    //--- Group chip kinds as tones
    function tone(kind) {
        return kind === "success" ? "success" : kind === "warning" ? "caution" : kind === "error" ? "error" : ""
    }

    //--------------------------------------------------------------------//
    //-- Picking a window and adding a rule
    //--------------------------------------------------------------------//
    property var picked: null
    property int kindIndex: 0
    property int choiceIndex: 0
    property int sizeIndex: 1
    property int placeIndex: 0
    readonly property var kind: wr ? wr.kinds[kindIndex] : null
    readonly property var places: !kind ? [] : kind.control === "workspace" ? wr.workspaces
                                       : kind.control === "output" ? wr.outputs : []

    function pick() {
        picking = true
        view.say("Click the window to make a rule for")
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

    function regex(text) {
        return "^" + text.replace(/[\\.+*?()|[\]{}^$]/g, "\\$&") + "$"
    }

    function use(w) {
        windows = null
        picked = w
        nameField.text = w.name
        appField.text = w.appId ? regex(w.appId) : ""
        titleField.text = w.title ? regex(w.title) : ""
        matchTitle.checked = !w.appId
        fillPixels()
        view.say(`Picked ${w.name}`)
    }

    function fillPixels() {
        if (picked && kind && kind.control === "size" && picked.size.length === 2)
            pixels.text = String(picked.size[kind.prop === "default-column-width" ? 0 : 1])
    }

    function setKind(i) {
        kindIndex = i
        choiceIndex = 0
        placeIndex = 0
        fillPixels()
    }

    //--- The value the form sets, or undefined (and a toast) when it isn't valid
    function value() {
        const c = kind.control
        if (c === "on")
            return true
        if (c === "choice")
            return kind.choices[choiceIndex].value
        if (c === "size") {
            const v = wr.sizes[sizeIndex].value
            if (v !== null)
                return v
            const px = parseInt(pixels.text)
            if (!(px >= 50 && px <= 8000)) {
                view.say("Type a size from 50 to 8000 pixels")
                return undefined
            }
            return { fixed: px }
        }
        if (c === "opacity") {
            const o = parseFloat(opacityField.text)
            if (!(o >= 0.05 && o <= 1)) {
                view.say("Type an opacity from 0.05 to 1")
                return undefined
            }
            return Math.round(o * 100) / 100
        }
        if (page.places.length)
            return page.places[placeIndex]
        const typed = placeField.text.trim()
        if (!typed)
            view.say("Type the name it should open on")
        return typed || undefined
    }

    function add() {
        const app = appField.text.trim(), title = matchTitle.checked ? titleField.text.trim() : ""
        if (!app && !title) {
            view.say("Pick a window, or type an app ID or title")
            return
        }
        const v = value()
        if (v === undefined)
            return
        Backend.call("addWindowRule", { appId: app, title, name: nameField.text, prop: kind.prop, value: v },
                     saved)
    }

    function remove(rule) {
        Backend.call("removeWindowRule", { index: rule.index }, saved)
    }

    //--- A change's reply: its toast offers Undo, which puts the file back as it was
    function saved(reply) {
        if (!reply.ok) {
            view.say(`Couldn't save the rules: ${reply.error}`)
            return
        }
        const undo = reply.data.undo
        view.say(reply.data.text, { label: "Undo", run: () => Backend.call("undoWindowRules", undo, r => {
            view.say(r.ok ? r.data : `Couldn't undo: ${r.error}`)
            load()
        }) })
        load()
    }

    function rebuild() {
        view.ask({
            heading: "Rebuild now?",
            body: "Rebuilds from your settings files as they are (nixos-rebuild switch), which gives niri "
                  + "the rules changed here.",
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
                Badge { implicitWidth: 56; implicitHeight: 56; radius: 28; icon: "view_quilt" }
                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    Text { text: "Window Rules"; color: Theme.text; font.pixelSize: 22; font.weight: Font.Bold }
                    Text {
                        text: !page.niri
                            ? `These rules are niri's, and this computer runs ${page.view.info && page.view.info.wm || "another"} window manager.`
                            : !page.wr || page.editable
                            ? "Pick a window, choose what niri should do with it, and the rule joins the list "
                              + "below. A rebuild applies it."
                            : "Only an admin who can edit the config's files can add window rules."
                        color: Theme.dim
                        font.pixelSize: 13
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }
            Flow {
                visible: page.editable
                Layout.fillWidth: true
                spacing: 8
                Pill { text: page.picking ? "Click a Window…" : "Pick a Window"; enabled: !page.picking; onClicked: page.pick() }
                Pill { text: page.windows ? "Hide Open Windows" : "Open Windows"; quiet: true; onClicked: page.listWindows() }
            }
        }
    }

    Text {
        visible: page.error !== ""
        text: page.error
        color: Theme.error
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        Layout.margins: 6
    }

    //--- The windows open now; a click fills the form
    Section { visible: !!page.windows; text: "Open Windows" }
    Text {
        visible: !!page.windows && page.windows.length === 0
        text: "Loading…"
        color: Theme.dim
        Layout.leftMargin: 6
    }
    Repeater {
        model: page.windows || []
        ListRow {
            required property var modelData
            compact: true
            icon: "view_quilt"
            app: modelData.appId ? [modelData.appId, modelData.appId.toLowerCase()] : []
            title: modelData.title || modelData.name || "Untitled"
            subtitle: modelData.appId || "no app ID"
            onClicked: page.use(modelData)
        }
    }

    //--------------------------------------------------------------------//
    //-- New rule
    //--------------------------------------------------------------------//
    Section { visible: page.editable; text: "New Rule" }
    Rectangle {
        visible: page.editable
        Layout.fillWidth: true
        implicitHeight: form.implicitHeight + 28
        radius: 16
        color: Theme.card
        ColumnLayout {
            id: form
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8
            Text {
                text: "Filled in from the window you pick; the app ID and title are regular expressions."
                color: Theme.dim
                font.pixelSize: 13
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }
            Label { text: "Name" }
            Field { id: nameField; placeholder: "What the list calls it" }
            Label { text: "App ID" }
            Field { id: appField; placeholder: "^org\\.example\\.App$" }
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 12
                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true
                    Text { text: "Match the Title Too"; color: Theme.text; font.pixelSize: 15 }
                    Text {
                        text: page.picked ? (page.picked.title || "This window has no title")
                                          : "For one window of an app, like a dialog or popout"
                        color: Theme.dim
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
                Toggle { id: matchTitle; onToggled: on => checked = on }
            }
            Field { id: titleField; visible: matchTitle.checked; placeholder: "^Title$" }

            Label { text: "Rule"; Layout.topMargin: 4 }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: page.wr ? page.wr.kinds : []
                    Chip {
                        required property var modelData
                        required property int index
                        text: modelData.title
                        accent: index === page.kindIndex
                        onTapped: page.setKind(index)
                    }
                }
            }

            //--- The value, by the rule's control
            Label { visible: !!page.kind && page.kind.control !== "on"; text: "Value"; Layout.topMargin: 4 }
            Flow {
                visible: !!page.kind && ["choice", "size"].includes(page.kind.control) || page.places.length > 0
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: !page.kind ? [] : page.kind.control === "choice" ? page.kind.choices.map(c => c.label)
                         : page.kind.control === "size" ? page.wr.sizes.map(s => s.label) : page.places
                    Chip {
                        required property var modelData
                        required property int index
                        text: modelData
                        accent: index === (page.kind.control === "choice" ? page.choiceIndex
                                         : page.kind.control === "size" ? page.sizeIndex : page.placeIndex)
                        onTapped: {
                            if (page.kind.control === "choice")
                                page.choiceIndex = index
                            else if (page.kind.control === "size")
                                page.sizeIndex = index
                            else
                                page.placeIndex = index
                        }
                    }
                }
            }
            Field {
                id: pixels
                visible: !!page.kind && page.kind.control === "size" && page.wr.sizes[page.sizeIndex].value === null
                text: "800"
                placeholder: page.kind && page.kind.prop === "default-column-width" ? "Width in pixels" : "Height in pixels"
            }
            Field {
                id: opacityField
                visible: !!page.kind && page.kind.control === "opacity"
                text: "0.9"
                placeholder: "0.05 to 1"
            }
            Field {
                id: placeField
                visible: !!page.kind && ["workspace", "output"].includes(page.kind.control) && page.places.length === 0
                placeholder: page.kind && page.kind.control === "workspace" ? "Workspace name" : "Monitor name"
            }
            Pill { text: "Add Rule"; Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 6; onClicked: page.add() }
        }
    }

    ListRow {
        visible: !!page.wr && page.wr.waiting
        Layout.topMargin: 6
        icon: "sync"
        tone: "caution"
        title: "Not Applied Yet"
        subtitle: "Rebuild to give niri the rules changed here."
        button: page.view.info && page.view.info.canApply && page.view.info.admin ? "Rebuild" : ""
        onClicked: if (button) page.rebuild()
    }

    //--------------------------------------------------------------------//
    //-- The rules
    //--------------------------------------------------------------------//
    RowLayout {
        visible: !!page.wr
        Layout.fillWidth: true
        Section { text: "Rules" }
        Item { Layout.fillWidth: true }
        Chip {
            Layout.topMargin: 10
            text: "Show App IDs"
            icon: page.showIds ? "check" : ""
            accent: page.showIds
            onTapped: page.showIds = !page.showIds
        }
    }
    Text {
        visible: !!page.wr
        text: "Later rules win where two set the same thing."
        color: Theme.dim
        font.pixelSize: 13
        Layout.leftMargin: 6
    }

    Repeater {
        model: page.wr ? page.wr.groups : []
        RuleGroup {
            required property var modelData
            title: modelData.title
            description: modelData.description
            icon: modelData.icon
            tone: page.tone(modelData.kind)
            rules: modelData.rules
        }
    }
    RuleGroup {
        visible: !!page.wr && page.wr.fromNix.length > 0
        title: "Set in Nix"
        description: "Theme styling, the translucent app list and this computer's own rules. These are "
                     + "edited in the config's Nix files, not here."
        icon: "applications-system"
        rules: page.wr ? page.wr.fromNix : []
    }

    component Label: Text {
        color: Theme.dim
        font.pixelSize: 13
        font.weight: Font.DemiBold
        Layout.leftMargin: 4
    }

    //--- A group heading with its count, then its rules
    component RuleGroup: ColumnLayout {
        id: group
        property string title
        property string description
        property string icon
        property string tone: ""
        property var rules: []
        Layout.fillWidth: true
        spacing: 6
        RowLayout {
            Layout.topMargin: 10
            Layout.leftMargin: 6
            spacing: 8
            Icon { icon: Theme.glyph(group.icon, "settings"); size: 18; color: Theme.primary }
            Text { text: group.title; color: Theme.primary; font.pixelSize: 15; font.weight: Font.DemiBold }
            Chip { text: String(group.rules.length); tone: group.tone; accent: group.tone === "" && group.title !== "Set in Nix" }
        }
        Text {
            visible: text !== ""
            text: group.description
            color: Theme.dim
            font.pixelSize: 13
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.bottomMargin: 2
        }
        Repeater {
            model: group.rules
            RuleRow { required property var modelData; rule: modelData }
        }
    }

    //--- One rule: name, tags coloured by group, and the windows it matches when opened
    component RuleRow: Rectangle {
        id: row
        property var rule
        property bool open: false
        readonly property int count: rule.matches.length
        Layout.fillWidth: true
        implicitHeight: ruleCol.implicitHeight + 22
        radius: 14
        color: hover.hovered ? Theme.cardHover : Theme.card
        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: row.open = !row.open }
        ColumnLayout {
            id: ruleCol
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            spacing: 6
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Badge { icon: "view_quilt"; app: row.rule.app ? [row.rule.app, row.rule.app.toLowerCase()] : [] }
                ColumnLayout {
                    spacing: 4
                    Layout.fillWidth: true
                    Text {
                        text: row.rule.title
                        color: Theme.text
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 4
                        Repeater {
                            model: row.rule.tags
                            Chip {
                                required property var modelData
                                text: modelData.text
                                tone: page.tone(modelData.kind)
                                accent: modelData.kind === "accent"
                            }
                        }
                    }
                }
                Text {
                    visible: row.count !== 1
                    text: row.count ? `${row.count} windows` : "all windows"
                    color: Theme.dim
                    font.pixelSize: 13
                }
                IconButton {
                    visible: page.editable && row.rule.index !== null
                    icon: "delete"
                    onClicked: page.remove(row.rule)
                }
                Icon { icon: row.open ? "expand_less" : "expand_more"; size: 18 }
            }
            Text {
                visible: row.open && row.rule.note !== ""
                text: row.rule.note
                color: Theme.dim
                font.pixelSize: 13
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.leftMargin: 50
            }
            Repeater {
                model: row.open ? row.rule.matches.map(m => Object.assign({ out: false }, m))
                                  .concat(row.rule.excludes.map(m => Object.assign({ out: true }, m))) : []
                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.leftMargin: 50
                    spacing: 10
                    Badge {
                        implicitWidth: 24
                        implicitHeight: 24
                        radius: 12
                        icon: "view_quilt"
                        app: modelData.app ? [modelData.app, modelData.app.toLowerCase()] : []
                    }
                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true
                        Text {
                            text: modelData.name
                            color: Theme.text
                            font.pixelSize: 15
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            visible: page.showIds
                            text: modelData.pattern
                            color: Theme.dim
                            font.family: "monospace"
                            font.pixelSize: 13
                            wrapMode: Text.WrapAnywhere
                            Layout.fillWidth: true
                        }
                    }
                    Chip { visible: modelData.out; text: "Left out"; tone: "caution" }
                }
            }
        }
    }
}
