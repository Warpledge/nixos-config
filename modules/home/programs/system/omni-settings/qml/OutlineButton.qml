// A small button: outlined, or filled in primary for a card's main action
import QtQuick

Rectangle {
    id: btn
    property string text
    property color tint: Theme.text
    property bool filled: false
    property string tip: ""
    signal clicked()
    implicitWidth: label.implicitWidth + 26
    implicitHeight: 32
    radius: 9
    color: filled ? (hover.hovered ? Qt.lighter(Theme.primary, 1.1) : Theme.primary)
        : hover.hovered ? Qt.alpha(tint, 0.1) : "transparent"
    border.width: filled ? 0 : 1
    border.color: tint === Theme.text ? Qt.alpha(Theme.dim, 0.5) : tint
    opacity: enabled ? 1 : 0.5
    Behavior on color { ColorAnimation { duration: 120 } }
    Text {
        id: label
        anchors.centerIn: parent
        text: btn.text
        color: btn.filled ? Theme.inkPrimary : btn.tint
        font.pixelSize: 13
        font.weight: btn.filled ? Font.Bold : Font.DemiBold
    }
    readonly property point cursor: hover.point.scenePosition
    onCursorChanged: Tip.move(btn, cursor)
    HoverHandler {
        id: hover
        cursorShape: btn.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onHoveredChanged: hovered && btn.tip ? Tip.request(btn, btn.tip, point.scenePosition) : Tip.cancel(btn)
    }
    TapHandler {
        enabled: btn.enabled
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: btn.clicked()
    }
}
