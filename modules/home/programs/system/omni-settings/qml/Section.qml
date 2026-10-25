// A group heading, in the primary colour
import QtQuick
import QtQuick.Layouts

Text {
    color: Theme.primary
    font.pixelSize: 15
    font.weight: Font.DemiBold
    // Without fillWidth a layout won't shrink below the unwrapped text
    wrapMode: Text.Wrap
    Layout.fillWidth: true
    Layout.topMargin: 10
    Layout.leftMargin: 6
    Layout.rightMargin: 6
}
