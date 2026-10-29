// A page generated from the settings templates (api.py's `load`)
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: page
    required property var model
    required property var view
    readonly property string glyph: Theme.glyph(model.icon)
    spacing: 6

    Text {
        visible: text !== ""
        text: Theme.rich(page.model.intro || page.model.description)
        textFormat: Text.StyledText
        color: Theme.dim
        font.pixelSize: 15
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        Layout.leftMargin: 6
        Layout.rightMargin: 6
        Layout.bottomMargin: 4
    }

    //--- Change For: this computer, another listing the user, or all of them
    ColumnLayout {
        visible: page.model.changeFor
        Layout.fillWidth: true
        spacing: 4
        Section { text: "Change For" }
        Flow {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            spacing: 6
            Repeater {
                model: page.view.scopes
                Chip {
                    required property var modelData
                    text: modelData.title
                    accent: page.view.scope === modelData.id
                    opacity: page.view.pendingCount && !accent ? 0.5 : 1
                    onTapped: page.view.setScope(modelData.id)
                }
            }
        }
    }

    Repeater {
        model: page.model.groups
        ColumnLayout {
            id: group
            required property var modelData
            property bool open: false
            readonly property bool collapsed: modelData.collapsed
            readonly property var bools: modelData.settings.filter(s => s.kind === "bool")
            Layout.fillWidth: true
            spacing: 6
            Section { visible: !group.collapsed && group.modelData.title !== ""; text: group.modelData.title }
            Text {
                visible: !group.collapsed && text !== ""
                text: Theme.rich(group.modelData.description)
                textFormat: Text.StyledText
                color: Theme.dim
                font.pixelSize: 13
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.leftMargin: 6
            }
            Text {
                visible: !group.collapsed && group.modelData.locked
                text: "Only an admin can change these."
                color: Theme.caution
                font.pixelSize: 13
                Layout.leftMargin: 6
            }
            Repeater {
                model: group.collapsed ? [] : group.modelData.settings
                SettingRow {
                    required property var modelData
                    setting: modelData
                    view: page.view
                    locked: group.modelData.locked
                    pageGlyph: page.glyph
                }
            }

            //--- schema.py's COLLAPSED groups: a card that opens from its heading
            Rectangle {
                id: card
                visible: group.collapsed
                readonly property color accent: Theme.accentOf(card)
                Layout.fillWidth: true
                Layout.topMargin: 6
                implicitHeight: cardCol.implicitHeight + 12
                radius: 20
                color: Qt.alpha(accent, cardHover.hovered && !group.open ? 0.13 : 0.07)
                border.width: 1
                border.color: Qt.alpha(accent, group.open ? 0.35 : 0.2)
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                ColumnLayout {
                    id: cardCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 6
                    spacing: 6
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.margins: 6
                        spacing: 12
                        Rectangle {
                            implicitWidth: 36
                            implicitHeight: 36
                            radius: 18
                            color: card.accent
                            Icon {
                                anchors.centerIn: parent
                                icon: group.modelData.icon || page.glyph
                                size: 20
                                color: Theme.inkPrimary
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Layout.fillWidth: true
                            Text {
                                text: group.modelData.title
                                color: Theme.text
                                font.pixelSize: 16
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                visible: text !== ""
                                text: Theme.rich(group.modelData.description)
                                textFormat: Text.StyledText
                                color: Theme.dim
                                font.pixelSize: 13
                                wrapMode: Text.Wrap
                                Layout.fillWidth: true
                            }
                        }
                        Rectangle {
                            implicitWidth: countText.implicitWidth + 20
                            implicitHeight: 26
                            radius: 13
                            color: Qt.alpha(card.accent, 0.18)
                            Text {
                                id: countText
                                anchors.centerIn: parent
                                text: group.bools.length === group.modelData.settings.length
                                    ? `${group.bools.filter(s => page.view.valueOf(s)).length} of ${group.bools.length} on`
                                    : `${group.modelData.settings.length}`
                                color: card.accent
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                        }
                        Rectangle {
                            implicitWidth: 30
                            implicitHeight: 30
                            radius: 15
                            color: Qt.alpha(card.accent, group.open ? 0.25 : 0.12)
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Icon {
                                anchors.centerIn: parent
                                icon: "expand_more"
                                size: 20
                                color: card.accent
                                rotation: group.open ? 180 : 0
                                Behavior on rotation { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                            }
                        }
                        HoverHandler { id: cardHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            gesturePolicy: TapHandler.ReleaseWithinBounds
                            onTapped: group.open = !group.open
                        }
                    }
                    Reveal {
                        open: group.open
                        gap: cardCol.spacing
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 8
                            Layout.rightMargin: 8
                            Layout.bottomMargin: 2
                            implicitHeight: 1
                            color: Qt.alpha(card.accent, 0.25)
                        }
                        Text {
                            visible: group.modelData.locked
                            text: "Only an admin can change these."
                            color: Theme.caution
                            font.pixelSize: 13
                            Layout.leftMargin: 6
                        }
                        Repeater {
                            model: group.collapsed ? group.modelData.settings : []
                            SettingRow {
                                required property var modelData
                                setting: modelData
                                view: page.view
                                locked: group.modelData.locked
                                pageGlyph: page.glyph
                            }
                        }
                    }
                }
            }
            //--- DMS settings tabs this group links to
            Repeater {
                model: group.modelData.links
                ListRow {
                    required property var modelData
                    icon: Theme.glyph(modelData.icon, "open_in_new")
                    title: modelData.title
                    subtitle: modelData.subtitle
                    trailing: "open_in_new"
                    onClicked: Quickshell.execDetached(["dms", "ipc", "call", "settings", "openWith", modelData.tab])
                }
            }
            Loader {
                active: group.modelData.title === "Open Ports"
                visible: active
                Layout.fillWidth: true
                Layout.preferredHeight: item ? item.implicitHeight : 0
                sourceComponent: OpenPorts {}
            }
        }
    }

    Loader {
        active: page.model.title === "Services"
        visible: active
        Layout.fillWidth: true
        Layout.preferredHeight: item ? item.implicitHeight : 0
        sourceComponent: RunningNow { view: page.view }
    }
}
