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
    radius: Theme.r(9)
    color: filled ? (hover.hovered ? Qt.lighter(Theme.primary, 1.1) : Theme.primary)
        : hover.hovered ? Qt.alpha(tint, 0.1) : "transparent"
    border.width: filled ? 0 : 1
    border.color: tint === Theme.text ? Qt.alpha(Theme.dim, hover.hovered ? 0.8 : 0.5) : tint
    opacity: enabled ? 1 : 0.5
    scale: tap.pressed ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: Theme.ms(120); easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: Theme.ms(140) } }
    Behavior on border.color { ColorAnimation { duration: Theme.ms(140) } }
    Behavior on opacity { NumberAnimation { duration: Theme.ms(160) } }
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
        id: tap
        enabled: btn.enabled
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: btn.clicked()
    }
}
