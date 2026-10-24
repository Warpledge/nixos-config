// A Material Symbols glyph
import QtQuick

Text {
    property string icon
    property int size: 22
    property bool fill: false
    text: icon
    color: Theme.dim
    font.family: "Material Symbols Rounded"
    font.pixelSize: size
    font.variableAxes: { "FILL": fill ? 1 : 0 }
}
