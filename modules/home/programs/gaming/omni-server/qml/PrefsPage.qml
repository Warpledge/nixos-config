// How Omni Server looks (Prefs.qml, ~/.config/omni-server/appearance.json): the look
// both apps share, then the console and tab bar, and the keyboard shortcuts
import QtQuick
import QtQuick.Layouts

Flickable {
    id: page
    property var app
    contentHeight: col.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    component Row_: RowLayout {
        id: prefRow
        property string label
        property string info: ""
        default property alias control: slot.data
        Layout.fillWidth: true
        Layout.minimumHeight: Theme.pad(44)
        spacing: 10
        Text {
            Layout.fillWidth: true
            text: prefRow.label
            color: Theme.text
            font.pixelSize: 14
            elide: Text.ElideRight
            TitleTip { tip: prefRow.info }
        }
        RowLayout { id: slot; spacing: 6 }
    }
    component Rule: Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.rule }
    component Keycap: Rectangle {
        property alias text: capText.text
        implicitWidth: capText.implicitWidth + 14
        implicitHeight: 24
        radius: Theme.r(6)
        color: Qt.alpha(Theme.bg, 0.7)
        border.width: 1
        border.color: Theme.rule
        Text {
            id: capText
            anchors.centerIn: parent
            color: Theme.text
            font.pixelSize: 12
            font.family: "monospace"
        }
    }

    ColumnLayout {
        id: col
        width: page.width
        spacing: 10

        GridLayout {
            Layout.fillWidth: true
            columns: page.app && page.app.wide ? 2 : 1
            columnSpacing: 10
            rowSpacing: 10

            Card {
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                title: "Appearance"
                info: "Saved in ~/.config/omni-server/appearance.json. Omni Settings keeps its own."
                AppearancePrefs {}
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 10

                Card {
                    title: "Console"
                    spacing: 0
                    Row_ {
                        label: "Text size"
                        info: "The console's text, in pixels. The Dashboard's console is a size smaller."
                        Segmented {
                            options: [10, 11, 12, 13, 14, 16].map(n => ({ value: n, label: String(n) }))
                            current: Prefs.consoleSize
                            onPicked: value => Prefs.consoleSize = value
                        }
                    }
                    Rule {}
                    Row_ {
                        label: "Wrap long lines"
                        info: "Off cuts a long line at the edge instead; Copy still copies all of it."
                        Toggle { checked: Prefs.consoleWrap; onToggled: on => Prefs.consoleWrap = on }
                    }
                    Rule {}
                    Row_ {
                        label: "Timestamps"
                        info: "The time the server logged each line, in front of it."
                        Toggle { checked: Prefs.timestamps; onToggled: on => Prefs.timestamps = on }
                    }
                }

                Card {
                    title: "Tabs"
                    spacing: 0
                    Row_ {
                        label: "Tab names"
                        info: "Every tab's name while the window is wide enough, or only the open tab's."
                        Segmented {
                            options: [{ value: "always", label: "All tabs" }, { value: "selected", label: "Open tab" }]
                            current: Prefs.tabLabels
                            onPicked: value => Prefs.tabLabels = value
                        }
                    }
                }

                Card {
                    title: "Keyboard shortcuts"
                    spacing: 0
                    Repeater {
                        model: [
                            { keys: ["Ctrl", "1–9"], what: "Go to a tab" },
                            { keys: ["Ctrl", "F"], what: "Find in the console" },
                            { keys: ["Ctrl", "K"], what: "Type a command" },
                            { keys: ["Ctrl", ","], what: "Preferences" },
                            { keys: ["↑", "↓"], what: "Command history, or the next match while finding" },
                            { keys: ["Esc"], what: "Close a dialog, sheet or search" }
                        ]
                        RowLayout {
                            id: shortcut
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.minimumHeight: Theme.pad(36)
                            spacing: 4
                            Repeater {
                                model: shortcut.modelData.keys
                                Keycap { required property string modelData; text: modelData }
                            }
                            Text {
                                Layout.fillWidth: true
                                Layout.leftMargin: 8
                                text: shortcut.modelData.what
                                color: Theme.dim
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
