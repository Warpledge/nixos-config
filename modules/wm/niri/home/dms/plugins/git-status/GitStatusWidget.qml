import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins

// Reads Omni Settings' `git` command, whose fetch and GitHub call share one
// limit and cache with the app (gitstate.remote), so polling here adds no
// GitHub requests beyond one per 5 minutes.
PluginComponent {
    id: root

    readonly property string backend: "@backend@"

    property var git: null
    property string error: ""
    property real now: Date.now()

    readonly property int changed: git ? git.changed.length + git.moreChanged : 0
    readonly property int ahead: git ? git.outgoing.length : 0
    readonly property int behind: git ? git.incoming.length : 0
    readonly property int prs: git && git.prs ? git.prs.length : 0
    readonly property bool problem: error !== "" || (git !== null && !!(git.fetchErr || git.prErr))

    function refresh(force) {
        if (query.running)
            return;
        query.command = [backend, "git", JSON.stringify(force ? {force: true} : {})];
        query.running = true;
    }

    function ago(epoch) {
        if (!epoch)
            return "never";
        const m = Math.round((now - epoch * 1000) / 60000);
        return m < 1 ? "just now" : m < 60 ? m + " min ago" : m < 1440 ? Math.round(m / 60) + " h ago"
                                                                         : Math.round(m / 1440) + " d ago";
    }

    Process {
        id: query
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const reply = JSON.parse(text);
                    if (reply.ok) {
                        root.git = reply.data;
                        root.error = "";
                    } else {
                        root.error = reply.error || "The backend failed";
                    }
                } catch (e) {
                    root.error = "The backend sent no reply";
                }
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.now = Date.now();
            root.refresh(false);
        }
    }

    // Counts left out at zero; a clean, up-to-date repo shows the icon alone
    readonly property var parts: [
        {text: "●" + changed, color: Theme.warning, show: changed > 0},
        {text: "↑" + ahead, color: Theme.primary, show: ahead > 0},
        {text: "↓" + behind, color: Theme.primary, show: behind > 0}
    ].filter(p => p.show)

    readonly property color iconColor: problem ? Theme.error
        : changed + ahead + behind + prs > 0 ? Theme.surfaceText : Theme.surfaceVariantText

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DIcon {
                name: "commit"
                size: root.iconSize
                color: root.iconColor
                anchors.verticalCenter: parent.verticalCenter
            }

            Repeater {
                model: root.parts
                StyledText {
                    text: modelData.text
                    color: modelData.color
                    font.pixelSize: root.textSize
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            DIcon {
                visible: root.prs > 0
                name: "merge"
                size: root.iconSize * 0.85
                color: Theme.secondary
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                visible: root.prs > 0
                text: root.prs
                color: Theme.secondary
                font.pixelSize: root.textSize
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: 1

            DIcon {
                name: "commit"
                size: root.iconSize
                color: root.iconColor
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Repeater {
                model: root.prs > 0 ? root.parts.concat([{text: "#" + root.prs, color: Theme.secondary}]) : root.parts
                StyledText {
                    text: modelData.text
                    color: modelData.color
                    font.pixelSize: root.textSize * 0.8
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    popoutWidth: 380
    popoutHeight: 440

    component Heading: StyledText {
        topPadding: Theme.spacingS
        color: Theme.surfaceVariantText
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.Medium
    }

    component Line: StyledText {
        width: parent.width
        elide: Text.ElideRight
        color: Theme.surfaceText
        font.pixelSize: Theme.fontSizeMedium
    }

    component ActionChip: StyledRect {
        id: button
        property string label
        property string icon
        signal clicked
        width: buttonRow.implicitWidth + Theme.spacingM * 2
        height: 30
        radius: Theme.cornerRadius
        color: Theme.chipSurface

        Row {
            id: buttonRow
            anchors.centerIn: parent
            spacing: Theme.spacingXS
            DIcon {
                name: button.icon
                size: Theme.iconSizeSmall
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                text: button.label
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        StateLayer {
            anchors.fill: parent
            onClicked: button.clicked()
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: pop
            headerText: "Git"
            detailsText: root.git ? (root.git.repo || "config repo") + " · " + root.git.branch
                                    + (root.git.upstream ? " → " + root.git.upstream : "") : ""

            Flickable {
                width: parent.width
                height: root.popoutHeight - pop.headerHeight - pop.detailsHeight - footer.height - Theme.spacingM * 2
                contentHeight: body.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: body
                    width: parent.width - Theme.spacingS * 2
                    x: Theme.spacingS
                    spacing: 2

                    Line {
                        visible: root.error !== ""
                        text: root.error
                        color: Theme.error
                        wrapMode: Text.WordWrap
                        elide: Text.ElideNone
                    }

                    Line {
                        visible: !!root.git && !!root.git.fetchErr
                        text: "Fetch failed: " + (root.git ? root.git.fetchErr : "")
                        color: Theme.error
                        wrapMode: Text.WordWrap
                        elide: Text.ElideNone
                    }

                    Heading {
                        text: root.changed ? "Changed files · " + root.changed : "No changes"
                    }
                    Repeater {
                        model: root.git ? root.git.changed.slice(0, 6) : []
                        Line {
                            text: modelData.path
                            color: modelData.state === "conflict" ? Theme.error : Theme.surfaceText
                        }
                    }
                    Line {
                        visible: root.changed > 6
                        text: "and " + (root.changed - 6) + " more"
                        color: Theme.surfaceVariantText
                    }

                    Heading {
                        visible: root.ahead > 0
                        text: "To push · " + root.ahead
                    }
                    Repeater {
                        model: root.git ? root.git.outgoing.slice(0, 5) : []
                        Line {
                            text: modelData.subject
                        }
                    }

                    Heading {
                        visible: root.behind > 0
                        text: "To pull · " + root.behind
                    }
                    Repeater {
                        model: root.git ? root.git.incoming.slice(0, 5) : []
                        Line {
                            text: modelData.subject
                        }
                    }

                    Heading {
                        text: !root.git || root.git.prs === null
                              ? (root.git && root.git.limited ? "Pull requests · GitHub's limit is used up"
                                                              : "Pull requests · couldn't reach GitHub")
                              : root.prs ? "Pull requests · " + root.prs : "No open pull requests"
                    }
                    Repeater {
                        model: root.git && root.git.prs ? root.git.prs : []
                        Item {
                            width: parent.width
                            height: prLine.implicitHeight + 6

                            Line {
                                id: prLine
                                anchors.verticalCenter: parent.verticalCenter
                                text: "#" + modelData.number + "  " + modelData.title
                                      + (modelData.draft ? " (draft)" : "") + " · " + modelData.author
                            }

                            StateLayer {
                                anchors.fill: parent
                                onClicked: Qt.openUrlExternally(modelData.url)
                            }
                        }
                    }
                }
            }

            Row {
                id: footer
                x: Theme.spacingS
                topPadding: Theme.spacingM
                spacing: Theme.spacingS

                ActionChip {
                    icon: "refresh"
                    label: query.running ? "Checking…" : "Refresh"
                    onClicked: root.refresh(true)
                }

                ActionChip {
                    icon: "settings"
                    label: "Omni Settings"
                    onClicked: {
                        Quickshell.execDetached(["dms", "ipc", "call", "omniSettings", "show"]);
                        if (pop.closePopout)
                            pop.closePopout();
                    }
                }

                StyledText {
                    text: "Fetched " + root.ago(root.git ? root.git.fetched : 0)
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
