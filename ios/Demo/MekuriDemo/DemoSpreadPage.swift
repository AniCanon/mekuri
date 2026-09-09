import SwiftUI

enum DemoSpreadHalf {
    case left
    case right
}

/// One half of a composition drawn at twice the page width. The two pages
/// of the spread each show their half so the picture runs across the spine.
struct DemoSpreadPage: View {
    let half: DemoSpreadHalf
    let scale: CGFloat

    var body: some View {
        GeometryReader { proxy in
            DemoSpreadComposition(scale: self.scale)
                .frame(width: proxy.size.width * 2, height: proxy.size.height)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: self.half == .left ? .leading : .trailing)
                .clipped()
        }
    }
}

/// The full spread: a moon over mountains straddling the spine, a bubble
/// that crosses it, and a figure and a broadcast on each page.
struct DemoSpreadComposition: View {
    let scale: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            ZStack {
                DemoSpeedLines(focus: CGPoint(x: 0.5, y: 0.38), count: 140, clearRadius: 0.36)
                    .opacity(0.9)
                DemoMoon()
                    .frame(width: height * 0.52, height: height * 0.52)
                    .position(x: width * 0.5, y: height * 0.36)
                DemoMountains()
                    .frame(height: height * 0.42)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                DemoFigure(pose: .pointing)
                    .frame(width: height * 0.24, height: height * 0.30)
                    .position(x: width * 0.16, y: height * 0.68)
                DemoFigure(pose: .running)
                    .scaleEffect(x: -1)
                    .frame(width: height * 0.24, height: height * 0.30)
                    .position(x: width * 0.84, y: height * 0.70)
                DemoSpeechBubble(text: "Both pages are one leaf.", tail: .none, size: 18 * self.scale)
                    .position(x: width * 0.5, y: height * 0.83)
                DemoCaption(text: "Chapter Two — the spread", size: 13 * self.scale)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(DemoInk.margin - DemoInk.panelStroke / 2)
                DemoBroadcastPanel(size: 13 * self.scale)
                    .padding(10 * self.scale)
                    .background(Rectangle().fill(DemoInk.paper).stroke(DemoInk.ink, lineWidth: DemoInk.panelStroke))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(DemoInk.margin - DemoInk.panelStroke / 2)
                DemoBroadcastPanel(size: 13 * self.scale)
                    .padding(10 * self.scale)
                    .background(Rectangle().fill(DemoInk.paper).stroke(DemoInk.ink, lineWidth: DemoInk.panelStroke))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(DemoInk.margin - DemoInk.panelStroke / 2)
                DemoSoundEffect(text: "FWIP", size: 44 * self.scale, burst: true)
                    .rotationEffect(.degrees(-10))
                    .position(x: width * 0.30, y: height * 0.26)
            }
            .clipShape(Rectangle().inset(by: DemoInk.margin))
            .overlay(Rectangle().inset(by: DemoInk.margin).stroke(DemoInk.ink, lineWidth: DemoInk.panelStroke))
        }
    }
}
