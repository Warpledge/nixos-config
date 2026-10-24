// The round icon at the start of a row: an app's own icon when `app` names one
import QtQuick
import Quickshell.Widgets

Rectangle {
    id: badge
    property string icon: "settings"
    property var app: []
    property string tone: ""
    readonly property string appPath: Theme.appIcon(app)
    implicitWidth: 38
    implicitHeight: 38
    radius: 19
    color: appPath ? "transparent" : tone ? Theme.toneColor(tone) : Theme.primary
    Icon {
        id: glyph
        visible: !badge.appPath
        anchors.centerIn: parent
        icon: badge.icon
        size: Math.round(badge.width * 0.53)
        color: badge.tone ? Theme.bg : Theme.inkPrimary
        RotationAnimation on rotation {
            running: badge.icon === "progress_activity"
            from: 0; to: 360; duration: 1200; loops: Animation.Infinite
            onStopped: glyph.rotation = 0
        }
    }
    IconImage {
        visible: !!badge.appPath
        anchors.fill: parent
        source: badge.appPath
    }
}
