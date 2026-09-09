import SwiftUI

/// One bordered panel: paper behind the content, the content clipped to the
/// panel, the ink border drawn over both.
struct DemoPanel<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            DemoInk.paper
            self.content()
        }
        .clipShape(Rectangle())
        .overlay(Rectangle().strokeBorder(DemoInk.ink, lineWidth: DemoInk.panelStroke))
    }
}

/// Lays out panels from unit-square frames inside the page margin, each
/// inset by half a gutter so neighbours sit a full gutter apart.
struct DemoPanelGrid<Content: View>: View {
    let frames: [CGRect]
    @ViewBuilder let panel: (Int) -> Content

    var body: some View {
        GeometryReader { proxy in
            let area = CGRect(origin: .zero, size: proxy.size).insetBy(dx: DemoInk.margin, dy: DemoInk.margin)
            ForEach(Array(self.frames.enumerated()), id: \.offset) { index, unit in
                let frame = Self.frame(unit, in: area)
                self.panel(index)
                    .frame(width: frame.width, height: frame.height)
                    .position(x: frame.midX, y: frame.midY)
            }
        }
    }

    static func frame(_ unit: CGRect, in area: CGRect) -> CGRect {
        CGRect(
            x: area.minX + unit.minX * area.width,
            y: area.minY + unit.minY * area.height,
            width: unit.width * area.width,
            height: unit.height * area.height
        )
        .insetBy(dx: DemoInk.gutter / 2, dy: DemoInk.gutter / 2)
    }
}
