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
    readonly property bool atDefault: JSON.stringify(value) === JSON.stringify(s.default)
    readonly property bool overridden: !!s.overridden && (view.scope === view.info.machine)

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 20
    radius: 14
    color: hover.hovered && !open ? Theme.cardHover : Theme.card
    opacity: locked ? 0.6 : 1
    Behavior on color { ColorAnimation { duration: 120 } }

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
            Badge { icon: Theme.glyph(row.s.icon, row.pageGlyph); app: row.s.icon }
            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true
                RowLayout {
                    spacing: 6
                    Text {
                        text: row.s.title
                        color: Theme.text
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Rectangle {
                        visible: row.pending
                        width: 8; height: 8; radius: 4
                        color: Theme.primary
                    }
                }
                Text {
                    visible: text !== ""
                    text: row.s.subtitle
                    color: Theme.dim
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
                Text {
                    visible: row.s.note !== ""
                    text: Theme.rich(row.s.note.includes("!!") ? row.s.note : `!!${row.s.note}!!`)
                    textFormat: Text.StyledText
                    font.pixelSize: 13
                    color: Theme.caution
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
                Text {
                    visible: row.overridden
                    text: "Set for this computer only"
                    color: Theme.primary
                    font.pixelSize: 13
                }
                Text {
                    visible: row.s.kind !== "bool" && !row.open
                    text: row.view.shownOf(row.s, row.value)
                    color: Theme.primary
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
            IconButton {
                visible: !!row.s.module
                icon: "code"
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
                onClicked: row.view.change(row.s, row.s.default)
            }
            Toggle {
                visible: row.s.kind === "bool"
                enabled: !row.locked
                checked: !!row.value
                onToggled: on => row.view.change(row.s, on)
            }
            Icon {
                icon: "expand_more"
                rotation: row.open ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: 150 } }
            }
            TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: row.open = !row.open }
        }

        //--- Opened
        Text {
            visible: row.open && row.s.description !== ""
            text: Theme.rich(row.s.description)
            textFormat: Text.StyledText
            color: Theme.dim
            font.pixelSize: 15
            wrapMode: Text.Wrap
            lineHeight: 1.15
            Layout.fillWidth: true
            Layout.leftMargin: 50
        }
        Text {
            visible: row.open && row.s.kind !== "bool"
            text: `Default: ${row.s.defaultShown}`
            color: Theme.dim
            font.pixelSize: 13
            Layout.leftMargin: 50
        }
        Loader {
            active: row.open && !row.locked && row.s.kind !== "bool"
            visible: active
            Layout.fillWidth: true
            Layout.leftMargin: 50
            Layout.bottomMargin: 4
            sourceComponent: row.s.kind === "text" ? textEditor
                           : row.s.kind === "list" ? listEditor : choiceEditor
        }
    }

    //--- choice, and pick (the list comes from `omni-settings-backend list`)
    Component {
        id: choiceEditor
        ColumnLayout {
            spacing: 4
            readonly property var options: row.s.kind === "pick"
                ? (row.view.lists[row.s.data] || [])
                : row.s.choices
            Component.onCompleted: if (row.s.kind === "pick") row.view.loadList(row.s.data)
            Field {
                id: filter
                visible: options.length > 8
                icon: "search"
                placeholder: "Filter"
            }
            Text {
                visible: row.s.kind === "pick" && !row.view.lists[row.s.data]
                text: "Loading…"
                color: Theme.dim
            }
            ListView {
                id: choices
                Layout.fillWidth: true
                implicitHeight: Math.min(contentHeight, 280)
                clip: true
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                model: options.filter(o => {
                    const q = filter.text.toLowerCase()
                    return !q || String(o.label).toLowerCase().includes(q)
                        || String(o.value).toLowerCase().includes(q)
                })
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool chosen: JSON.stringify(modelData.value) === JSON.stringify(row.value)
                    width: choices.width
                    height: 34
                    radius: 10
                    color: chosen ? Theme.selected : optHover.hovered ? Theme.cardHover : "transparent"
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        Text {
                            text: modelData.label
                            color: chosen ? Theme.inkSelected : Theme.text
                            font.pixelSize: 15
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Icon { visible: chosen; icon: "check"; size: 18; color: Theme.primary }
                    }
                    HoverHandler { id: optHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: row.view.change(row.s, modelData.value) }
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
