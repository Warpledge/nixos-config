// The files a build would write (files.changes): /etc and each person's home
// files, each group opening to its changed paths and a short diff of the text
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: view
    required property var files
    readonly property var groups: !!files && !!files.groups ? files.groups : []
    spacing: 6

    function esc(t) {
        return t.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    }

    //--- A changed file's diff lines, each in its own colour; rich text needs <br/>
    function ink(lines) {
        const tones = { "+": Theme.success, "-": Theme.error }
        return lines.map(l => `<font color="${tones[l.charAt(0)] || Theme.dim}">${esc(l)}</font>`)
                    .join("<br/>")
    }

    Text {
        Layout.fillWidth: true
        Layout.leftMargin: 6
        text: view.groups.length
            ? "The files the new system would write, beyond the packages: /etc, and each "
              + "person's home files (niri's config.kdl among them)."
            : "No generated file would change."
        color: Theme.dim
        font.pixelSize: 13
        wrapMode: Text.Wrap
    }

    Flow {
        Layout.fillWidth: true
        spacing: 6
        Chip { tappable: false; visible: !!view.files && view.files.changed > 0; accent: true; text: view.files ? `${view.files.changed} changed` : "" }
        Chip { tappable: false; visible: !!view.files && view.files.added > 0; tone: "success"; text: view.files ? `${view.files.added} new` : "" }
        Chip { tappable: false; visible: !!view.files && view.files.removed > 0; tone: "error"; text: view.files ? `${view.files.removed} removed` : "" }
    }

    Repeater {
        model: view.groups
        Rectangle {
            id: group
            required property var modelData
            property bool open: true
            readonly property var items: modelData.items
            Layout.fillWidth: true
            implicitHeight: groupCol.implicitHeight + 20
            radius: 14
            color: Theme.card
            ColumnLayout {
                id: groupCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                anchors.leftMargin: 14
                spacing: 4
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: `${group.modelData.title} (${group.items.length})`
                        color: Theme.text
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                    }
                    Icon { icon: "expand_more"; rotation: group.open ? 180 : 0 }
                    TapHandler {
                        gesturePolicy: TapHandler.ReleaseWithinBounds
                        onTapped: group.open = !group.open
                    }
                }
                Repeater {
                    model: group.open ? group.items : []
                    ColumnLayout {
                        id: file
                        required property var modelData
                        property bool open: false
                        Layout.fillWidth: true
                        spacing: 4
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Icon {
                                icon: file.modelData.status === "added" ? "add_circle"
                                    : file.modelData.status === "removed" ? "remove_circle" : "edit"
                                size: 16
                                color: file.modelData.status === "added" ? Theme.success
                                    : file.modelData.status === "removed" ? Theme.error : Theme.primary
                            }
                            Text {
                                text: file.modelData.path
                                color: Theme.text
                                font.pixelSize: 13
                                elide: Text.ElideMiddle
                                Layout.fillWidth: true
                            }
                            Text {
                                visible: file.modelData.diff.length > 0 && !file.open
                                text: `${file.modelData.diff.length} diff lines`
                                color: Theme.dim
                                font.pixelSize: 12
                            }
                            Icon {
                                visible: file.modelData.diff.length > 0
                                icon: file.open ? "expand_less" : "expand_more"
                                size: 16
                            }
                        }
                        Text {
                            visible: file.open
                            Layout.fillWidth: true
                            Layout.leftMargin: 24
                            text: view.ink(file.modelData.diff)
                            textFormat: Text.StyledText
                            font.family: "monospace"
                            font.pixelSize: 12
                            wrapMode: Text.WrapAnywhere
                        }
                        TapHandler {
                            gesturePolicy: TapHandler.ReleaseWithinBounds
                            enabled: file.modelData.diff.length > 0
                            onTapped: file.open = !file.open
                        }
                    }
                }
            }
        }
    }
}
