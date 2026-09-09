import SwiftUI

/// What is drawn inside a panel, behind its bubble and sound effect.
enum DemoPanelArt {
    case blank
    case tone
    case broadcast
    case figure(DemoPose, tone: Bool)
    case skyline
    case moon
    case speed(DemoPose?)
    case ending
}

struct DemoBubbleSpec {
    let text: String
    var tail: DemoBubbleTail = .bottomLeading
    var anchor = UnitPoint(x: 0.5, y: 0.25)
}

struct DemoSoundSpec {
    let text: String
    var anchor = UnitPoint(x: 0.5, y: 0.5)
    var burst = false
}

struct DemoPanelSpec {
    let frame: CGRect
    var art: DemoPanelArt = .blank
    var caption: String? = nil
    var bubble: DemoBubbleSpec? = nil
    var sound: DemoSoundSpec? = nil
}

/// Renders one panel spec. `scale` is the page's type scale.
struct DemoPanelView: View {
    let spec: DemoPanelSpec
    let scale: CGFloat

    var body: some View {
        DemoPanel {
            GeometryReader { proxy in
                ZStack {
                    self.art(in: proxy.size)
                    if let bubble = self.spec.bubble {
                        DemoSpeechBubble(text: bubble.text, tail: bubble.tail, size: 14 * self.scale)
                            .frame(maxWidth: proxy.size.width * 0.82)
                            .position(x: bubble.anchor.x * proxy.size.width, y: bubble.anchor.y * proxy.size.height)
                    }
                    if let sound = self.spec.sound {
                        DemoSoundEffect(text: sound.text, size: 34 * self.scale, burst: sound.burst)
                            .rotationEffect(.degrees(-8))
                            .position(x: sound.anchor.x * proxy.size.width, y: sound.anchor.y * proxy.size.height)
                    }
                    if let caption = self.spec.caption {
                        DemoCaption(text: caption, size: 12 * self.scale)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func art(in size: CGSize) -> some View {
        switch self.spec.art {
        case .blank:
            EmptyView()
        case .tone:
            DemoHalftone(spacing: 8 * self.scale, opacity: 0.35)
        case .broadcast:
            DemoBroadcastPanel(size: 15 * self.scale)
        case let .figure(pose, tone):
            ZStack {
                if tone {
                    DemoHalftone(spacing: 8 * self.scale, opacity: 0.30)
                        .frame(height: size.height * 0.45)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
                DemoFigure(pose: pose)
                    .frame(width: size.height * 0.5, height: size.height * 0.62)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, size.height * 0.05)
            }
        case .skyline:
            DemoSkyline()
        case .moon:
            DemoMoon()
                .padding(size.width * 0.12)
        case let .speed(pose):
            ZStack {
                DemoSpeedLines(focus: UnitPoint(x: 0.5, y: 0.55).point, clearRadius: 0.3)
                if let pose {
                    DemoFigure(pose: pose)
                        .frame(width: size.height * 0.5, height: size.height * 0.55)
                }
            }
        case .ending:
            VStack(spacing: 8 * self.scale) {
                Text("THE END")
                    .font(DemoInk.title(26 * self.scale))
                Text("turn back to begin again")
                    .font(DemoInk.narration(11 * self.scale))
            }
            .foregroundStyle(DemoInk.ink)
        }
    }
}

/// Boxed narration in a panel's corner.
struct DemoCaption: View {
    let text: String
    var size: CGFloat = 12

    var body: some View {
        Text(self.text)
            .font(DemoInk.narration(self.size))
            .foregroundStyle(DemoInk.ink)
            .padding(.horizontal, self.size * 0.8)
            .padding(.vertical, self.size * 0.5)
            .background(Rectangle().fill(DemoInk.paper).stroke(DemoInk.ink, lineWidth: DemoInk.bubbleStroke))
            .padding(-DemoInk.bubbleStroke / 2)
    }
}

extension UnitPoint {
    var point: CGPoint { CGPoint(x: self.x, y: self.y) }
}
