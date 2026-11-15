// A thin line through `values` (0 to 1, oldest first), `count` samples across its width;
// `fill` shades under it, fading to nothing at the bottom (Preferences' Graphs)
import QtQuick
import QtQuick.Shapes

Shape {
    id: graph
    property var values: []
    property int count: 150
    property color color: Theme.primary
    property bool fill: Prefs.graphs === "filled"
    preferredRendererType: Shape.CurveRenderer

    readonly property var points: {
        const v = graph.values
        const step = graph.width / Math.max(1, graph.count - 1)
        const start = graph.count - v.length  // new samples come in from the right
        const h = graph.height - 2
        return v.map((y, i) => Qt.point((start + i) * step,
                                        1 + h * (1 - Math.max(0, Math.min(1, y)))))
    }

    ShapePath {
        strokeWidth: 0
        strokeColor: "transparent"
        fillGradient: LinearGradient {
            x1: 0; y1: 0
            x2: 0; y2: graph.height
            GradientStop { position: 0; color: Qt.alpha(graph.color, graph.fill ? 0.32 : 0) }
            GradientStop { position: 1; color: Qt.alpha(graph.color, 0) }
        }
        PathPolyline {
            path: {
                const p = graph.points
                if (p.length < 2 || !graph.fill)
                    return []
                return [Qt.point(p[0].x, graph.height)].concat(p, [Qt.point(p[p.length - 1].x, graph.height)])
            }
        }
    }
    ShapePath {
        strokeColor: graph.color
        strokeWidth: 1.3
        fillColor: "transparent"
        joinStyle: ShapePath.RoundJoin
        PathPolyline { path: graph.points }
    }
}
