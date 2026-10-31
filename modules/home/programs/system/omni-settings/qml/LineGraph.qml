// A thin line through `values` (0 to 1, oldest first), `count` samples across its width
import QtQuick
import QtQuick.Shapes

Shape {
    id: graph
    property var values: []
    property int count: 150
    property color color: Theme.primary
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeColor: graph.color
        strokeWidth: 1.3
        fillColor: "transparent"
        joinStyle: ShapePath.RoundJoin
        PathPolyline {
            path: {
                const v = graph.values
                const step = graph.width / Math.max(1, graph.count - 1)
                const start = graph.count - v.length  // new samples come in from the right
                const h = graph.height - 2
                return v.map((y, i) => Qt.point((start + i) * step,
                                                1 + h * (1 - Math.max(0, Math.min(1, y)))))
            }
        }
    }
}
