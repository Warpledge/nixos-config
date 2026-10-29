// Content that slides open and fades in; what it holds stacks in a column
import QtQuick
import QtQuick.Layouts

Item {
    id: reveal
    property bool open: false
    property real gap: 0  // the parent layout's spacing, taken in so opening doesn't jump by it
    property alias spacing: column.spacing
    default property alias content: column.data
    // Open or still closing: Loaders and Repeaters inside stay until it's shut
    readonly property bool shown: open || height > 0
    // Content that's open on load, or still loading, appears without sliding
    property bool armed: false
    onOpenChanged: armed = true

    Layout.fillWidth: true
    Layout.topMargin: -gap
    Layout.preferredHeight: open ? column.implicitHeight + gap : 0
    implicitHeight: Layout.preferredHeight
    visible: shown
    clip: true
    opacity: open ? 1 : 0
    Behavior on Layout.preferredHeight {
        enabled: reveal.armed
        NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
    }
    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }

    ColumnLayout {
        id: column
        y: reveal.gap
        width: reveal.width
        spacing: 6
    }
}
