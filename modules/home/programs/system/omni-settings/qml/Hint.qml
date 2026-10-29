// A small indicator beside a name; its text shows at the cursor on hover. A caution
// is a bare yellow triangle with a yellow tip; descriptions.json's ** and !! marks
// are kept. What a name is shows on hovering the name itself (TitleTip.qml)
import QtQuick

Rectangle {
    id: hint
    property string icon: "warning"
    property string tip: ""
    property string tone: "caution"  // Theme.toneColor, or "" for the page's accent
    readonly property color tint: tone ? Theme.toneColor(tone) : Theme.accentOf(hint)
    readonly property bool bare: icon === "warning"
    readonly property string shown: tone === "caution"
        ? `<font color="${Theme.caution}">${Theme.rich(tip)}</font>` : Theme.rich(tip)
    visible: tip !== ""
    implicitWidth: 22
    implicitHeight: 22
    radius: 11
    color: bare ? "transparent" : Qt.alpha(tint, hover.hovered ? 0.34 : 0.18)
    border.width: bare ? 0 : 1
    border.color: Qt.alpha(tint, 0.45)
    Behavior on color { ColorAnimation { duration: 120 } }
    Icon {
        anchors.centerIn: parent
        icon: hint.icon
        size: hint.bare ? 20 : 15
        fill: true
        color: hint.tint
        opacity: hint.bare && !hover.hovered ? 0.85 : 1
    }
    readonly property point cursor: hover.point.scenePosition
    onCursorChanged: Tip.move(hint, cursor)
    HoverHandler {
        id: hover
        onHoveredChanged: hovered ? Tip.request(hint, hint.shown, point.scenePosition, true)
                                  : Tip.cancel(hint)
    }
}
