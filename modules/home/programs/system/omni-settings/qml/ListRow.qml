// One DMS-style row: its own rounded block, icon badge, title and subtitle
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: row
    property string icon: "settings"
    property var app: []
    property string title
    property string subtitle  // data that tells list items apart; a description goes in `info`
    property string info: ""  // what it is, shown on hovering the title (TitleTip)
    property string caution: ""  // behind a yellow triangle beside the title
    property string alert: ""  // something to act on, in yellow under the title
    property string value: ""  // a status value, large on the right
    property string tag: ""
    property bool tagSuccess: false
    property string tone: ""  // tints the row and its badge: Theme.toneColor
    property string button: ""
    property string trailing: ""
    property bool chevron: false
    property bool expandable: false  // a dropdown: a turning Chevron, open while `expanded`
    property bool expanded: false
    property bool selected: false
    property bool compact: false
    property int titleLines: 1
    property real bar: -1  // a usage bar under the text, 0 to 1
    signal clicked
    Layout.fillWidth: true
    implicitHeight: rowCol.implicitHeight + (compact ? 14 : 22)
    readonly property color accent: Theme.accentOf(row)
    readonly property bool plainCard: !selected && !tone && !compact
    radius: compact ? 14 : 16
    opacity: enabled ? 1 : 0.5
    color: selected ? Theme.selected
         : tone ? Theme.toneFill(tone, hover.hovered ? Theme.hover : Theme.card)
         : compact ? (hover.hovered ? Theme.hover : "transparent")
         : hover.hovered && !expanded ? Theme.hover : Qt.alpha(Theme.bg, 0.55)
    border.width: plainCard ? 1 : 0
    border.color: expanded ? Qt.alpha(accent, 0.35) : Theme.rule
    Behavior on color { ColorAnimation { duration: 120 } }

    ColumnLayout {
        id: rowCol
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Badge { icon: row.icon; app: row.app; tone: row.tone; implicitWidth: 32; implicitHeight: 32 }
            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true
                RowLayout {
                    spacing: 6
                    Layout.fillWidth: true
                    Text {
                        id: titleText
                        text: row.title
                        color: Theme.text
                        font.pixelSize: row.compact ? 14 : 15
                        font.weight: Font.Medium
                        wrapMode: Text.Wrap
                        maximumLineCount: row.titleLines
                        elide: Text.ElideRight
                        // Its full width, so the indicators sit right after the name; a
                        // value beside it shrinks before the name is cut
                        Layout.maximumWidth: Math.ceil(titleWidth.advanceWidth) + 1
                        Layout.minimumWidth: row.value !== ""
                            ? Math.min(Layout.maximumWidth, row.width * 0.6) : 0
                        Layout.fillWidth: true
                        TextMetrics { id: titleWidth; font: titleText.font; text: titleText.text }
                        TitleTip { tip: row.info }
                    }
                    Hint { tip: row.caution }
                    Item { Layout.fillWidth: true }
                }
                Elided {
                    visible: text !== ""
                    text: row.subtitle
                    color: Theme.dim
                    font.pixelSize: 12
                    Layout.fillWidth: true
                }
                Text {
                    visible: text !== ""
                    text: row.alert
                    color: Theme.caution
                    font.pixelSize: 14
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
            //--- Shrinks to fit rather than cutting the value short
            Text {
                visible: row.value !== ""
                text: row.value
                color: row.tone ? Theme.toneColor(row.tone) : row.accent
                font.pixelSize: 18
                font.weight: Font.Bold
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 12
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.minimumWidth: 40
                Layout.preferredWidth: implicitWidth
                Layout.maximumWidth: implicitWidth
            }
            Chip { tappable: false; visible: row.tag !== ""; text: row.tag; accent: !row.tagSuccess; success: row.tagSuccess }
            Pill { visible: row.button !== ""; text: row.button; onClicked: row.clicked() }
            Icon { visible: row.chevron; icon: "chevron_right" }
            Chevron { visible: row.expandable; open: row.expanded; lit: hover.hovered }
            Icon { visible: row.trailing !== ""; icon: row.trailing; size: 18 }
        }

        Rectangle {
            visible: row.bar >= 0
            Layout.fillWidth: true
            Layout.leftMargin: 50
            implicitHeight: 6
            radius: 3
            color: Theme.cardHover
            Rectangle {
                height: parent.height
                radius: 3
                width: parent.width * Math.max(0, Math.min(1, row.bar))
                color: Theme.primary
            }
        }
    }

    HoverHandler { id: hover; cursorShape: row.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
    TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: row.clicked() }
}
