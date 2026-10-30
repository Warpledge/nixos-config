// A group heading inside a page, as the group cards title theirs (SettingGroup.qml)
import QtQuick
import QtQuick.Layouts

Text {
    id: heading
    property string info: ""  // what the group is, shown on hovering the heading
    color: Theme.dim
    font.pixelSize: 12
    font.weight: Font.Bold
    font.capitalization: Font.AllUppercase
    font.letterSpacing: 0.6
    // Without fillWidth a layout won't shrink below the unwrapped text
    wrapMode: Text.Wrap
    Layout.fillWidth: true
    Layout.topMargin: 10
    Layout.leftMargin: 6
    Layout.rightMargin: 6
    TitleTip { tip: heading.info }
}
