// A round icon-only button; `tip` shows at the cursor on hover
import QtQuick

Rectangle {
    id: btn
    property string icon
    property bool filled: false
    property string tip: ""
    property color tint: Theme.dim
    readonly property color accent: Theme.accentOf(btn)
    signal clicked
    implicitWidth: 32
    implicitHeight: 32
    radius: 16
    color: hover.hovered ? Qt.alpha(accent, 0.2) : filled ? Qt.alpha(accent, 0.1) : "transparent"
    Behavior on color { ColorAnimation { duration: 120 } }
    Icon {
        anchors.centerIn: parent
        icon: btn.icon
        size: 18
        color: hover.hovered ? btn.accent : btn.tint
        Behavior on color { ColorAnimation { duration: 120 } }
    }
    readonly property point cursor: hover.point.scenePosition
    onCursorChanged: Tip.move(btn, cursor)
    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: hovered ? Tip.request(btn, btn.tip, point.scenePosition) : Tip.cancel(btn)
    }
    TapHandler {
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: {
            Tip.cancel(btn)
            btn.clicked()
        }
    }
}
