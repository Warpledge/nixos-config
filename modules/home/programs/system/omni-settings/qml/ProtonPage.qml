// Launch Options: options to copy for Steam, Heroic and Lutris (api.py's launchOptions)
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: page
    required property var view
    property var lo: null
    property string error: ""
    spacing: 6

    Component.onCompleted: Backend.call("launchOptions", {}, reply => {
        if (reply.ok)
            lo = reply.data
        else
            error = reply.error
    })

    function copy(option) {
        Quickshell.clipboardText = option
        view.say(`Copied ${option}`)
    }

    //--- Hero
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: hero.implicitHeight + 28
        radius: 16
        color: Theme.card
        RowLayout {
            id: hero
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14
            Badge { implicitWidth: 56; implicitHeight: 56; radius: 28; icon: "sports_esports" }
            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                Text { text: "Launch Options"; color: Theme.text; font.pixelSize: 20; font.weight: Font.Bold }
                Text {
                    text: "Launch options for Steam, Heroic and Lutris. Click one to copy it."
                    color: Theme.dim
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
        }
    }

    Text {
        visible: page.error !== ""
        text: page.error
        color: Theme.error
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        Layout.margins: 6
    }

    //--- Where they go
    Group {
        title: "Where They Go"
        description: "In Steam, right-click a game, then Properties, then Launch Options. Variables go before "
                     + "%command% and game arguments after it. Heroic and Lutris take variables in their "
                     + "environment table and a wrapper in their wrapper field, both without %command%."
    }
    OptionRow {
        option: "PROTON_ENABLE_WAYLAND=0 nix-performance %command% -dx11"
        text: "An example with all three, to start from."
    }

    //--- Already set for every game
    Group {
        visible: !!page.lo && page.lo.session.length > 0
        title: "Set for Every Game"
        description: "Already in this session's environment; a value in a game's options overrides one."
    }
    Flow {
        visible: !!page.lo && page.lo.session.length > 0
        Layout.fillWidth: true
        Layout.leftMargin: 4
        spacing: 6
        Repeater {
            model: page.lo ? page.lo.session : []
            Chip { required property var modelData; text: modelData }
        }
    }

    Repeater {
        model: page.lo ? page.lo.groups : []
        ColumnLayout {
            id: group
            required property var modelData
            Layout.fillWidth: true
            spacing: 6
            Group { title: group.modelData.title; description: group.modelData.description }
            Repeater {
                model: group.modelData.options
                OptionRow { required property var modelData; option: modelData.option; text: modelData.text }
            }
        }
    }

    component Group: ColumnLayout {
        id: head
        property string title
        property string description
        Layout.fillWidth: true
        spacing: 2
        Section { text: head.title }
        Text {
            visible: text !== ""
            text: head.description
            color: Theme.dim
            font.pixelSize: 12
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.bottomMargin: 4
        }
    }

    //--- One option in monospace, its text under it; a click copies it
    component OptionRow: Rectangle {
        id: row
        property string option
        property string text
        Layout.fillWidth: true
        implicitHeight: optionCol.implicitHeight + 22
        radius: 14
        color: hover.hovered ? Theme.cardHover : Theme.card
        RowLayout {
            id: optionCol
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 14
            anchors.rightMargin: 12
            spacing: 10
            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                Text {
                    text: row.option
                    color: Theme.text
                    font.family: "monospace"
                    font.pixelSize: 13
                    wrapMode: Text.WrapAnywhere
                    Layout.fillWidth: true
                }
                Text {
                    text: row.text
                    color: Theme.dim
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
            Icon { icon: "content_copy"; size: 18 }
        }
        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: page.copy(row.option) }
    }
}
