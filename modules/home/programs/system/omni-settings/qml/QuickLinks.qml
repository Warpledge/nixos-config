// Tiles opening DankMaterialShell's settings on one tab, in `order` (api.py's QUICK)
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: quick
    required property var links
    required property var order
    readonly property var shown: order.map(t => links.find(l => l.tab === t)).filter(l => l)
    visible: shown.length > 0
    spacing: 6

    Section { text: "Shell Settings" }
    Text {
        text: "Open DankMaterialShell's settings on one page."
        color: Theme.dim
        font.pixelSize: 13
        Layout.leftMargin: 6
    }
    GridLayout {
        Layout.fillWidth: true
        columns: 3
        columnSpacing: 6
        rowSpacing: 6
        Repeater {
            model: quick.shown
            Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 78
                radius: 14
                color: tileHover.hovered ? Theme.cardHover : Theme.card
                Behavior on color { ColorAnimation { duration: 120 } }
                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width - 12
                    spacing: 6
                    Icon {
                        Layout.alignment: Qt.AlignHCenter
                        icon: Theme.glyph(modelData.icon, "open_in_new")
                        color: Theme.primary
                    }
                    Text {
                        text: modelData.title
                        color: Theme.text
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
                HoverHandler { id: tileHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    onTapped: Quickshell.execDetached(["dms", "ipc", "call", "settings", "openWith", modelData.tab])
                }
            }
        }
    }
}
