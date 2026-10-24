// DMS plugin: Omni Settings as a slideout on the right edge, `dms ipc call omniSettings toggle`
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets
import "file:@qml@"

Item {
    id: root

    // What PluginService hands a daemon
    property string pluginId
    property var pluginService

    function show(screen) {
        // One slideout, moved to the focused screen, so pending changes aren't split
        if (!slideout.isVisible)
            slideout.modelData = screen ?? CompositorService.getFocusedScreen() ?? Quickshell.screens[0] ?? null
        slideout.show()
    }

    //--- Hot corner: the top-right pixel of each screen, over the bar
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors.top: true
            anchors.right: true
            implicitWidth: 1
            implicitHeight: 1
            color: "transparent"
            WlrLayershell.namespace: "dms:omni-settings-corner"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            HoverHandler {
                onHoveredChanged: if (hovered) root.show(modelData)
            }
        }
    }

    DSlideout {
        id: slideout
        layerNamespace: "dms:omni-settings"
        slideEdge: "right"

        //--- Between the bars on the top and bottom edges, auto-hiding ones included
        readonly property real topInset: ShellLayout.edge(modelData, "top")?.occupancy ?? 0
        readonly property real bottomInset: ShellLayout.edge(modelData, "bottom")?.occupancy ?? 0
        WlrLayershell.exclusiveZone: -1
        margins.top: topInset
        margins.bottom: bottomInset
        implicitHeight: (modelData ? modelData.height : 800) - topInset - bottomInset

        //--- Closes once the cursor has been off it a moment (not while typing, or with a
        // sheet or question open), or when another window takes focus
        readonly property bool keepOpen: {
            const view = slideout.loadedItem
            const f = slideout.contentItem.Window.activeFocusItem
            return !!view && (view.sheet !== null || view.dialog.visible || (!!f && "cursorPosition" in f))
        }
        readonly property bool focused: slideout.contentItem.Window.active
        onFocusedChanged: if (!focused && isVisible) hide()
        onKeepOpenChanged: leave.restart()
        onIsVisibleChanged: leave.stop()
        HoverHandler {
            id: hover
            parent: slideout.contentItem
            onHoveredChanged: leave.restart()
        }
        Timer {
            id: leave
            interval: 600
            onTriggered: if (slideout.isVisible && !hover.hovered && !slideout.keepOpen) slideout.hide()
        }
        content: Component {
            OmniView {
                focus: true
                onCloseRequested: slideout.hide()
            }
        }
    }

    IpcHandler {
        target: "omniSettings"

        function toggle(): string {
            if (slideout.isVisible) {
                slideout.hide()
                return "CLOSED"
            }
            root.show()
            return "OPENED"
        }

        function show(): string {
            root.show()
            return "OPENED"
        }

        function hide(): string {
            slideout.hide()
            return "CLOSED"
        }
    }
}
