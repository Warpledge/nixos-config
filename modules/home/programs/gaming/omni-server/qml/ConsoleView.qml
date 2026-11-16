// The live console: follows the end unless scrolled up. Filters: all, warnings, chat.
// `query` highlights matches (case-insensitive); find() steps through them.
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property var app
    property string filter: "all"
    property int fontSize: Prefs.consoleSize
    property string query: ""
    property int current: -1  // the match find() last moved to
    property int matches: 0
    Layout.fillWidth: true
    Layout.fillHeight: true
    radius: Theme.r(10)
    color: Qt.darker(Theme.bg, 1.25)
    clip: true

    function lineText(time, body) { return Prefs.timestamps && time ? `[${time}] ${body}` : body }
    function hit(time, body) {
        return query !== "" && lineText(time, body).toLowerCase().includes(query.toLowerCase())
    }
    //--- A matching line as rich text with each match marked; players write these
    //--- lines, so everything else is escaped
    function marked(text) {
        const esc = s => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
        const lower = text.toLowerCase(), q = query.toLowerCase()
        let out = "", at = 0, i
        while ((i = lower.indexOf(q, at)) >= 0) {
            out += esc(text.slice(at, i))
                + `<span style="background-color:${Theme.caution}; color:${Theme.bg}">`
                + esc(text.slice(i, i + q.length)) + "</span>"
            at = i + q.length
        }
        return (out + esc(text.slice(at))).replace(/ {2}/g, " &nbsp;")
    }
    function recount() {
        let n = 0
        const m = app ? app.consoleModel : null
        if (m && query)
            for (let i = 0; i < m.count; i++) {
                const e = m.get(i)
                if (passes(e.level, e.kind) && hit(e.time, e.body))
                    n++
            }
        matches = n
    }
    //--- Moves to the next match after `current` (dir 1) or before it (-1), wrapping
    function find(dir) {
        const m = app ? app.consoleModel : null
        if (!m || !query || !m.count)
            return
        const start = current >= 0 ? current : dir > 0 ? -1 : m.count
        for (let step = 1; step <= m.count; step++) {
            const i = ((start + dir * step) % m.count + m.count) % m.count
            const e = m.get(i)
            if (passes(e.level, e.kind) && hit(e.time, e.body)) {
                current = i
                list.follow = false
                list.positionViewAtIndex(i, ListView.Center)
                return
            }
        }
    }
    onQueryChanged: {
        current = -1
        recount()
        if (query)
            find(-1)  // the latest match first
    }
    onFilterChanged: recount()
    Timer { id: recountSoon; interval: 300; onTriggered: root.recount() }
    Connections {
        target: root.app
        function onConsoleLine() { if (root.query) recountSoon.restart() }
    }

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
                out.push(lineText(e.time, e.body))
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
        delegate: Item {
            id: line
            required property int index
            required property string time
            required property string level
            required property string body
            required property string kind
            readonly property bool shown: root.passes(level, kind)
            readonly property bool hit: root.hit(time, body)
            width: list.width - 6
            visible: shown
            height: shown ? lineLabel.implicitHeight : 0
            //--- The match find() moved to
            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: -4
                anchors.rightMargin: -2
                visible: line.hit && line.index === root.current
                radius: 4
                color: Qt.alpha(Theme.caution, 0.16)
                border.width: 1
                border.color: Qt.alpha(Theme.caution, 0.5)
            }
            Text {
                id: lineLabel
                width: parent.width
                readonly property string plain: root.lineText(line.time, line.body)
                // Rich text only for a line that matches; every other line stays plain
                text: line.hit ? root.marked(plain) : plain
                textFormat: line.hit ? Text.RichText : Text.PlainText
                wrapMode: Prefs.consoleWrap ? Text.WrapAnywhere : Text.NoWrap
                elide: Prefs.consoleWrap ? Text.ElideNone : Text.ElideRight
                font.family: "monospace"
                font.pixelSize: root.fontSize
                lineHeight: 1.1
                color: line.level === "ERROR" || line.level === "FATAL" ? Theme.error
                    : line.level === "WARN" || line.kind === "lag" ? Theme.caution
                    : line.kind === "chat" ? Theme.primary
                    : line.kind === "join" || line.kind === "leave" || line.kind === "done" ? Theme.success
                    : Theme.text
            }
        }
        Rectangle {
            visible: list.contentHeight > list.height
            anchors.right: parent.right
            width: barHover.hovered || list.moving ? 6 : 3
            radius: width / 2
            color: barHover.hovered || list.moving ? Qt.alpha(Theme.primary, 0.6) : Theme.rule
            y: list.visibleArea.yPosition * list.height
            height: Math.max(20, list.visibleArea.heightRatio * list.height)
            Behavior on width { NumberAnimation { duration: Theme.ms(140) } }
            Behavior on color { ColorAnimation { duration: Theme.ms(200) } }
            HoverHandler { id: barHover }
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
