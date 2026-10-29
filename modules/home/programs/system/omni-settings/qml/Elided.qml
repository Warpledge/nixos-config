// One line of text cut with …; hovering a cut one shows all of it
import QtQuick

Text {
    id: line
    property string full: text  // the tooltip, when `text` is marked up
    elide: Text.ElideRight
    readonly property point cursor: hover.point.scenePosition
    onCursorChanged: Tip.move(line, cursor)
    HoverHandler {
        id: hover
        onHoveredChanged: hovered && line.truncated ? Tip.request(line, line.full, point.scenePosition)
                                                    : Tip.cancel(line)
    }
}
