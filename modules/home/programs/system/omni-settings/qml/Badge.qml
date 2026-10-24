// The round icon at the start of a row: an app's own icon when `app` names one
import QtQuick
import Quickshell.Widgets

Rectangle {
    id: badge
    property string icon: "settings"
    property var app: []
    property bool strong: false
    readonly property string appPath: Theme.appIcon(app)
    implicitWidth: 38
    implicitHeight: 38
    radius: 19
    color: appPath ? "transparent" : strong ? Theme.primary : Theme.primaryContainer
    Icon {
        visible: !badge.appPath
        anchors.centerIn: parent
        icon: badge.icon
        size: 20
        color: badge.strong ? Theme.onPrimary : Theme.onPrimaryContainer
    }
    IconImage {
        visible: !!badge.appPath
        anchors.fill: parent
        source: badge.appPath
    }
}
