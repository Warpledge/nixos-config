// A line that needs attention, with an optional button at its end
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: banner
    property string text
    property string icon: "info"
    property string tone: "caution"
    property string action: ""
    signal acted
    Layout.fillWidth: true
    implicitHeight: Math.max(row.implicitHeight + 16, 40)
    radius: 12
    color: Qt.alpha(Theme.toneColor(tone), 0.14)
    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 8
        spacing: 8
        Icon { icon: banner.icon; size: 18; color: Theme.toneColor(banner.tone) }
        Text {
            Layout.fillWidth: true
            text: banner.text
            textFormat: Text.PlainText
            color: Theme.toneColor(banner.tone)
            font.pixelSize: 13
            wrapMode: Text.Wrap
        }
        OutlineButton {
            visible: banner.action !== ""
            text: banner.action
            tint: Theme.toneColor(banner.tone)
            onClicked: banner.acted()
        }
    }
}
