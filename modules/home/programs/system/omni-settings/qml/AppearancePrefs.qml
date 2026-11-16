// The look preferences both apps share (Prefs.qml), as rows with a live preview at
// the top; each app puts it in its own card
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: list
    Layout.fillWidth: true
    spacing: 0

    component PrefRow: RowLayout {
        id: prefRow
        property string label
        property string info: ""
        default property alias control: slot.data
        Layout.fillWidth: true
        Layout.minimumHeight: Theme.pad(44)
        spacing: 10
        Text {
            Layout.fillWidth: true
            text: prefRow.label
            color: Theme.text
            font.pixelSize: 14
            elide: Text.ElideRight
            TitleTip { tip: prefRow.info }
        }
        RowLayout { id: slot; spacing: 6 }
    }
    component Rule: Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.rule }

    //--- A small card drawn with the current choices
    Rectangle {
        Layout.fillWidth: true
        Layout.bottomMargin: 8
        implicitHeight: previewRow.implicitHeight + Theme.pad(24)
        radius: Theme.r(14)
        // A shade lighter than the card it sits on, so it shows on either app's page
        color: Theme.cardFill(Theme.cardHover)
        border.width: Theme.cardEdged ? 1 : 0
        border.color: Theme.cardEdge()
        Behavior on color { ColorAnimation { duration: Theme.ms(200) } }
        Behavior on radius { NumberAnimation { duration: Theme.ms(200) } }
        RowLayout {
            id: previewRow
            anchors.fill: parent
            anchors.margins: Theme.pad(12)
            spacing: 10
            ColumnLayout {
                spacing: 6
                Text {
                    text: "Preview"
                    color: Theme.text
                    font.pixelSize: 14
                    font.weight: Font.Bold
                }
                Row {
                    spacing: 6
                    Chip { tappable: false; accent: true; text: "Chip" }
                    OutlineButton { filled: true; text: "Button" }
                    Toggle { anchors.verticalCenter: parent.verticalCenter; checked: true }
                }
            }
            // In an Item: a RowLayout would size the graph by its own path, which loops
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                LineGraph {
                    anchors.fill: parent
                    values: [0.3, 0.42, 0.38, 0.55, 0.5, 0.68, 0.6, 0.74, 0.7, 0.86]
                    count: 10
                }
            }
        }
    }

    PrefRow {
        label: "Motion"
        info: "How long animations take. Off switches them off; spinners for running work stay."
        Segmented {
            options: [{ value: "full", label: "Full" }, { value: "reduced", label: "Reduced" },
                      { value: "off", label: "Off" }]
            current: Prefs.motion
            onPicked: value => Prefs.motion = value
        }
    }
    Rule {}
    PrefRow {
        label: "Accent"
        info: "Which of the theme's colours highlights choices, buttons and graphs. All three come from DMS's matugen theme."
        Repeater {
            model: [{ role: "primary", label: "Primary" }, { role: "secondary", label: "Secondary" },
                    { role: "tertiary", label: "Tertiary" }]
            Rectangle {
                id: swatch
                required property var modelData
                readonly property bool chosen: Theme.role === modelData.role
                implicitWidth: 28
                implicitHeight: 28
                radius: 14
                color: Theme.col(modelData.role)
                border.width: chosen ? 3 : 1
                border.color: chosen ? Theme.text : Theme.rule
                scale: swatchHover.hovered ? 1.12 : 1
                Behavior on scale { NumberAnimation { duration: Theme.ms(140); easing.type: Easing.OutBack } }
                Behavior on border.width { NumberAnimation { duration: Theme.ms(140) } }
                Icon {
                    anchors.centerIn: parent
                    visible: swatch.chosen
                    icon: "check"
                    size: 14
                    color: Theme.col("on_" + swatch.modelData.role)
                }
                readonly property point cursor: swatchHover.point.scenePosition
                onCursorChanged: Tip.move(swatch, cursor)
                HoverHandler {
                    id: swatchHover
                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: hovered ? Tip.request(swatch, swatch.modelData.label, point.scenePosition)
                                              : Tip.cancel(swatch)
                }
                TapHandler {
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    onTapped: Prefs.accent = swatch.modelData.role
                }
            }
        }
    }
    Rule {}
    PrefRow {
        label: "Cards"
        info: "Solid cards, see-through ones, or just an outline."
        Segmented {
            options: [{ value: "solid", label: "Solid" }, { value: "translucent", label: "Translucent" },
                      { value: "outlined", label: "Outlined" }]
            current: Prefs.cards
            onPicked: value => Prefs.cards = value
        }
    }
    Rule {}
    PrefRow {
        label: "Graphs"
        info: "A bare line, or the line with a shade under it."
        Segmented {
            options: [{ value: "line", label: "Line" }, { value: "filled", label: "Filled" }]
            current: Prefs.graphs
            onPicked: value => Prefs.graphs = value
        }
    }
    Rule {}
    PrefRow {
        label: "Corners"
        info: "How round cards, buttons and fields are."
        Segmented {
            options: [{ value: "sharp", label: "Sharp" }, { value: "default", label: "Default" },
                      { value: "round", label: "Round" }]
            current: Prefs.corners
            onPicked: value => Prefs.corners = value
        }
    }
    Rule {}
    PrefRow {
        label: "Density"
        info: "Compact trims the padding inside cards and rows."
        Segmented {
            options: [{ value: "compact", label: "Compact" }, { value: "comfortable", label: "Comfortable" }]
            current: Prefs.density
            onPicked: value => Prefs.density = value
        }
    }
    Rule {}
    PrefRow {
        label: "Reset"
        info: "Puts every preference here back to its default."
        OutlineButton { text: "Reset all"; onClicked: Prefs.reset() }
    }
}
