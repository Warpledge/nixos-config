// A closure diff (closure.Diff.as_json): counts, then the package lists, each opening
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: view
    required property var diff
    readonly property bool none: !diff.updated.length && !diff.added.length && !diff.removed.length
    spacing: 6

    Flow {
        Layout.fillWidth: true
        spacing: 6
        Chip { visible: view.diff.updated.length > 0; accent: true; text: `${view.diff.updated.length} updated` }
        Chip { visible: view.diff.added.length > 0; tone: "success"; text: `${view.diff.added.length} new` }
        Chip { visible: view.diff.removed.length > 0; tone: "error"; text: `${view.diff.removed.length} removed` }
        Chip {
            readonly property var size: view.diff.size || []
            visible: !!size[0] && !!size[1] && size[0] !== size[1]
            text: `${Fmt.size(size[1] - size[0], true)} on disk`
        }
    }

    ListRow {
        visible: view.none
        icon: "check"
        title: "No package versions changed"
        subtitle: "Only settings and generated files did" + (view.diff.files ? ` (${view.diff.files} settings files)` : "")
    }

    Repeater {
        model: [
            { title: "Updated", items: view.diff.updated.map(i => [i[0], `${i[1]}  →  ${i[2]}`]) },
            { title: "New", items: view.diff.added.map(i => [i[0], i[1] === "ε" ? "" : i[1]]) },
            { title: "Removed", items: view.diff.removed.map(i => [i[0], i[1] === "ε" ? "" : i[1]]) }
        ].filter(g => g.items.length)
        Rectangle {
            id: group
            required property var modelData
            property bool open: false
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
                    ColumnLayout {
                        spacing: 1
                        Layout.fillWidth: true
                        Text {
                            text: `${group.modelData.title} (${group.modelData.items.length})`
                            color: Theme.text
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }
                        Text {
                            visible: !group.open
                            text: group.modelData.items.slice(0, 6).map(i => i[0]).join(", ")
                                  + (group.modelData.items.length > 6 ? "…" : "")
                            color: Theme.dim
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                    Icon { icon: "expand_more"; rotation: group.open ? 180 : 0 }
                    TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: group.open = !group.open }
                }
                Repeater {
                    model: group.open ? group.modelData.items.slice(0, 300) : []
                    RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        Text {
                            text: modelData[0]
                            color: Theme.text
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: modelData[1]
                            color: Theme.dim
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
}
