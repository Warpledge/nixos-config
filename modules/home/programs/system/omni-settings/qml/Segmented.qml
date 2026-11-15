// A row of options with one picked: `options` [{value, label}], `current` the picked value
import QtQuick

Rectangle {
    id: seg
    property var options: []
    property var current
    signal picked(var value)
    implicitWidth: segRow.implicitWidth + 6
    implicitHeight: 32
    radius: Theme.r(10)
    color: Qt.alpha(Theme.bg, 0.7)
    opacity: enabled ? 1 : 0.6

    //--- The picked option's fill, which slides to the next one picked
    readonly property int picked_: {
        const key = JSON.stringify(current)
        return options.findIndex(o => JSON.stringify(o.value) === key)
    }
    readonly property Item pickedItem: optRepeater.count > 0 && picked_ >= 0 ? optRepeater.itemAt(picked_) : null
    Rectangle {
        visible: !!seg.pickedItem
        x: segRow.x + (seg.pickedItem ? seg.pickedItem.x : 0)
        y: segRow.y
        width: seg.pickedItem ? seg.pickedItem.width : 0
        height: 26
        radius: Theme.r(8)
        color: Qt.alpha(Theme.primary, 0.3)
        // Only after the first layout, or it slides in from the left on load
        Behavior on x { enabled: seg.armed; NumberAnimation { duration: Theme.ms(240); easing.type: Easing.OutCubic } }
        Behavior on width { enabled: seg.armed; NumberAnimation { duration: Theme.ms(240); easing.type: Easing.OutCubic } }
    }
    property bool armed: false  // set by the first tap

    Row {
        id: segRow
        anchors.centerIn: parent
        spacing: 2
        Repeater {
            id: optRepeater
            model: seg.options
            Rectangle {
                id: opt
                required property var modelData
                readonly property bool chosen: JSON.stringify(modelData.value) === JSON.stringify(seg.current)
                implicitWidth: optText.implicitWidth + 20
                implicitHeight: 26
                radius: Theme.r(8)
                color: !chosen && optHover.hovered && seg.enabled ? Theme.hover : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.ms(120) } }
                Text {
                    id: optText
                    anchors.centerIn: parent
                    text: opt.modelData.label
                    color: opt.chosen ? Theme.primary : Theme.dim
                    font.pixelSize: 13
                    font.weight: opt.chosen ? Font.Bold : Font.Medium
                    Behavior on color { ColorAnimation { duration: Theme.ms(200) } }
                }
                HoverHandler { id: optHover; enabled: seg.enabled; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    enabled: seg.enabled && !opt.chosen
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    onTapped: {
                        seg.armed = true
                        seg.picked(opt.modelData.value)
                    }
                }
            }
        }
    }
}
