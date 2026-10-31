// A title's description, read at the cursor: put inside a Text, it covers just the
// words, and hovering them underlines them with dots and shows `tip` (with
// descriptions.json's ** and !! marks)
import QtQuick

Item {
    id: tt
    property string tip: ""
    readonly property Text title: parent
    visible: tip !== ""
    width: Math.min(title.contentWidth, title.width)
    height: Math.min(title.contentHeight, title.height)
    x: title.horizontalAlignment === Text.AlignRight ? title.width - width : 0
    y: title.height > height && title.verticalAlignment === Text.AlignVCenter ? (title.height - height) / 2 : 0

    Row {
        y: tt.height - 1
        spacing: 2
        opacity: hover.hovered ? 0.7 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
        Repeater {
            model: Math.floor(tt.width / 4)
            Rectangle { width: 2; height: 2; radius: 1; color: tt.title.color }
        }
    }

    readonly property point cursor: hover.point.scenePosition
    onCursorChanged: Tip.move(tt, cursor)
    HoverHandler {
        id: hover
        cursorShape: Qt.WhatsThisCursor
        onHoveredChanged: hovered ? Tip.request(tt, Theme.rich(tt.tip), point.scenePosition, true)
                                  : Tip.cancel(tt)
    }
}
