// The tooltip at the cursor: a control asks with request(), OmniView.qml draws it
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: tip
    property string text: ""
    property point at: Qt.point(0, 0)  // the cursor, in scene coordinates
    property var owner: null
    property bool rich: false  // `text` is StyledText markup (Hint.qml)
    property bool shown: false

    function request(item, text, scenePos, rich) {
        if (!text)
            return
        owner = item
        tip.text = text
        tip.rich = !!rich
        at = scenePos
        shown = false
        delay.restart()
    }
    //--- Follows the cursor until the tip shows, then stays put
    function move(item, scenePos) {
        if (owner === item && !shown)
            at = scenePos
    }
    function cancel(item) {
        if (owner !== item)
            return
        delay.stop()
        shown = false
        owner = null
    }

    Timer { id: delay; interval: 450; onTriggered: tip.shown = true }
}
