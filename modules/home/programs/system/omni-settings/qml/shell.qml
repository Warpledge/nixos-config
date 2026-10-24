// `omni-settings`: Omni Settings in its own window
import QtQuick
import Quickshell

ShellRoot {
    FloatingWindow {
        id: win
        title: "Omni Settings"
        implicitWidth: 618  // 560 for the page, plus the page rail and its gap
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
