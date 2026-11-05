// A slider in whole gigabytes; `picked` on release, in megabytes
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    property int value: 4096
    property int maximum: 16384
    property int dragging: -1
    readonly property int minimumGb: 1
    readonly property int maximumGb: Math.max(minimumGb + 1, Math.floor(maximum / 1024))
    readonly property int shownGb: dragging >= 0 ? dragging : Math.round(value / 1024)
    signal picked(int value)
    spacing: 10

    Item {
        id: track
        Layout.fillWidth: true
        implicitHeight: 24
        readonly property real fraction: (root.shownGb - root.minimumGb) / (root.maximumGb - root.minimumGb)
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 5
            radius: 3
            color: Qt.alpha(Theme.bg, 0.55)
            Rectangle {
                width: parent.width * track.fraction
                height: parent.height
                radius: 3
                color: Theme.primary
            }
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: (parent.width - width) * track.fraction
            width: 16
            height: 16
            radius: 8
            color: Theme.primary
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            function at(x) {
                const fraction = Math.max(0, Math.min(1, x / width))
                return Math.round(root.minimumGb + fraction * (root.maximumGb - root.minimumGb))
            }
            onPressed: mouse => root.dragging = at(mouse.x)
            onPositionChanged: mouse => root.dragging = at(mouse.x)
            onReleased: {
                const gb = root.dragging
                root.dragging = -1
                root.picked(gb * 1024)
            }
        }
    }
    Text {
        Layout.preferredWidth: 44
        horizontalAlignment: Text.AlignRight
        text: `${root.shownGb} GB`
        color: Theme.text
        font.pixelSize: 13
    }
}
