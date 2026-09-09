import SwiftUI

/// Where a bubble's tail points, as a fraction of the bubble's own width.
enum DemoBubbleTail {
    case bottomLeading
    case bottomTrailing
    case topLeading
    case topTrailing
    case none
}

/// An ellipse with a tail. The tail is unioned into the ellipse so the
/// stroke runs around the outside only.
struct DemoBubbleShape: Shape {
    let tail: DemoBubbleTail

    func path(in rect: CGRect) -> Path {
        let inset: CGFloat = 12
        let body = rect.insetBy(dx: 0, dy: inset)
        var path = Path(ellipseIn: body)
        switch self.tail {
        case .none:
            return path
        case .bottomLeading:
            path.addPath(self.tailPath(from: CGPoint(x: body.minX + body.width * 0.30, y: body.maxY - 6), tip: CGPoint(x: body.minX + body.width * 0.12, y: rect.maxY), toward: CGPoint(x: body.minX + body.width * 0.45, y: body.maxY - 4)))
        case .bottomTrailing:
            path.addPath(self.tailPath(from: CGPoint(x: body.maxX - body.width * 0.30, y: body.maxY - 6), tip: CGPoint(x: body.maxX - body.width * 0.12, y: rect.maxY), toward: CGPoint(x: body.maxX - body.width * 0.45, y: body.maxY - 4)))
        case .topLeading:
            path.addPath(self.tailPath(from: CGPoint(x: body.minX + body.width * 0.30, y: body.minY + 6), tip: CGPoint(x: body.minX + body.width * 0.12, y: rect.minY), toward: CGPoint(x: body.minX + body.width * 0.45, y: body.minY + 4)))
        case .topTrailing:
            path.addPath(self.tailPath(from: CGPoint(x: body.maxX - body.width * 0.30, y: body.minY + 6), tip: CGPoint(x: body.maxX - body.width * 0.12, y: rect.minY), toward: CGPoint(x: body.maxX - body.width * 0.45, y: body.minY + 4)))
        }
        return path
    }

    private func tailPath(from: CGPoint, tip: CGPoint, toward: CGPoint) -> Path {
        var path = Path()
        path.move(to: from)
        path.addLine(to: tip)
        path.addLine(to: toward)
        path.closeSubpath()
        return path
    }
}

/// Speech text in a bubble. `size` scales the type with the page.
struct DemoSpeechBubble: View {
    let text: String
    var tail: DemoBubbleTail = .bottomLeading
    var size: CGFloat = 15

    var body: some View {
        Text(self.text)
            .font(DemoInk.speech(self.size))
            .multilineTextAlignment(.center)
            .foregroundStyle(DemoInk.ink)
            .padding(.horizontal, self.size * 1.4)
            .padding(.vertical, self.size * 1.5)
            .background(
                DemoBubbleShape(tail: self.tail)
                    .fill(DemoInk.paper)
                    .stroke(DemoInk.ink, lineWidth: DemoInk.bubbleStroke)
            )
    }
}

/// A jagged burst for a sound effect.
struct DemoBurstShape: Shape {
    var points = 14
    var depth: CGFloat = 0.22

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = CGSize(width: rect.width / 2, height: rect.height / 2)
        var path = Path()
        for index in 0..<(self.points * 2) {
            let angle = CGFloat(index) / CGFloat(self.points * 2) * .pi * 2 - .pi / 2
            let scale: CGFloat = index.isMultiple(of: 2) ? 1 : 1 - self.depth
            let point = CGPoint(x: center.x + cos(angle) * outer.width * scale, y: center.y + sin(angle) * outer.height * scale)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

/// Sound-effect lettering, optionally inside a burst.
struct DemoSoundEffect: View {
    let text: String
    var size: CGFloat = 40
    var burst = false

    var body: some View {
        Text(self.text)
            .font(DemoInk.sfx(self.size))
            .foregroundStyle(DemoInk.ink)
            .padding(.horizontal, self.burst ? self.size * 0.9 : 0)
            .padding(.vertical, self.burst ? self.size * 0.7 : 0)
            .background {
                if self.burst {
                    DemoBurstShape()
                        .fill(DemoInk.paper)
                        .stroke(DemoInk.ink, lineWidth: DemoInk.panelStroke)
                }
            }
    }
}
