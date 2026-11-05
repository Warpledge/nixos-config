// `omni-server`: the window
import QtQuick
import Quickshell

ShellRoot {
    FloatingWindow {
        title: "Omni Server"
        implicitWidth: 1100
        implicitHeight: 780
        color: Theme.bg
        onClosed: Qt.quit()

        ServerView {
            anchors.fill: parent
            focus: true
        }
    }
}
