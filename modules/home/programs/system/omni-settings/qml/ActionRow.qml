// A row that does one thing: its name, a line on what it does, and an outlined button
// (red when it deletes something)
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: row
    property string title
    property string note: ""
    property string action
    property bool destructive: false
    signal clicked()
    Layout.fillWidth: true
    implicitHeight: rowLayout.implicitHeight + 22
    radius: 14
    color: Qt.alpha(Theme.bg, 0.55)
    border.width: 1
    border.color: Theme.rule
    opacity: enabled ? 1 : 0.6

    RowLayout {
        id: rowLayout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 14
        anchors.rightMargin: 12
        spacing: 10
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                Layout.fillWidth: true
                text: row.title
                color: Theme.text
                font.pixelSize: 15
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
            Text {
                visible: row.note !== ""
                Layout.fillWidth: true
                text: row.note
                color: Theme.dim
                font.pixelSize: 12
                wrapMode: Text.Wrap
            }
        }
        OutlineButton {
            text: row.action
            tint: row.destructive ? Theme.error : Theme.text
            onClicked: row.clicked()
        }
    }
}
