// Chat, joins and leaves, with a box to say something to everyone
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    property var app
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 6

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 2
        model: root.app ? root.app.chatModel : null
        boundsBehavior: Flickable.StopAtBounds
        onCountChanged: Qt.callLater(positionViewAtEnd)
        Component.onCompleted: positionViewAtEnd()
        delegate: Row {
            id: chatRow
            required property string time
            required property string kind
            required property string name
            required property string message
            width: list.width
            spacing: 6
            Text {
                visible: chatRow.kind === "chat"
                text: chatRow.name
                textFormat: Text.PlainText
                color: Theme.primary
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
            Text {
                width: parent.width - (chatRow.kind === "chat" ? x : 0)
                text: chatRow.kind === "chat" ? chatRow.message
                    : `${chatRow.name} ${chatRow.kind === "join" ? "joined" : "left"}`
                textFormat: Text.PlainText
                color: chatRow.kind === "chat" ? Theme.text : Theme.dim
                font.pixelSize: 13
                wrapMode: Text.Wrap
            }
        }
        Text {
            visible: list.count === 0
            anchors.centerIn: parent
            text: "No chat yet"
            color: Theme.dim
            font.pixelSize: 13
        }
    }
    Field {
        id: box
        placeholder: "Message everyone"
        onAccepted: {
            const text = input.text.trim()
            if (text)
                root.app.send(`say ${text}`)
            input.text = ""
        }
    }
}
