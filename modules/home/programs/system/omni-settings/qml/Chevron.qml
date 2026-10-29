// The round dropdown button at the end of a row, turning as it opens
import QtQuick

Rectangle {
    id: chev
    property bool open: false
    property bool lit: false  // the row under the cursor
    property int size: 28
    readonly property color accent: Theme.accentOf(chev)
    implicitWidth: size
    implicitHeight: size
    radius: size / 2
    color: Qt.alpha(accent, open ? 0.25 : lit ? 0.18 : 0.1)
    Behavior on color { ColorAnimation { duration: 150 } }
    Icon {
        anchors.centerIn: parent
        icon: "expand_more"
        size: Math.round(chev.size * 0.64)
        color: chev.accent
        rotation: chev.open ? 180 : 0
        Behavior on rotation { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    }
}
