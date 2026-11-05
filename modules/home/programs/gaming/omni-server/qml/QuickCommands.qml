// The quick command buttons; `pinnedOnly` is the Dashboard's short row
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    property var app
    property bool pinnedOnly: false
    spacing: 8

    readonly property var items: !app ? [] : app.quick
        .map((q, i) => Object.assign({ index: i }, q))
        .filter(q => !pinnedOnly || q.pinned)
    readonly property var runs: app && app.stats ? app.stats.runs : []

    Repeater {
        model: root.runs
        Banner {
            required property var modelData
            icon: "schedule"
            tone: "info"
            text: `${modelData.name}: ${modelData.steps} step${modelData.steps > 1 ? "s" : ""} left, next in ${modelData.next} s`
            action: "Cancel"
            onActed: root.app.call("quick_cancel", { run: modelData.id })
        }
    }

    Flow {
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            model: root.items
            Rectangle {
                id: quickItem
                required property var modelData
                width: quickRow.implicitWidth + 24
                height: 36
                radius: 10
                opacity: root.app && root.app.running ? 1 : 0.5
                color: quickHover.hovered ? Theme.hover : Qt.alpha(Theme.bg, 0.55)
                border.width: 1
                border.color: Theme.rule
                Row {
                    id: quickRow
                    anchors.centerIn: parent
                    spacing: 6
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: quickItem.modelData.icon
                        size: 18
                        color: Theme.primary
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: quickItem.modelData.name
                        textFormat: Text.PlainText
                        color: Theme.text
                        font.pixelSize: 13
                    }
                }
                HoverHandler {
                    id: quickHover
                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: hovered
                        ? Tip.request(quickItem, quickItem.modelData.steps.map(s => s.command).join(", "), point.scenePosition)
                        : Tip.cancel(quickItem)
                }
                TapHandler {
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    onTapped: {
                        Tip.cancel(quickItem)
                        if (root.app.running)
                            root.app.runQuick(quickItem.modelData)
                        else
                            root.app.showError("Start the server first")
                    }
                }
                TapHandler {
                    enabled: !root.pinnedOnly
                    acceptedButtons: Qt.RightButton
                    onTapped: root.edit(quickItem.modelData.index)
                }
            }
        }
        OutlineButton {
            height: 36
            text: root.pinnedOnly ? "More" : "New"
            tip: root.pinnedOnly ? "Every quick command, on the Console tab" : "Make a quick command"
            onClicked: root.pinnedOnly ? root.app.tab = "console" : root.edit(-1)
        }
        OutlineButton {
            visible: !root.pinnedOnly && root.items.length > 0
            height: 36
            text: "Edit"
            tip: "Change or delete a quick command. Right-click one to jump straight to it."
            onClicked: root.edit(0)
        }
    }

    function edit(index) {
        app.openSheet("QuickEditor.qml", sheet => {
            sheet.app = app
            sheet.begin(index)
        })
    }
}
