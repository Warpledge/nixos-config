// `omni-settings`: Omni Settings in its own window
import QtQuick
import Quickshell

ShellRoot {
    FloatingWindow {
        id: win
        title: "Omni Settings"
        implicitWidth: 560
        implicitHeight: 880
        color: Theme.bg
        onClosed: Qt.quit()

        OmniView {
            anchors.fill: parent
            focus: true
            onCloseRequested: Qt.quit()
        }
    }
}
