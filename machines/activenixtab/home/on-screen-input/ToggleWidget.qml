import QtQuick
import Quickshell
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins

// A bar button that runs @command@ (substituted by on-screen-input/default.nix)
PluginComponent {
    id: root

    readonly property int iconSize: Theme.barIconSize(barThickness, -4, root.barConfig?.maximizeWidgetIcons, root.barConfig?.iconScale)

    pillClickAction: () => Quickshell.execDetached(["@command@"])

    horizontalBarPill: Component {
        DankIcon {
            name: "@icon@"
            size: root.iconSize
            color: Theme.surfaceText
        }
    }

    verticalBarPill: Component {
        DankIcon {
            name: "@icon@"
            size: root.iconSize
            color: Theme.surfaceText
        }
    }
}
