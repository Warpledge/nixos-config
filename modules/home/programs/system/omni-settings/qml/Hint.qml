// A small indicator beside a name; its text shows at the cursor on hover
import QtQuick

Rectangle {
    id: hint
    property string icon: "priority_high"
    property string tip: ""
    property string tone: "caution"  // Theme.toneColor, or "" for the page's accent
    readonly property color tint: tone ? Theme.toneColor(tone) : Theme.accentOf(hint)
    implicitWidth: 20
    implicitHeight: 20
    radius: 10
    color: Qt.alpha(tint, hover.hovered ? 0.34 : 0.18)
    border.width: 1
    border.color: Qt.alpha(tint, 0.45)
    Behavior on color { ColorAnimation { duration: 120 } }
    Icon { anchors.centerIn: parent; icon: hint.icon; size: 14; fill: true; color: hint.tint }
    readonly property point cursor: hover.point.scenePosition
    onCursorChanged: Tip.move(hint, cursor)
    HoverHandler {
        id: hover
        onHoveredChanged: hovered ? Tip.request(hint, hint.tip, point.scenePosition) : Tip.cancel(hint)
    }
}
