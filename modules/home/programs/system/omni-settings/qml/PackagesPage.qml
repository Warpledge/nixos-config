// The Search page: nixpkgs by name through nix-search-tv (api.py's packageNames,
// matched here as packagestate.search does), Install adding to userPackages
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: page
    required property var view
    readonly property int shown: 50  // packagestate.SHOWN
    property string query: ""
    property var found: []
    spacing: 6

    Component.onCompleted: view.loadPackageNames()

    //--- As packagestate.search: every word, then the name, its start (or its
    //--- last part's) and anywhere
    function search(text) {
        const q = text.trim().toLowerCase()
        const words = q.split(/\s+/).filter(w => w)
        query = text.trim()
        if (!words.length || !view.packageNames) {
            found = []
            return
        }
        const hits = []
        const lower = view.packageLower
        for (let i = 0; i < lower.length; i++) {
            const low = lower[i]
            if (!words.every(w => low.includes(w)))
                continue
            const last = low.slice(low.lastIndexOf(".") + 1)
            const rank = low === q ? 0 : low.startsWith(q) || last.startsWith(q) ? 1 : 2
            hits.push([rank, low.split(".").length, low.length, view.packageNames[i]])
        }
        hits.sort((a, b) => a[0] - b[0] || a[1] - b[1] || a[2] - b[2] || (a[3] < b[3] ? -1 : a[3] > b[3] ? 1 : 0))
        found = hits.map(h => h[3])
        view.describe(found.slice(0, shown))
    }

    function install(attr) {
        if (view.flatPackages(view.userPackages(false)).includes(attr))
            return
        view.pickCategory(attr, "", cat => {
            const groups = view.userPackages(false)
            groups[cat] = (groups[cat] || []).concat([attr])
            view.setUserPackages(groups)
            view.say(`${attr} will be installed under ${cat} when you apply`)
        })
    }

    Timer { id: typing; interval: 150; onTriggered: page.search(field.text) }
    Connections {
        target: page.view
        function onPackageNamesChanged() {
            if (field.text.trim())
                page.search(field.text)
            field.input.forceActiveFocus()
        }
    }

    //--- Hero
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: hero.implicitHeight + 28
        radius: 16
        color: Theme.card
        ColumnLayout {
            id: hero
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10
            RowLayout {
                spacing: 14
                Badge { implicitWidth: 56; implicitHeight: 56; radius: 28; icon: "search" }
                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    Text { text: "Search"; color: Theme.text; font.pixelSize: 20; font.weight: Font.Bold }
                    Text {
                        text: "Search nixpkgs by package name and install what you need; it's added to User "
                              + "Packages and installed when you apply. Expand a result for its homepage, "
                              + "licence and the program it runs."
                        color: Theme.dim
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }
            Field {
                id: field
                enabled: !!page.view.packageNames
                icon: "search"
                placeholder: page.view.packageNames
                    ? `Search ${page.view.packageNames.length.toLocaleString(Qt.locale("en_US"), "f", 0)} packages`
                    : "Search packages"
                onTextChanged: typing.restart()
                onAccepted: {
                    typing.stop()
                    page.search(text)
                }
                Component.onCompleted: if (page.view.packageNames) input.forceActiveFocus()
            }
        }
    }

    //--- Reading the index
    ListRow {
        visible: !page.view.packageNames
        icon: page.view.packageError ? "error" : "progress_activity"
        title: page.view.packageError ? "Couldn't read the package list" : "Reading the package list…"
        subtitle: page.view.packageError
            || "The first time, and once a week after, the list is downloaded again; that takes a minute or so."
        titleLines: 2
    }

    //--- Results
    RowLayout {
        visible: page.query !== ""
        Layout.fillWidth: true
        Section {
            text: page.found.length ? "Results" : `Nothing is named like “${page.query}”`
            Layout.fillWidth: true
        }
        Text {
            text: page.found.length > page.shown
                ? `first ${page.shown} of ${page.found.length.toLocaleString(Qt.locale("en_US"), "f", 0)}`
                : page.found.length ? String(page.found.length) : ""
            color: Theme.dim
            font.pixelSize: 11
            Layout.rightMargin: 6
        }
    }
    Repeater {
        model: page.query ? page.found.slice(0, page.shown) : []
        ResultRow { required property var modelData; attr: modelData }
    }

    //--- One result: name, version and description, Install, copy, and its details
    //--- when expanded
    component ResultRow: Rectangle {
        id: result
        property string attr
        property bool open: false
        readonly property var info: page.view.packageInfo[attr] || null
        readonly property string where: page.view.packageState(attr)
        Layout.fillWidth: true
        implicitHeight: resultCol.implicitHeight + 22
        radius: 14
        color: hover.hovered && !open ? Theme.cardHover : Theme.card

        HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
        TapHandler { gesturePolicy: TapHandler.ReleaseWithinBounds; onTapped: result.open = !result.open }

        ColumnLayout {
            id: resultCol
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 10
            anchors.rightMargin: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Badge { icon: "package_2" }
                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true
                    Text {
                        text: result.attr + (result.info && result.info.version
                            ? `  <font size="2" color="${Theme.dim}">${result.info.version}</font>` : "")
                        textFormat: Text.StyledText
                        color: Theme.text
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: !result.info ? "…" : result.info.description || "No description"
                        color: Theme.dim
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
                Chip { visible: !!result.info && result.info.broken; tone: "error"; text: "Broken" }
                IconButton {
                    icon: "content_copy"
                    tip: "Copy the attribute name"
                    onClicked: {
                        Quickshell.clipboardText = result.attr
                        page.view.say(`Copied ${result.attr}`)
                    }
                }
                Pill {
                    text: result.where === "installed" ? "Installed" : result.where === "adding" ? "Added" : "Install"
                    quiet: text !== "Install"
                    enabled: text === "Install"
                    onClicked: page.install(result.attr)
                }
                Icon { icon: result.open ? "expand_less" : "expand_more"; size: 20 }
            }

            Text {
                visible: !!result.info && result.info.broken
                text: "nixpkgs marks it broken, so it may not build."
                color: Theme.caution
                font.pixelSize: 12
                Layout.leftMargin: 50
            }

            //--- Details
            ColumnLayout {
                visible: result.open && !!result.info
                Layout.fillWidth: true
                Layout.leftMargin: 50
                spacing: 6
                Repeater {
                    model: result.info ? result.info.homepage : []
                    Detail {
                        required property var modelData
                        label: "Homepage"
                        value: modelData
                        link: true
                    }
                }
                Detail {
                    label: "Licence"
                    value: !result.info ? "" : (result.info.licenses.join(", ") || "Not stated")
                        + (result.info.unfree ? " (unfree)" : "")
                }
                Detail { visible: !!result.info && !!result.info.program; label: "Runs"; value: result.info ? result.info.program : "" }
                Detail { visible: !!result.info && !!result.info.about; label: "About"; value: result.info ? result.info.about : "" }
            }
        }
    }

    component Detail: ColumnLayout {
        id: detail
        property string label
        property string value
        property bool link: false
        spacing: 0
        Layout.fillWidth: true
        Text { text: detail.label; color: Theme.text; font.pixelSize: 12; font.weight: Font.DemiBold }
        Text {
            text: detail.value
            color: detail.link ? Theme.primary : Theme.dim
            font.pixelSize: 12
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            HoverHandler { enabled: detail.link; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                enabled: detail.link
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: Qt.openUrlExternally(detail.value)
            }
        }
    }
}
