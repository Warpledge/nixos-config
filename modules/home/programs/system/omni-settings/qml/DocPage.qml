// One note under docs/guide/ or docs/gaming/ (api.py's `doc`, page id "doc:…"). Links
// to other notes open their page, other repo files the text editor, web links the browser
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: page
    required property var view
    property var doc: null
    property string error: ""
    spacing: 10

    // A link to another note keeps this page loaded, so it reads the note anew
    readonly property string key: view.page
    onKeyChanged: load()
    Component.onCompleted: load()
    function load() {
        if (!key.startsWith("doc:"))
            return
        Backend.call("doc", { key }, reply => {
            if (reply.ok) {
                doc = reply.data
                error = ""
            } else {
                error = reply.error
            }
        })
    }

    function follow(href) {
        if (/^[a-z][a-z0-9+.-]*:/.test(href)) {
            Qt.openUrlExternally(href)
            return
        }
        Backend.call("docLink", { key: doc.key, href }, reply => {
            if (reply.ok && reply.data.doc)
                view.go("docs", reply.data.doc)
            else if (reply.ok && reply.data.file)
                view.openFile(reply.data.file)
            else
                view.say(`No page for ${href.split("/").pop()}`)
        })
    }

    //--- Where the note lives, and a button to open it
    RowLayout {
        visible: !!page.doc
        Layout.fillWidth: true
        Text {
            text: page.doc ? page.doc.path : ""
            color: Theme.dim
            font.pixelSize: 12
            elide: Text.ElideMiddle
            Layout.fillWidth: true
            Layout.leftMargin: 6
        }
        IconButton {
            icon: "open_in_new"
            tip: "Open the file"
            onClicked: page.view.openFile(page.doc.path)
        }
    }

    Text {
        visible: page.error !== ""
        text: page.error
        color: Theme.error
        wrapMode: Text.Wrap
        Layout.fillWidth: true
        Layout.margins: 6
    }

    Repeater {
        model: page.doc ? page.doc.blocks : []
        // Only the width is set on the Loader, so the block's wrapped height isn't fed back
        Item {
            required property var modelData
            Layout.fillWidth: true
            Layout.topMargin: modelData.kind === "h" && modelData.level > 1 ? 10 : 0
            implicitHeight: blockLoader.item ? blockLoader.item.implicitHeight : 0
            Loader {
                id: blockLoader
                width: parent.width
                readonly property var block: parent.modelData
                sourceComponent: ({ h: heading, p: paragraph, quote: quote, code: code, list: list,
                                    table: table, rule: rule })[block.kind] || null
            }
        }
    }

    component Rich: Text {
        textFormat: Text.RichText
        color: Theme.text
        linkColor: Theme.primary
        font.pixelSize: 15
        wrapMode: Text.Wrap
        onLinkActivated: href => page.follow(href)
        HoverHandler { cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor }
    }

    Component {
        id: heading
        Rich {
            text: parent.block.html
            font.pixelSize: ({ 1: 26, 2: 20, 3: 17 })[parent.block.level] || 16
            font.weight: Font.Bold
        }
    }

    Component {
        id: paragraph
        Rich { text: parent.block.html }
    }

    Component {
        id: quote
        Rectangle {
            implicitHeight: quoteText.implicitHeight + 16
            radius: 10
            color: Theme.card
            Rectangle { width: 3; height: parent.height - 12; x: 6; y: 6; radius: 2; color: Theme.primary }
            Rich {
                id: quoteText
                x: 18
                y: 8
                width: parent.width - 28
                color: Theme.dim
                text: parent.parent.block.html
            }
        }
    }

    Component {
        id: code
        Rectangle {
            implicitHeight: codeText.implicitHeight + 20
            radius: 12
            color: Theme.card
            TextEdit {
                id: codeText
                x: 12
                y: 10
                width: parent.width - 24
                readOnly: true
                selectByMouse: true
                text: parent.parent.block.text
                color: Theme.text
                selectionColor: Theme.primary
                font.family: "monospace"
                font.pixelSize: 13
                wrapMode: TextEdit.WrapAnywhere
            }
        }
    }

    Component {
        id: list
        ColumnLayout {
            readonly property var block: parent.block
            spacing: 4
            Repeater {
                model: parent.block.items
                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.leftMargin: 6 + 18 * modelData.depth
                    spacing: 8
                    Text {
                        text: parent.modelData.marker
                        color: Theme.dim
                        font.pixelSize: 15
                        Layout.alignment: Qt.AlignTop
                    }
                    Rich { text: parent.modelData.html; Layout.fillWidth: true }
                }
            }
        }
    }

    //--- Columns but the last as wide as their longest cell, up to docstate.TABLE_CHARS
    Component {
        id: table
        Rectangle {
            id: tableCard
            readonly property var block: parent.block
            implicitHeight: tableRows.implicitHeight + 8
            radius: 12
            color: Theme.card
            ColumnLayout {
                id: tableRows
                x: 12
                y: 4
                width: parent.width - 24
                spacing: 0
                Repeater {
                    model: tableCard.block.rows
                    ColumnLayout {
                        id: tableRow
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        spacing: 0
                        Rectangle {
                            visible: tableRow.index > 0
                            Layout.fillWidth: true
                            implicitHeight: 1
                            color: Theme.line
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                            Layout.bottomMargin: 8
                            spacing: 18
                            Repeater {
                                model: tableRow.modelData
                                Rich {
                                    required property var modelData
                                    required property int index
                                    readonly property bool last: index >= tableCard.block.widths.length
                                    text: tableRow.index === 0 ? `<b>${modelData}</b>` : modelData
                                    Layout.alignment: Qt.AlignTop
                                    Layout.fillWidth: last
                                    Layout.preferredWidth: last ? -1 : tableCard.block.widths[index] * 7
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: rule
        Rectangle { implicitHeight: 1; color: Theme.line }
    }
}
