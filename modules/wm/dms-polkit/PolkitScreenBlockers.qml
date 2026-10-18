import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets

// Added to DMS by modules/wm/dms-polkit. While the polkit prompt is open, every
// other monitor gets a dimmed layer that swallows clicks and, under niri, holds
// the keyboard: niri honours the prompt's own keyboard grab only on the active
// monitor, and a click on another monitor makes that one active.
Variants {
    id: root

    property var prompt: null

    model: Quickshell.screens

    delegate: PanelWindow {
        required property var modelData

        screen: modelData
        visible: (root.prompt?.shouldBeVisible ?? false) && root.prompt?.effectiveScreen !== modelData
        color: "transparent"

        WlrLayershell.namespace: "dms:polkit-auth-blocker"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.keyboardFocus: CompositorService.isNiri ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        // The same dimming DMS draws behind its own modals
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.5
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onWheel: wheel => wheel.accepted = true
        }

        StyledText {
            anchors.centerIn: parent
            text: "Enter your password on the other screen"
            font.pixelSize: Theme.fontSizeXLarge
        }
    }
}
