import SwiftUI

/// The cover: one full panel with the title over a skyline, and a small
/// inset panel for the broadcast.
struct DemoTitlePage: View {
    let scale: CGFloat

    var body: some View {
        DemoPanelGrid(frames: [CGRect(x: 0, y: 0, width: 1, height: 1)]) { _ in
            DemoPanel {
                GeometryReader { proxy in
                    ZStack {
                        DemoMoon()
                            .frame(width: proxy.size.width * 0.42, height: proxy.size.width * 0.42)
                            .position(x: proxy.size.width * 0.70, y: proxy.size.height * 0.24)
                        DemoSkyline()
                            .frame(height: proxy.size.height * 0.30)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                        VStack(spacing: 6 * self.scale) {
                            Text("Chapter One")
                                .font(DemoInk.narration(16 * self.scale))
                                .italic()
                            Text("MEKURI")
                                .font(DemoInk.title(58 * self.scale))
                                .tracking(4 * self.scale)
                            Text("the page turns the way paper does")
                                .font(DemoInk.narration(14 * self.scale))
                        }
                        .foregroundStyle(DemoInk.ink)
                        .padding(.horizontal, 20 * self.scale)
                        .padding(.vertical, 14 * self.scale)
                        .background(Rectangle().fill(DemoInk.paper).stroke(DemoInk.ink, lineWidth: DemoInk.panelStroke))
                        .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.60)
                        DemoBroadcastPanel(size: 13 * self.scale)
                            .padding(10 * self.scale)
                            .background(Rectangle().fill(DemoInk.paper).stroke(DemoInk.ink, lineWidth: DemoInk.panelStroke))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                            .padding(-DemoInk.panelStroke)
                    }
                }
            }
        }
    }
}
