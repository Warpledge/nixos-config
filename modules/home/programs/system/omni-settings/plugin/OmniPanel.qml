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

    function toggle(screen) {
        if (slideout.isVisible)
            slideout.hide()
        else
            show(screen)
    }

    function show(screen) {
        // One slideout, moved to the focused screen, so pending changes aren't split
        if (!slideout.isVisible)
            slideout.modelData = screen ?? CompositorService.getFocusedScreen() ?? Quickshell.screens[0] ?? null
        slideout.show()
    }

    DSlideout {
        id: slideout
        layerNamespace: "dms:omni-settings"
        slideEdge: "right"
        // DSlideout's 480, plus the page rail and its gap, less the margins dropped below
        slideoutWidth: 490
        // Drops DSlideout's own content margin; OmniView's edge is the only gap
        Component.onCompleted: {
            container.anchors.topMargin = 0
            container.anchors.bottomMargin = 0
            container.anchors.leftMargin = 0
            container.anchors.rightMargin = 0
        }

        //--- Between the bars on the top and bottom edges, auto-hiding ones included
        readonly property real topInset: ShellLayout.edge(modelData, "top")?.occupancy ?? 0
        readonly property real bottomInset: ShellLayout.edge(modelData, "bottom")?.occupancy ?? 0
        WlrLayershell.exclusiveZone: -1
        margins.top: topInset
        margins.bottom: bottomInset
        implicitHeight: (modelData ? modelData.height : 800) - topInset - bottomInset

        content: Component {
            OmniView {
                edge: 6
                focus: true
                onCloseRequested: slideout.hide()
            }
        }
    }

    IpcHandler {
        target: "omniSettings"

        function toggle(): string {
            root.toggle()
            return slideout.isVisible ? "OPENED" : "CLOSED"
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
