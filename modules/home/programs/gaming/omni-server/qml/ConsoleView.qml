// The live console: follows the end unless scrolled up. Filters: all, warnings, chat
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property var app
    property string filter: "all"
    property int fontSize: 12
    Layout.fillWidth: true
    Layout.fillHeight: true
    radius: 10
    color: Qt.darker(Theme.bg, 1.25)
    clip: true

    function passes(level, kind) {
        return filter === "all"
            || (filter === "warn" && (level === "WARN" || level === "ERROR" || level === "FATAL" || kind === "lag"))
            || (filter === "chat" && (kind === "chat" || kind === "join" || kind === "leave"))
    }
    function copyAll() {
        const m = app.consoleModel
        const out = []
        for (let i = 0; i < m.count; i++) {
            const e = m.get(i)
            if (passes(e.level, e.kind))
                out.push(e.time ? `[${e.time}] ${e.body}` : e.body)
        }
        return out.join("\n")
    }

    ListView {
        id: list
        anchors.fill: parent
        anchors.margins: 8
        model: root.app ? root.app.consoleModel : null
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: 2000
        property bool follow: true
        onMovementEnded: follow = atYEnd
        onCountChanged: if (follow) Qt.callLater(positionViewAtEnd)
        Component.onCompleted: positionViewAtEnd()
        delegate: Text {
            id: line
            required property string time
            required property string level
            required property string body
            required property string kind
            readonly property bool shown: root.passes(level, kind)
            width: list.width - 6
            visible: shown
            height: shown ? implicitHeight : 0
            text: time ? `[${time}] ${body}` : body
            textFormat: Text.PlainText
            wrapMode: Text.WrapAnywhere
            font.family: "monospace"
            font.pixelSize: root.fontSize
            lineHeight: 1.1
            color: level === "ERROR" || level === "FATAL" ? Theme.error
                : level === "WARN" || kind === "lag" ? Theme.caution
                : kind === "chat" ? Theme.primary
                : kind === "join" || kind === "leave" || kind === "done" ? Theme.success
                : Theme.text
        }
        Rectangle {
            visible: list.contentHeight > list.height
            anchors.right: parent.right
            width: 3
            radius: 2
            color: Theme.rule
            y: list.visibleArea.yPosition * list.height
            height: Math.max(20, list.visibleArea.heightRatio * list.height)
        }
    }
    OutlineButton {
        visible: !list.follow
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 10
        filled: true
        text: "Follow"
        onClicked: {
            list.follow = true
            list.positionViewAtEnd()
        }
    }
    Text {
        visible: !root.app || root.app.consoleModel.count === 0
        anchors.centerIn: parent
        text: "Nothing yet. The console fills once the server starts."
        color: Theme.dim
        font.pixelSize: 13
    }
}
