// A group of settings as one card: its name, then its rows with a rule between each
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: grp
    required property var view
    property var settings: []
    property string title: ""
    property string info: ""  // shown on hovering the title
    property bool locked: false
    property string pageGlyph: "settings"
    Layout.fillWidth: true
    implicitHeight: col.implicitHeight
    radius: 14
    color: Qt.alpha(Theme.bg, 0.55)
    border.width: 1
    border.color: Theme.rule

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        RowLayout {
            visible: grp.title !== ""
            Layout.fillWidth: true
            Layout.margins: 12
            Layout.bottomMargin: 8
            spacing: 6
            Text {
                text: grp.title
                color: Theme.text
                font.pixelSize: 13
                font.weight: Font.Bold
                TitleTip { tip: grp.info }
            }
            Item { Layout.fillWidth: true }
        }
        Repeater {
            model: grp.settings
            ColumnLayout {
                id: item
                required property var modelData
                required property int index
                Layout.fillWidth: true
                spacing: 0
                Rectangle {
                    visible: item.index > 0 || grp.title !== ""
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Theme.rule
                }
                SettingRow {
                    setting: item.modelData
                    view: grp.view
                    locked: grp.locked
                    pageGlyph: grp.pageGlyph
                }
            }
        }
    }
}
