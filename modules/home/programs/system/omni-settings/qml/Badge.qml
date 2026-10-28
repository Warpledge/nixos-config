// The round icon at the start of a row: an app's own icon when `app` names one
import QtQuick
import Quickshell.Widgets

Rectangle {
    id: badge
    property string icon: "settings"
    property var app: []
    property string tone: ""
    readonly property var appPath: Theme.appIcon(app)
    readonly property bool looking: appPath === undefined  // left blank until known
    implicitWidth: 38
    implicitHeight: 38
    radius: 19
    color: appPath || looking ? "transparent" : tone ? Theme.toneColor(tone) : Theme.accentOf(badge)
    Icon {
        id: glyph
        visible: !badge.appPath && !badge.looking
        anchors.centerIn: parent
        icon: badge.icon
        size: Math.round(badge.width * 0.53)
        color: badge.tone ? Theme.bg : Theme.inkPrimary
        RotationAnimation on rotation {
            // A hidden spinner still redraws the window every frame
            running: badge.icon === "progress_activity" && glyph.visible
            from: 0; to: 360; duration: 1200; loops: Animation.Infinite
            onStopped: glyph.rotation = 0
        }
    }
    IconImage {
        visible: !!badge.appPath
        anchors.fill: parent
        asynchronous: true
        source: badge.appPath || ""
    }
}
