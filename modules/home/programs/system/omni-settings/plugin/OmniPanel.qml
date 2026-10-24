// DMS plugin: Omni Settings as a slideout on the right edge, `dms ipc call omniSettings toggle`
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Modules.Plugins
import qs.Services
import qs.Widgets
import "file:@qml@"

PluginComponent {
    id: root

    function show() {
        // One slideout, moved to the focused screen, so pending changes aren't split
        if (!slideout.isVisible)
            slideout.modelData = CompositorService.getFocusedScreen() ?? Quickshell.screens[0] ?? null
        slideout.show()
    }

    DSlideout {
        id: slideout
        layerNamespace: "dms:omni-settings"
        slideEdge: "right"
        hoverDismissEnabled: true
        // Typing, a sheet or a question keeps it open when the cursor leaves
        hoverDismissSuspended: {
            const view = slideout.loadedItem
            const f = slideout.contentItem.Window.activeFocusItem
            return !!view && (view.sheet !== null || view.dialog.visible || (!!f && "cursorPosition" in f))
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
