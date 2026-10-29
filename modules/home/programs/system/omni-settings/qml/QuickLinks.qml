// Tiles opening DankMaterialShell's settings on one tab, in `order` (api.py's QUICK),
// or all of `links` without one
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: quick
    required property var links
    property var order: null
    property string title: "Shell Settings"
    property string description: "Open DankMaterialShell's settings on one page."
    readonly property var shown: order ? order.map(t => links.find(l => l.tab === t)).filter(l => l) : links
    visible: shown.length > 0
    spacing: 6

    Section { text: quick.title; info: quick.description }
    GridLayout {
        Layout.fillWidth: true
        columns: 3
        columnSpacing: 6
        rowSpacing: 6
        Repeater {
            // Blank tiles fill the last row, so a short row's tiles keep their size
            model: quick.shown.concat(Array((3 - quick.shown.length % 3) % 3).fill(null))
            Rectangle {
                id: tile
                required property var modelData
                Layout.fillWidth: true
                opacity: modelData ? 1 : 0
                enabled: !!modelData
                implicitHeight: 78
                radius: 14
                color: tileHover.hovered ? Theme.hover : Theme.card
                Behavior on color { ColorAnimation { duration: 120 } }
                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width - 12
                    spacing: 6
                    Icon {
                        Layout.alignment: Qt.AlignHCenter
                        icon: tile.modelData ? Theme.glyph(tile.modelData.icon, "open_in_new") : ""
                        color: Theme.primary
                    }
                    Text {
                        text: tile.modelData ? tile.modelData.title : ""
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
                    onTapped: Quickshell.execDetached(["dms", "ipc", "call", "settings", "openWith", tile.modelData.tab])
                }
            }
        }
    }
}
