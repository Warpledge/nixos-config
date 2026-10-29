// One generated setting: the row, and its description and editor when opened
import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: row
    required property var setting
    required property var view
    property bool locked: false
    property string pageGlyph: "settings"
    property bool open: false

    readonly property var s: setting
    readonly property var value: view.valueOf(s)
    readonly property bool pending: view.pending[s.key] !== undefined
        || (!!s.pair && view.pending[s.pair.key] !== undefined)
    readonly property bool atDefault: JSON.stringify(value) === JSON.stringify(s.default)
        && (!s.pair || JSON.stringify(view.valueOf(s.pair)) === JSON.stringify(s.pair.default))
    readonly property bool overridden: !!s.overridden && (view.scope === view.info.machine)
    // A switch with nothing more to say has no dropdown
    readonly property bool expandable: s.description !== "" || s.kind !== "bool" || !!s.pair
    readonly property color accent: Theme.accentOf(row)

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 20
    radius: 16
    color: Theme.rowFill(accent, hover.hovered && !open)
    border.width: 1
    border.color: Theme.rowBorder(accent, open)
    opacity: locked ? 0.6 : 1
    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    HoverHandler { id: hover }

    ColumnLayout {
        id: col
        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 12
        spacing: 10

        //--- Header: tapping it opens the description and editor
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Badge { icon: Theme.glyph(row.s.icon, row.pageGlyph); app: row.s.icon; implicitWidth: 34; implicitHeight: 34 }
            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true
                RowLayout {
                    spacing: 6
                    Layout.fillWidth: true
                    Text {
                        id: titleText
                        text: row.s.title
                        color: Theme.text
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        // Its full width, so the indicators sit right after the name
                        Layout.maximumWidth: Math.ceil(titleWidth.advanceWidth) + 1
                        Layout.fillWidth: true
                        TextMetrics { id: titleWidth; font: titleText.font; text: titleText.text }
                    }
                    //--- Cautions and notes as indicators, read at the cursor
                    Hint {
                        visible: row.s.note !== ""
                        tip: Theme.plain(row.s.note)
                    }
                    Hint {
                        visible: row.overridden
                        icon: "computer"
                        tone: ""
                        tip: "Set for this computer only; other computers keep your own setting"
                    }
                    Rectangle {
                        visible: row.pending
                        width: 8; height: 8; radius: 4
                        color: row.accent
                    }
                    Item { Layout.fillWidth: true }
                }
                Text {
                    visible: text !== ""
                    text: row.s.subtitle
                    color: Theme.dim
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    Layout.fillWidth: true
                }
            }
            IconButton {
                visible: !!row.s.module
                icon: "code"
                tip: "Open its module in your editor"
                onClicked: row.view.openFile(row.s.module)
            }
            IconButton {
                visible: !!row.s.resettable
                icon: "restart_alt"
                tip: row.s.resettable ? `Reset ${row.s.resettable.app}'s settings to the config's` : ""
                onClicked: row.view.resetApp(row.s)
            }
            IconButton {
                visible: row.s.kind !== "bool" && !row.atDefault && !row.locked
                icon: "settings_backup_restore"
                tip: `Back to the default (${row.s.defaultShown})`
                onClicked: {
                    row.view.change(row.s, row.s.default)
                    if (row.s.pair)
                        row.view.change(row.s.pair, row.s.pair.default)
                }
            }
            //--- The current value, as the group cards show their count
            Rectangle {
                visible: row.s.kind !== "bool"
                implicitWidth: Math.min(valueText.implicitWidth + 20, row.width * 0.36)
                implicitHeight: 26
                radius: 13
                color: Qt.alpha(row.accent, 0.18)
                border.width: 1
                border.color: Qt.alpha(row.accent, 0.3)
                Text {
                    id: valueText
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: row.view.shownOf(row.s, row.value) + (row.s.pair
                        ? ` · ${row.view.shownOf(row.s.pair, row.view.valueOf(row.s.pair))}` : "")
                    color: row.accent
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }
            Toggle {
                visible: row.s.kind === "bool"
                enabled: !row.locked
                checked: !!row.value
                onToggled: on => row.view.change(row.s, on)
            }
            Chevron {
                visible: row.expandable
                open: row.open
                lit: hover.hovered
            }
            TapHandler {
                enabled: row.expandable
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: row.open = !row.open
            }
        }

        //--- Opened: an inset panel under the header
        Reveal {
            id: opened
            open: row.open && row.expandable
            gap: col.spacing
            Rectangle {
                Layout.fillWidth: true
                Layout.bottomMargin: 2
                implicitHeight: inset.implicitHeight + 24
                radius: 12
                color: Qt.alpha(Theme.bg, 0.55)
                border.width: 1
                border.color: Qt.alpha(row.accent, 0.1)
                ColumnLayout {
                    id: inset
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 12
                    spacing: 10
                    Text {
                        visible: row.s.description !== ""
                        text: Theme.rich(row.s.description)
                        textFormat: Text.StyledText
                        color: Theme.dim
                        font.pixelSize: 15
                        wrapMode: Text.Wrap
                        lineHeight: 1.15
                        Layout.fillWidth: true
                    }
                    Text {
                        visible: row.s.kind !== "bool"
                        text: `Default: ${row.s.defaultShown}`
                        color: Theme.dim
                        font.pixelSize: 13
                    }
                    Loader {
                        active: opened.shown && !row.locked && row.s.kind !== "bool"
                        visible: active
                        Layout.fillWidth: true
                        sourceComponent: row.s.kind === "text" ? textEditor
                                       : row.s.kind === "number" ? numberEditor
                                       : row.s.kind === "list" ? listEditor : choiceEditor
                    }
                    //--- The paired setting's choices (schema.py's PAIRS), under its own title
                    Text {
                        visible: !!row.s.pair
                        text: row.s.pair ? `${row.s.pair.title} · Default: ${row.s.pair.defaultShown}` : ""
                        color: Theme.dim
                        font.pixelSize: 13
                    }
                    Loader {
                        active: opened.shown && !row.locked && !!row.s.pair
                        visible: active
                        Layout.fillWidth: true
                        sourceComponent: choiceEditor
                        onLoaded: item.subject = row.s.pair
                    }
                }
            }
        }
    }

    //--- choice, and pick (the list comes from `omni-settings-backend list`);
    //--- `subject` is this row's setting or its pair's; not `target`, TapHandler's own
    Component {
        id: choiceEditor
        ColumnLayout {
            id: editor
            spacing: 4
            property var subject: row.s
            readonly property var subjectValue: row.view.valueOf(subject)
            readonly property var options: subject.kind === "pick"
                ? (row.view.lists[subject.data] || [])
                : subject.choices
            Component.onCompleted: if (subject.kind === "pick") row.view.loadList(subject.data)
            Field {
                id: filter
                visible: options.length > 8
                icon: "search"
                placeholder: "Filter"
            }
            Text {
                visible: editor.subject.kind === "pick" && !row.view.lists[editor.subject.data]
                text: "Loading…"
                color: Theme.dim
            }
            ListView {
                id: choices
                Layout.fillWidth: true
                implicitHeight: Math.min(contentHeight, 280)
                clip: true
                spacing: 4
                boundsBehavior: Flickable.StopAtBounds
                model: options.filter(o => {
                    const q = filter.text.toLowerCase()
                    return !q || String(o.label).toLowerCase().includes(q)
                        || String(o.value).toLowerCase().includes(q)
                })
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool chosen: JSON.stringify(modelData.value) === JSON.stringify(editor.subjectValue)
                    width: choices.width
                    height: 36
                    radius: 10
                    color: Qt.alpha(row.accent, chosen ? 0.2 : optHover.hovered ? 0.1 : 0.03)
                    border.width: chosen ? 1 : 0
                    border.color: Qt.alpha(row.accent, 0.4)
                    Behavior on color { ColorAnimation { duration: 120 } }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10
                        //--- A radio: a ring, with an accent dot in the chosen one
                        Rectangle {
                            implicitWidth: 16
                            implicitHeight: 16
                            radius: 8
                            color: "transparent"
                            border.width: 2
                            border.color: chosen ? row.accent : Qt.alpha(Theme.dim, 0.6)
                            Rectangle {
                                anchors.centerIn: parent
                                width: chosen ? 8 : 0
                                height: width
                                radius: width / 2
                                color: row.accent
                                Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                            }
                        }
                        Text {
                            text: modelData.label
                            color: chosen ? row.accent : Theme.text
                            font.pixelSize: 15
                            font.weight: chosen ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                    HoverHandler { id: optHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: row.view.change(editor.subject, modelData.value) }
                }
            }
        }
    }

    //--- text; an empty nullable field means "Not set"
    Component {
        id: textEditor
        RowLayout {
            spacing: 8
            Field {
                id: textField
                text: row.value ?? ""
                placeholder: row.s.nullable ? "Not set" : ""
                onAccepted: set()
                function set() {
                    row.view.change(row.s, text === "" && row.s.nullable ? null : text)
                }
            }
            Pill { text: "Set"; onClicked: textField.set() }
        }
    }

    //--- number: whole numbers, e.g. the boot menu's timeout in seconds
    Component {
        id: numberEditor
        RowLayout {
            spacing: 8
            Field {
                id: numberField
                text: row.value ?? ""
                placeholder: "A whole number"
                onAccepted: set()
                function set() {
                    const t = text.trim()
                    if (!/^[0-9]+$/.test(t)) {
                        row.view.say("A whole number of 0 or more, like 5")
                        return
                    }
                    row.view.change(row.s, parseInt(t))
                }
            }
            Pill { text: "Set"; onClicked: numberField.set() }
        }
    }

    //--- list: a switch per option, or chips plus a field to add one
    Component {
        id: listEditor
        ColumnLayout {
            spacing: 6
            readonly property var items: row.value || []
            readonly property var names: row.s.options.concat(items.filter(x => !row.s.options.includes(x)))
            Repeater {
                model: row.s.options.length ? names : []
                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    Text {
                        text: modelData
                        color: Theme.text
                        font.pixelSize: 15
                        Layout.fillWidth: true
                    }
                    Toggle {
                        checked: items.includes(modelData)
                        onToggled: on => row.view.change(row.s, on
                            ? names.filter(n => n === modelData || items.includes(n))
                            : items.filter(n => n !== modelData))
                    }
                }
            }
            Flow {
                visible: !row.s.options.length
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: row.s.options.length ? [] : items
                    Chip {
                        required property var modelData
                        text: String(modelData)
                        icon: "close"
                        onTapped: row.view.change(row.s, items.filter(x => x !== modelData))
                    }
                }
            }
            RowLayout {
                visible: !row.s.options.length
                spacing: 8
                Field {
                    id: addField
                    placeholder: row.s.ports ? "Add a port number" : "Add one"
                    onAccepted: add()
                    function add() {
                        const t = text.trim()
                        const v = row.s.ports ? parseInt(t) : t
                        if (row.s.ports && !(v >= 1 && v <= 65535 && String(v) === t)) {
                            row.view.say("A port is a number from 1 to 65535")
                            return
                        }
                        if (t !== "" && !items.includes(v))
                            row.view.change(row.s, items.concat([v]))
                        text = ""
                    }
                }
                Pill { text: "Add"; onClicked: addField.add() }
            }
        }
    }
}
