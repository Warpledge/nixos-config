// A group heading, in its page's colour
import QtQuick
import QtQuick.Layouts

Text {
    id: heading
    property string info: ""  // what the group is, shown on hovering the heading
    color: Theme.accentOf(heading)
    font.pixelSize: 17
    font.weight: Font.DemiBold
    // Without fillWidth a layout won't shrink below the unwrapped text
    wrapMode: Text.Wrap
    Layout.fillWidth: true
    Layout.topMargin: 10
    Layout.leftMargin: 6
    Layout.rightMargin: 6
    TitleTip { tip: heading.info }
}
