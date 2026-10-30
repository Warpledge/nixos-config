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

    //--- The width dragged to, kept in DMS's plugin state across restarts
    readonly property real defaultWidth: 618
    function loadWidth() {
        if (pluginService)
            slideout.slideoutWidth = pluginService.loadPluginState(pluginId, "width", defaultWidth)
    }
    onPluginServiceChanged: loadWidth()
    Component.onCompleted: loadWidth()

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
        // The window's default width (shell.qml), until a drag changes it (loadWidth)
        slideoutWidth: root.defaultWidth
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

        //--- Dragging the left edge resizes the panel; the window grows leftward, so
        //--- each move adds how far the cursor got from where it was pressed
        MouseArea {
            z: 10
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 6
            cursorShape: Qt.SizeHorCursor
            property real pressX: 0
            onPressed: mouse => pressX = mouse.x
            onPositionChanged: mouse => {
                const most = (slideout.modelData ? slideout.modelData.width : 1920) * 0.8
                slideout.slideoutWidth = Math.round(Math.max(480, Math.min(most,
                    slideout.slideoutWidth - (mouse.x - pressX))))
            }
            onReleased: save()
            onDoubleClicked: {
                slideout.slideoutWidth = root.defaultWidth
                save()
            }
            function save() {
                if (root.pluginService)
                    root.pluginService.savePluginState(root.pluginId, "width", slideout.slideoutWidth)
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
