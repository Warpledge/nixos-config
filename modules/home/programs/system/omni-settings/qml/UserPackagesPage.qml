// User Packages: every category (page "userpackages") or one ("userpackages:<name>"),
// each package with Move and Uninstall, and Undo for a pending removal
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    readonly property string category: view.page.startsWith("userpackages:") ? view.page.slice(13) : ""
    readonly property var now: view.userPackages(false)
    readonly property var saved: view.userPackages(true)
    //--- [{title, cat, names}]: pending removals stay listed under the category they were saved in
    readonly property var groups: {
        const current = view.flatPackages(now)
        const cats = category ? [category] : view.packageCategories
        const out = []
        for (const cat of cats) {
            const names = (now[cat] || []).concat((saved[cat] || []).filter(n => !current.includes(n)))
            if (names.length)
                out.push({ title: category ? "Installed" : cat, cat,
                           names: names.sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase())) })
        }
        return out
    }
    spacing: 6

    onGroupsChanged: view.describe(groups.reduce((all, g) => all.concat(g.names), []))
    Component.onCompleted: view.describe(groups.reduce((all, g) => all.concat(g.names), []))

    function move(cat, attr) {
        view.pickCategory(attr, cat, to => {
            const g = view.userPackages(false)
            g[cat] = (g[cat] || []).filter(n => n !== attr)
            g[to] = (g[to] || []).concat([attr])
            view.setUserPackages(g)
            view.say(`${attr} moves to ${to} when you apply`)
        })
    }

    function uninstall(attr) {
        const g = view.userPackages(false)
        for (const c of Object.keys(g))
            g[c] = g[c].filter(n => n !== attr)
        view.setUserPackages(g)
        if (view.packageState(attr) === "removing")
            view.say(`${attr} will be removed when you apply`)
    }

    function undo(cat, attr) {
        const g = view.userPackages(false)
        g[cat] = (g[cat] || []).concat([attr])
        view.setUserPackages(g)
    }

    //--- Hero
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: hero.implicitHeight + 28
        radius: 16
        color: Theme.card
        RowLayout {
            id: hero
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14
            Badge { implicitWidth: 56; implicitHeight: 56; radius: 28; icon: page.category ? "folder" : "package_2" }
            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                Text {
                    text: page.category || "User Packages"
                    color: Theme.text
                    font.pixelSize: 20
                    font.weight: Font.Bold
                }
                Text {
                    text: page.category
                        ? `User packages sorted under ${page.category}. Move one to list it under another category.`
                        : "Packages you added from Search, installed as they come with no settings of their own, "
                          + "sorted into categories you pick. Apps with settings made for them are under Default "
                          + "Packages."
                    color: Theme.dim
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
        }
    }

    Text {
        visible: page.groups.length > 0
        text: `Saved for ${page.view.scopeTitle()}.`
        color: Theme.dim
        font.pixelSize: 12
        Layout.leftMargin: 6
    }

    //--- Nothing yet
    Section { visible: !page.groups.length; text: "Installed" }
    ListRow {
        visible: !page.groups.length
        icon: "package_2"
        title: "No user packages yet"
        subtitle: "Find one on the Search page and press Install."
        chevron: true
        onClicked: page.view.go("packages", "packages")
    }

    Repeater {
        model: page.groups
        ColumnLayout {
            id: group
            required property var modelData
            Layout.fillWidth: true
            spacing: 6
            Section { text: modelData.title }
            Repeater {
                model: modelData.names
                PackageRow { required property var modelData; attr: modelData; cat: group.modelData.cat }
            }
        }
    }

    //--- One package: name, version and description, what Apply does to it, its buttons
    component PackageRow: Rectangle {
        id: row
        property string attr
        property string cat
        readonly property var info: page.view.packageInfo[attr] || null
        readonly property string where: page.view.packageState(attr)
        readonly property string was: page.view.categoryOf(page.saved, attr)
        Layout.fillWidth: true
        implicitHeight: rowLayout.implicitHeight + 22
        radius: 14
        color: Theme.card

        RowLayout {
            id: rowLayout
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 10
            anchors.rightMargin: 12
            spacing: 10
            Badge { icon: "package_2" }
            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true
                Text {
                    text: row.attr + (row.info && row.info.version
                        ? `  <font size="2" color="${Theme.dim}">${row.info.version}</font>` : "")
                    textFormat: Text.StyledText
                    color: Theme.text
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    visible: text !== ""
                    text: row.info ? row.info.description || "No description" : ""
                    color: Theme.dim
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
            Chip {
                visible: text !== ""
                accent: true
                tone: row.where === "removing" ? "caution" : row.where === "adding" ? "success" : ""
                text: row.where === "adding" ? "Installs on Apply"
                    : row.where === "removing" ? "Removed on Apply"
                    : row.was !== row.cat ? "Moves here on Apply" : ""
            }
            Pill {
                visible: row.where === "removing"
                text: "Undo"
                onClicked: page.undo(row.cat, row.attr)
            }
            IconButton {
                visible: row.where !== "removing"
                icon: "drive_file_move"
                tip: "Move to another category"
                onClicked: page.move(row.cat, row.attr)
            }
            Pill {
                visible: row.where !== "removing"
                text: "Uninstall"
                danger: true
                onClicked: page.uninstall(row.attr)
            }
        }
    }
}
