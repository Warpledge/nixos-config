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
        // The page's blurb sits in its header (PageSection in OmniView.qml)
        text: Theme.rich(page.model.intro)
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
    RowLayout {
        visible: page.model.changeFor
        Layout.fillWidth: true
        Layout.bottomMargin: 4
        spacing: 10
        Text {
            text: "Change for"
            color: Theme.dim
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }
        Segmented {
            options: page.view.scopes.map(s => ({ value: s.id, label: s.id === "" ? "All" : s.id }))
            current: page.view.scope
            onPicked: v => page.view.setScope(v)
        }
        Item { Layout.fillWidth: true }
    }

    Repeater {
        model: page.model.groups
        ColumnLayout {
            id: group
            required property var modelData
            // Open cards are kept across launches (OmniView's openCards)
            readonly property string cardKey: modelData.card || `${page.model.id}|${modelData.title}`
            readonly property bool open: !!page.view.openCards[cardKey]
            readonly property bool collapsed: modelData.collapsed
            readonly property var bools: modelData.settings.filter(s => s.kind === "bool")
            Layout.fillWidth: true
            spacing: 6
            SettingGroup {
                visible: !group.collapsed && group.modelData.settings.length > 0
                view: page.view
                settings: group.collapsed ? [] : group.modelData.settings
                title: group.modelData.title
                info: group.modelData.description
                locked: group.modelData.locked
                pageGlyph: page.glyph
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
                                // A Material name from COLLAPSED, or an app category's icon names
                                icon: typeof group.modelData.icon === "string"
                                    ? group.modelData.icon || page.glyph
                                    : Theme.glyph(group.modelData.icon, page.glyph)
                                size: 20
                                color: Theme.inkPrimary
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Layout.fillWidth: true
                            RowLayout {
                                spacing: 6
                                Layout.fillWidth: true
                                Text {
                                    id: cardTitle
                                    text: group.modelData.title
                                    color: Theme.text
                                    font.pixelSize: 18
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: Math.ceil(cardTitleWidth.advanceWidth) + 1
                                    Layout.fillWidth: true
                                    TextMetrics { id: cardTitleWidth; font: cardTitle.font; text: cardTitle.text }
                                    TitleTip { tip: group.modelData.description }
                                }
                                Hint {
                                    visible: group.modelData.locked
                                    icon: "lock"
                                    tip: "Only an admin can change these"
                                }
                                Item { Layout.fillWidth: true }
                            }
                        }
                        Rectangle {
                            implicitWidth: countText.implicitWidth + 24
                            implicitHeight: 32
                            radius: 16
                            color: Qt.alpha(card.accent, 0.18)
                            Text {
                                id: countText
                                anchors.centerIn: parent
                                text: group.bools.length === group.modelData.settings.length
                                    ? `${group.bools.filter(s => page.view.valueOf(s)).length} of ${group.bools.length} on`
                                    : `${group.modelData.settings.length}`
                                color: card.accent
                                font.pixelSize: 16
                                font.weight: Font.Bold
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
                            onTapped: page.view.setCardOpen(group.cardKey, !group.open)
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
                        //--- schema.py's CHIPS groups: each switch a chip, filled while on
                        Flow {
                            visible: !!group.modelData.chips
                            Layout.fillWidth: true
                            Layout.margins: 6
                            spacing: 6
                            Repeater {
                                model: group.collapsed && group.modelData.chips ? group.modelData.settings : []
                                ToggleChip {
                                    required property var modelData
                                    text: modelData.title
                                    tip: modelData.description || modelData.subtitle
                                    checked: !!page.view.valueOf(modelData)
                                    enabled: !group.modelData.locked
                                    onToggled: page.view.change(modelData, !checked)
                                }
                            }
                        }
                        //--- An app category's template groups head their rows (api.py's app_card)
                        Rectangle {
                            visible: !group.modelData.chips
                            Layout.fillWidth: true
                            implicitHeight: cardRows.implicitHeight
                            radius: 14
                            color: Qt.alpha(Theme.bg, 0.55)
                            border.width: 1
                            border.color: Theme.rule
                            ColumnLayout {
                                id: cardRows
                                anchors.left: parent.left
                                anchors.right: parent.right
                                spacing: 0
                                Repeater {
                                    model: group.collapsed && !group.modelData.chips ? group.modelData.settings : []
                                    ColumnLayout {
                                        id: cardItem
                                        required property var modelData
                                        required property int index
                                        readonly property string sub: modelData.sub || ""
                                        readonly property bool heads: sub !== "" && (index === 0
                                            || group.modelData.settings[index - 1].sub !== sub)
                                        Layout.fillWidth: true
                                        spacing: 0
                                        Rectangle {
                                            visible: cardItem.index > 0
                                            Layout.fillWidth: true
                                            implicitHeight: 1
                                            color: Theme.rule
                                        }
                                        Text {
                                            visible: cardItem.heads
                                            text: cardItem.sub
                                            color: card.accent
                                            font.pixelSize: 13
                                            font.weight: Font.Bold
                                            Layout.leftMargin: 14
                                            Layout.topMargin: 10
                                        }
                                        SettingRow {
                                            setting: cardItem.modelData
                                            view: page.view
                                            locked: group.modelData.locked
                                            pageGlyph: page.glyph
                                        }
                                    }
                                }
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
                    info: modelData.subtitle
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
            Loader {
                active: group.modelData.title === "Ad & Tracker Blocking"
                visible: active
                Layout.fillWidth: true
                Layout.preferredHeight: item ? item.implicitHeight : 0
                sourceComponent: BlockLookup {}
            }
            Loader {
                active: group.modelData.title === "Mullvad"
                visible: active && !!item && item.visible
                Layout.fillWidth: true
                Layout.preferredHeight: item && item.visible ? item.implicitHeight : 0
                sourceComponent: MullvadStatus {}
            }
            Loader {
                active: page.model.title === "SSH" && group.modelData.title === "Authorized Keys"
                visible: active
                Layout.fillWidth: true
                Layout.preferredHeight: item ? item.implicitHeight : 0
                sourceComponent: SshKeys { view: page.view }
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
