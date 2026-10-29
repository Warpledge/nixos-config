// DMS plugin: the Mod+A side rail (apps.nix), `dms ipc call sideRail toggle|show <id>|hide`.
// Each app is a real niri window docked floating beside the rail; hidden ones wait on a
// stash workspace. Moves go over DMS's own niri socket, so nothing spawns per click.
// Apps start in their own app-dms-side-rail-* scope and unload after sitting hidden.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.Widgets
import qs.DCommon.Widgets

Item {
    id: root

    // What PluginService hands a daemon
    property string pluginId
    property var pluginService

    // {geometry, apps} from apps.nix, substituted at build time
    readonly property var config: @config@
    readonly property var geo: config.geometry

    property bool shown: false
    property string activeId: ""
    // An app launched but whose window hasn't opened yet
    property string pendingId: ""
    // Workspace hidden apps wait on, kept so stashing doesn't spread them out
    property int stashWs: -1
    // The monitor the rail was opened on; it moves only when a rail key is pressed on another
    property string railOutput: ""
    // When the rail last stashed each app, {id: ms}; only these auto-unload
    property var hiddenSince: ({})
    // Apps closed by unload(), {id: pid}, checked once for a process left in the tray
    property var closing: ({})

    function app(id) {
        return config.apps.find(a => a.id === id) ?? null;
    }

    function windowOf(a) {
        return a ? NiriService.windows.find(w => w.app_id === a.appId) ?? null : null;
    }

    function state(key, fallback) {
        return pluginService ? pluginService.loadPluginState(pluginId, key, fallback) : fallback;
    }

    function saveState(key, value) {
        if (pluginService)
            pluginService.savePluginState(pluginId, key, value);
    }

    function widthOf(a) {
        return state("widths", {})[a.id] ?? a.width;
    }

    function setWidth(a, px) {
        const widths = Object.assign({}, state("widths", {}));
        if (px === null)
            delete widths[a.id];
        else
            widths[a.id] = px;
        saveState("widths", widths);
        const w = windowOf(a);
        if (w)
            act({SetWindowWidth: {id: w.id, change: {SetFixed: widthOf(a)}}});
    }

    //--- Keep running and minutes to unload: the rail menu's choice, else apps.nix's
    function keepOf(a) {
        return state("unload", {})[a.id]?.keep ?? a.keepRunning;
    }

    function timeoutOf(a) {
        return state("unload", {})[a.id]?.minutes ?? a.unloadAfter;
    }

    function setUnload(a, change) {
        const all = Object.assign({}, state("unload", {}));
        if (change === null)
            delete all[a.id];
        else
            all[a.id] = Object.assign({}, all[a.id] ?? {}, change);
        saveState("unload", all);
        sweepTimer.update();
    }

    function markHidden(id, hidden) {
        const all = Object.assign({}, hiddenSince);
        if (hidden)
            all[id] = Date.now();
        else
            delete all[id];
        hiddenSince = all;
        sweepTimer.update();
    }

    //--- Closes an app's window as × would, so it saves as on any quit. A native app
    //--- still running after that (a tray icon) has its scope stopped; a web app's
    //--- pid is the shared Helium browser, so it only gets the close
    function unload(id) {
        const a = app(id);
        const w = windowOf(a);
        markHidden(id, false);
        if (!w)
            return;
        // The rail stays as it is with nothing docked; Mod+A won't restart this one
        if (id === activeId) {
            activeId = "";
            pendingId = "";
            saveState("lastId", "");
        }
        if (a.command[0] !== "helium") {
            const all = Object.assign({}, closing);
            all[id] = w.pid;
            closing = all;
            trayCheck.restart();
        }
        act({CloseWindow: {id: w.id}});
    }

    function act(action) {
        NiriService.send({Action: action});
    }

    function focusedWs() {
        return NiriService.workspaces[NiriService.focusedWorkspaceId] ?? null;
    }

    //--- The workspace showing on the rail's monitor
    function railWs() {
        return NiriService.allWorkspaces.find(ws => ws.output === railOutput && ws.is_active) ?? null;
    }

    //--- The last workspace of the rail's monitor, as nirius's scratchpad uses. Kept on the
    //--- same monitor, since niri moves the cursor when focus follows a window across
    function stashTarget() {
        const known = NiriService.workspaces[stashWs];
        if (known && !known.is_active && known.output === railOutput)
            return stashWs;
        const onOutput = NiriService.allWorkspaces.filter(ws => ws.output === railOutput && !ws.is_active);
        if (onOutput.length === 0)
            return -1;
        stashWs = onOutput.reduce((a, b) => (b.idx > a.idx ? b : a)).id;
        return stashWs;
    }

    function stash(id) {
        const w = windowOf(app(id));
        const target = stashTarget();
        if (!w || target < 0)
            return;
        rememberWidth(id, w);
        act({MoveWindowToWorkspace: {window_id: w.id, reference: {Id: target}, focus: false}});
        markHidden(id, true);
    }

    function rememberWidth(id, w) {
        const px = Math.round(w.layout?.window_size?.[0] ?? 0);
        const a = app(id);
        if (!a || px <= 0 || px === widthOf(a))
            return;
        const widths = Object.assign({}, state("widths", {}));
        widths[id] = px;
        saveState("widths", widths);
    }

    //--- Docks a window beside the rail on its monitor's workspace, at the app's width.
    //--- Moved without focus, then focused, so niri leaves the cursor where it is
    function place(a, w) {
        const ws = railWs();
        const screen = railScreen();
        if (ws && w.workspace_id !== ws.id)
            act({MoveWindowToWorkspace: {window_id: w.id, reference: {Id: ws.id}, focus: false}});
        if (!w.is_floating)
            act({MoveWindowToFloating: {id: w.id}});
        const width = widthOf(a);
        if (Math.round(w.layout?.window_size?.[0] ?? 0) !== width)
            act({SetWindowWidth: {id: w.id, change: {SetFixed: width}}});
        const top = inset(screen, "top");
        const height = Math.round((screen?.height ?? 0) - top - inset(screen, "bottom") - geo.gap * 2);
        if (screen && Math.round(w.layout?.window_size?.[1] ?? 0) !== height)
            act({SetWindowHeight: {id: w.id, change: {SetFixed: height}}});
        // niri places floating windows inside the space bars reserve; an auto-hiding
        // bar reserves none, so the rest of its height is added here
        const y = top - ShellLayout.dockAdjacentThickness(screen, "top") + geo.gap;
        act({MoveFloatingWindow: {id: w.id, x: {SetFixed: geo.rail + geo.gap}, y: {SetFixed: Math.max(geo.gap, y)}}});
        act({FocusWindow: {id: w.id}});
    }

    //--- How far DMS's bars reach in from one edge, auto-hiding ones included
    function inset(screen, side) {
        return screen ? ShellLayout.edge(screen, side)?.occupancy ?? 0 : 0;
    }

    //--- A rail key pressed on a monitor without the rail: true when it moves the rail
    //--- there, taking the shown app along
    function claimFocusedOutput() {
        const output = focusedWs()?.output ?? "";
        if (shown && output === railOutput)
            return false;
        const moving = shown && activeId !== "";
        if (moving)
            stash(activeId);
        railOutput = output;
        stashWs = -1;
        return moving;
    }

    //--- An app's own key: shows the rail on it, or hides the rail when it's the one shown
    function toggleApp(id) {
        const moved = claimFocusedOutput();
        if (shown && !moved && activeId === id)
            hide();
        else
            open(id);
    }

    function open(id) {
        const a = app(id);
        if (!a)
            return;
        if (activeId && activeId !== id)
            stash(activeId);
        activeId = id;
        saveState("lastId", id);
        shown = true;
        markHidden(id, false);
        const w = windowOf(a);
        if (w) {
            place(a, w);
        } else {
            pendingId = id;
            pendingTimeout.restart();
            // Its own scope, out of dms.service, so a DMS restart leaves it running
            const unit = "app-dms-side-rail-" + id + "-" + Date.now().toString(36);
            Quickshell.execDetached(["systemd-run", "--user", "--scope", "--collect", "--quiet", "--unit=" + unit].concat(a.command));
        }
    }

    function hide() {
        if (activeId)
            stash(activeId);
        pendingId = "";
        shown = false;
    }

    function toggle() {
        const moved = claimFocusedOutput();
        if (shown && !moved) {
            hide();
            return;
        }
        const last = activeId || state("lastId", null);
        // "" after the docked app was unloaded: the rail alone
        if (last === "")
            shown = true;
        else
            open(app(last) ? last : (config.apps[0]?.id ?? ""));
    }

    function railScreen() {
        return Quickshell.screens.find(s => s.name === railOutput) ?? Quickshell.screens[0] ?? null;
    }

    //--- A launched app's window: dock it once it opens
    Timer {
        id: pendingTimeout
        interval: 20000
        onTriggered: root.pendingId = ""
    }

    //--- Unloads apps hidden past their time, only while one could be
    Timer {
        id: sweepTimer
        interval: 60000
        repeat: true

        function update() {
            running = Object.keys(root.hiddenSince).some(id => {
                const a = root.app(id);
                return a && !root.keepOf(a);
            });
        }

        onTriggered: {
            for (const id of Object.keys(root.hiddenSince)) {
                const a = root.app(id);
                const w = root.windowOf(a);
                if (!w) {
                    root.markHidden(id, false);
                    continue;
                }
                const visible = NiriService.workspaces[w.workspace_id]?.is_active ?? false;
                if (!visible && !root.keepOf(a) && Date.now() - root.hiddenSince[id] >= root.timeoutOf(a) * 60000)
                    root.unload(id);
            }
        }
    }

    //--- After unload(): an app whose window closed but whose process lives on (tray)
    //--- gets the scope holding that pid stopped, and the rail's own launch scope.
    //--- Only app-*.scope units, so never dms.service; an app still showing its window
    //--- (asking to save, kitty confirming) is left to the user
    Timer {
        id: trayCheck
        interval: 5000
        onTriggered: {
            for (const id of Object.keys(root.closing)) {
                if (root.windowOf(root.app(id)))
                    continue;
                Quickshell.execDetached(["sh", "-c", 'u=$(sed -n "s|^0::.*/||p" /proc/$1/cgroup 2>/dev/null); '
                    + 'case $u in app-*.scope) systemctl --user stop "$u" ;; esac; '
                    + 'systemctl --user stop "app-dms-side-rail-$2-*.scope"', "sh", String(root.closing[id]), id]);
            }
            root.closing = {};
        }
    }

    //--- Saves a drag-resized width a moment after the resize settles
    Timer {
        id: widthSaver
        interval: 600
        onTriggered: {
            const w = root.windowOf(root.app(root.activeId));
            if (w)
                root.rememberWidth(root.activeId, w);
        }
    }

    Connections {
        target: NiriService
        enabled: root.shown

        function onWindowsChanged() {
            if (root.pendingId) {
                const a = root.app(root.pendingId);
                const w = root.windowOf(a);
                if (w) {
                    root.pendingId = "";
                    pendingTimeout.stop();
                    if (a.id === root.activeId)
                        root.place(a, w);
                }
            } else if (!NiriService.titleOnlyWindowsUpdate) {
                widthSaver.restart();
            }
        }

        //--- The docked app follows a workspace switch on the rail's monitor only
        function onWorkspacesChanged() {
            const w = root.windowOf(root.app(root.activeId));
            const ws = root.railWs();
            if (!w || !ws || w.workspace_id === ws.id || ws.id === root.stashWs)
                return;
            root.act({MoveWindowToWorkspace: {window_id: w.id, reference: {Id: ws.id}, focus: false}});
            if (NiriService.focusedWorkspaceId == ws.id)
                root.act({FocusWindow: {id: w.id}});
        }
    }

    //--- The rail itself, only alive while shown
    LazyLoader {
        active: root.shown

        PanelWindow {
            id: rail
            screen: root.railScreen()
            WlrLayershell.namespace: "dms:side-rail"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            // Placed by hand below the bar, which may auto-hide and reserve nothing
            exclusionMode: ExclusionMode.Ignore
            anchors {
                left: true
                top: true
            }
            margins.top: root.inset(screen, "top") + root.geo.gap
            margins.left: root.geo.gap / 2
            // Only as tall as its icons
            implicitWidth: root.geo.rail - root.geo.gap / 2
            implicitHeight: icons.implicitHeight + Theme.spacingS * 2
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                radius: Theme.cornerRadius
                color: Theme.withAlpha(Theme.surfaceContainer, Theme.popupTransparency)

                Column {
                    id: icons
                    anchors.top: parent.top
                    anchors.topMargin: Theme.spacingS
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.spacingS

                    Repeater {
                        model: root.config.apps

                        Rectangle {
                            id: entry
                            required property var modelData
                            readonly property bool active: modelData.id === root.activeId
                            readonly property bool running: root.windowOf(modelData) !== null
                            // An image file, a theme icon, or else a Material Symbol name
                            readonly property string iconPath: modelData.icon.startsWith("/") ? "file://" + modelData.icon : Quickshell.iconPath(modelData.icon, true)
                            width: root.geo.rail - root.geo.gap - Theme.spacingS
                            height: width
                            radius: Theme.cornerRadius
                            color: active ? Theme.withAlpha(Theme.primary, 0.25) : (mouse.containsMouse ? Theme.withAlpha(Theme.surfaceText, 0.08) : "transparent")

                            IconImage {
                                visible: entry.iconPath !== ""
                                source: entry.iconPath
                                implicitSize: parent.width * 0.62
                                anchors.centerIn: parent
                            }

                            DIcon {
                                visible: entry.iconPath === ""
                                name: entry.modelData.icon
                                size: parent.width * 0.55
                                color: entry.active ? Theme.primary : Theme.surfaceText
                                anchors.centerIn: parent
                            }

                            // Running, shown or not
                            Rectangle {
                                visible: entry.running
                                width: 4
                                height: 4
                                radius: 2
                                color: Theme.primary
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            MouseArea {
                                id: mouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: event => {
                                    if (event.button === Qt.RightButton) {
                                        const p = entry.mapToItem(null, entry.width, 0);
                                        // Cleared first so the items rebuild
                                        menu.forApp = null;
                                        menu.forApp = entry.modelData;
                                        menu.open(rail.screen, p.x, p.y, false);
                                    } else if (entry.active) {
                                        root.hide();
                                    } else {
                                        root.open(entry.modelData.id);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            //--- Unloading and width presets for one app, and back to its defaults
            DContextMenu {
                id: menu
                property var forApp: null
                layerNamespace: "dms:side-rail-menu"
                menuItems: {
                    const t = forApp;
                    if (!t)
                        return [];
                    const keep = root.keepOf(t);
                    const minutes = root.timeoutOf(t);
                    const items = [];
                    if (root.windowOf(t))
                        items.push({
                            type: "item",
                            icon: "power_settings_new",
                            text: "Unload now",
                            action: () => root.unload(t.id)
                        }, {type: "separator"});
                    items.push({
                        type: "item",
                        icon: keep ? "check_box" : "check_box_outline_blank",
                        text: "Keep running",
                        action: () => root.setUnload(t, {keep: !keep})
                    });
                    for (const m of root.geo.unloadPresets)
                        items.push({
                            type: "item",
                            icon: !keep && m === minutes ? "radio_button_checked" : "radio_button_unchecked",
                            text: "Unload after " + m + " min",
                            enabled: !keep,
                            action: () => root.setUnload(t, {keep: false, minutes: m})
                        });
                    items.push({type: "separator"});
                    for (const name of Object.keys(root.geo.presets))
                        items.push({
                            type: "item",
                            icon: "width",
                            text: name + " (" + root.geo.presets[name] + "px)",
                            action: () => root.setWidth(t, root.geo.presets[name])
                        });
                    items.push({type: "separator"}, {
                        type: "item",
                        icon: "restart_alt",
                        text: "Reset to default (" + t.width + "px, " + (t.keepRunning ? "kept running" : t.unloadAfter + " min") + ")",
                        action: () => {
                            root.setWidth(t, null);
                            root.setUnload(t, null);
                        }
                    });
                    return items;
                }
            }
        }
    }

    IpcHandler {
        target: "sideRail"

        function toggle(): string {
            root.toggle();
            return root.shown ? "OPENED" : "CLOSED";
        }

        function show(id: string): string {
            if (!root.app(id))
                return "NO APP " + id;
            root.open(id);
            return "OPENED";
        }

        function toggleApp(id: string): string {
            if (!root.app(id))
                return "NO APP " + id;
            root.toggleApp(id);
            return root.shown ? "OPENED" : "CLOSED";
        }

        function hide(): string {
            root.hide();
            return "CLOSED";
        }

        function unload(id: string): string {
            if (!root.app(id))
                return "NO APP " + id;
            root.unload(id);
            return "UNLOADED";
        }
    }
}
