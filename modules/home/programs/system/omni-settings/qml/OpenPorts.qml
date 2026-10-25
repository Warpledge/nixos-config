// Open Right Now, under Open Ports: what the running firewall accepts (api.py's `ports`)
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: ports
    property var open: null
    property string error: ""
    spacing: 6

    Component.onCompleted: Backend.call("ports", {}, reply => {
        if (!ports)
            return  // the tab was left before the reply came
        if (reply.ok)
            open = reply.data
        else
            error = reply.error
    })

    Section { text: "Open Right Now" }
    Text {
        text: "What the running system accepts from other devices. Changes above show up here after Apply."
        color: Theme.dim
        font.pixelSize: 13
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        Layout.leftMargin: 6
    }
    ListRow {
        visible: ports.error !== "" || (!!ports.open && !ports.open.length)
        icon: "lan"
        title: ports.error !== "" ? "Couldn't read the firewall" : "No ports are open"
        subtitle: ports.error || "Other devices can't start connections to this computer."
    }
    Rectangle {
        visible: !!ports.open && ports.open.length > 0
        Layout.fillWidth: true
        implicitHeight: portList.implicitHeight + 8
        radius: 14
        color: Theme.card
        ColumnLayout {
            id: portList
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 4
            spacing: 0
            Repeater {
                model: ports.open || []
                ListRow {
                    required property var modelData
                    compact: true
                    icon: "lan"
                    title: `${modelData.proto.toUpperCase()} ${modelData.port}`
                    subtitle: modelData.who
                }
            }
        }
    }
}
