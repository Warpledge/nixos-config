// A switch as a chip: filled in primary while on, a dashed outline while off
import QtQuick
import QtQuick.Shapes

Item {
    id: chip
    property string text
    property string tip: ""  // shown on hovering
    property bool checked: false
    signal toggled()
    implicitWidth: label.implicitWidth + 26
    implicitHeight: 30
    opacity: enabled ? 1 : 0.6

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: chip.checked ? Qt.alpha(Theme.primary, hover.hovered ? 0.38 : 0.28)
            : hover.hovered ? Theme.hover : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
    }
    Shape {
        anchors.fill: parent
        visible: !chip.checked
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: Qt.alpha(Theme.dim, 0.6)
            strokeWidth: 1
            strokeStyle: ShapePath.DashLine
            dashPattern: [3, 3]
            fillColor: "transparent"
            PathRectangle {
                x: 0.5
                y: 0.5
                width: chip.width - 1
                height: chip.height - 1
                radius: (chip.height - 1) / 2
            }
        }
    }
    Text {
        id: label
        anchors.centerIn: parent
        text: chip.text
        color: chip.checked ? Theme.primary : Theme.dim
        font.pixelSize: 13
        font.weight: chip.checked ? Font.DemiBold : Font.Medium
    }

    readonly property point cursor: hover.point.scenePosition
    onCursorChanged: Tip.move(chip, cursor)
    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: hovered && chip.tip ? Tip.request(chip, chip.tip, point.scenePosition) : Tip.cancel(chip)
    }
    TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: chip.toggled() }
}
