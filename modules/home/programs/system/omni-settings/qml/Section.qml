// A group heading, in its page's colour
import QtQuick
import QtQuick.Layouts

Text {
    id: heading
    color: Theme.accentOf(heading)
    font.pixelSize: 15
    font.weight: Font.DemiBold
    // Without fillWidth a layout won't shrink below the unwrapped text
    wrapMode: Text.Wrap
    Layout.fillWidth: true
    Layout.topMargin: 10
    Layout.leftMargin: 6
    Layout.rightMargin: 6
}
