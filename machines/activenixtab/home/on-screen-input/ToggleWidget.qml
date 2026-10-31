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

    // Empty for a button that's always shown
    visibilityCommand: "@visibility@"
    visibilityInterval: 2

    horizontalBarPill: Component {
        DIcon {
            name: "@icon@"
            size: root.iconSize
            color: Theme.surfaceText
        }
    }

    verticalBarPill: Component {
        DIcon {
            name: "@icon@"
            size: root.iconSize
            color: Theme.surfaceText
        }
    }
}
