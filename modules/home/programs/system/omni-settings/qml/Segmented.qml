// A row of options with one picked: `options` [{value, label}], `current` the picked value
import QtQuick

Rectangle {
    id: seg
    property var options: []
    property var current
    signal picked(var value)
    implicitWidth: segRow.implicitWidth + 6
    implicitHeight: 32
    radius: 10
    color: Qt.alpha(Theme.bg, 0.7)
    opacity: enabled ? 1 : 0.6

    Row {
        id: segRow
        anchors.centerIn: parent
        spacing: 2
        Repeater {
            model: seg.options
            Rectangle {
                id: opt
                required property var modelData
                readonly property bool chosen: JSON.stringify(modelData.value) === JSON.stringify(seg.current)
                implicitWidth: optText.implicitWidth + 20
                implicitHeight: 26
                radius: 8
                color: chosen ? Qt.alpha(Theme.primary, 0.3) : optHover.hovered && seg.enabled ? Theme.hover : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
                Text {
                    id: optText
                    anchors.centerIn: parent
                    text: opt.modelData.label
                    color: opt.chosen ? Theme.primary : Theme.dim
                    font.pixelSize: 13
                    font.weight: opt.chosen ? Font.Bold : Font.Medium
                }
                HoverHandler { id: optHover; enabled: seg.enabled; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    enabled: seg.enabled && !opt.chosen
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    onTapped: seg.picked(opt.modelData.value)
                }
            }
        }
    }
}
