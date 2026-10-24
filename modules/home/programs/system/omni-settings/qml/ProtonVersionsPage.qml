// Proton Versions: the Proton and Wine builds each launcher has (api.py's protonVersions)
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: page
    required property var view
    property var pv: null
    property string error: ""
    spacing: 6

    Component.onCompleted: Backend.call("protonVersions", {}, reply => {
        if (reply.ok)
            pv = reply.data
        else
            error = reply.error
    })

    function openProtonPlus() {
        const entry = DesktopEntries.byId("com.vysp3r.ProtonPlus")
        if (entry)
            entry.execute()
        else
            Quickshell.execDetached(["protonplus"])
    }

    //--- Hero
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: hero.implicitHeight + 28
        radius: 16
        color: Theme.card
        ColumnLayout {
            id: hero
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10
            RowLayout {
                spacing: 14
                Badge { implicitWidth: 56; implicitHeight: 56; radius: 28; icon: "deployed_code" }
                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    Text { text: "Proton Versions"; color: Theme.text; font.pixelSize: 20; font.weight: Font.Bold }
                    Text {
                        text: "The Proton and Wine builds each launcher can run games with. Pick one per game "
                              + "in the launcher, or Steam's default under Settings, Compatibility."
                        color: Theme.dim
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }
            Pill {
                visible: !!page.pv && page.pv.protonplus
                Layout.alignment: Qt.AlignHCenter
                text: "Open ProtonPlus"
                onClicked: page.openProtonPlus()
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
    Text {
        visible: !page.pv && !page.error
        text: "Loading…"
        color: Theme.dim
        Layout.margins: 6
    }

    Repeater {
        model: page.pv ? page.pv.groups : []
        ColumnLayout {
            id: group
            required property var modelData
            Layout.fillWidth: true
            spacing: 6
            Section { text: group.modelData.title }
            Text {
                visible: text !== ""
                text: group.modelData.description
                color: Theme.dim
                font.pixelSize: 12
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.bottomMargin: 4
            }
            ListRow {
                visible: !group.modelData.tools.length
                icon: "deployed_code"
                title: "No builds yet"
                subtitle: "Steam lists its own Proton once it has downloaded one."
            }
            Repeater {
                model: group.modelData.tools
                ToolRow { required property var modelData; tool: modelData }
            }
        }
    }

    component ToolRow: Rectangle {
        id: row
        property var tool
        Layout.fillWidth: true
        implicitHeight: toolLayout.implicitHeight + 22
        radius: 14
        color: Theme.card
        RowLayout {
            id: toolLayout
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 10
            anchors.rightMargin: 12
            spacing: 10
            Badge { icon: "deployed_code" }
            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true
                Text {
                    text: row.tool.name
                    color: Theme.text
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: row.tool.subtitle
                    color: Theme.dim
                    font.pixelSize: 12
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
            }
            Chip { visible: row.tool["default"]; text: "Steam default"; accent: true }
            IconButton {
                visible: !!row.tool.path
                icon: "folder_open"
                tip: "Open its folder"
                onClicked: Qt.openUrlExternally("file://" + row.tool.path)
            }
        }
    }
}
