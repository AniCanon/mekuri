import SwiftUI

enum DemoPose {
    case standing
    case pointing
    case running
    case reading
}

/// A silhouette drawn from a head, a torso and stroked limbs, scaled to the
/// height it is given.
struct DemoFigure: View {
    let pose: DemoPose

    var body: some View {
        Canvas { context, size in
            let unit = size.height
            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: size.width / 2 + x * unit, y: y * unit)
            }
            let limb = StrokeStyle(lineWidth: unit * 0.075, lineCap: .round, lineJoin: .round)
            let ink = GraphicsContext.Shading.color(DemoInk.ink)

            let lean: CGFloat = self.pose == .running ? 0.06 : 0
            let headRadius = unit * 0.10
            let head = CGRect(x: point(lean, 0.13).x - headRadius, y: point(0, 0.13).y - headRadius, width: headRadius * 2, height: headRadius * 2)
            context.fill(Path(ellipseIn: head), with: ink)

            var torso = Path()
            torso.move(to: point(-0.10 + lean, 0.26))
            torso.addLine(to: point(0.10 + lean, 0.26))
            torso.addLine(to: point(0.08, 0.58))
            torso.addLine(to: point(-0.08, 0.58))
            torso.closeSubpath()
            context.fill(torso, with: ink)

            var limbs = Path()
            switch self.pose {
            case .standing:
                limbs.move(to: point(-0.09, 0.30)); limbs.addLine(to: point(-0.16, 0.55))
                limbs.move(to: point(0.09, 0.30)); limbs.addLine(to: point(0.16, 0.55))
                limbs.move(to: point(-0.06, 0.58)); limbs.addLine(to: point(-0.08, 0.95))
                limbs.move(to: point(0.06, 0.58)); limbs.addLine(to: point(0.08, 0.95))
            case .pointing:
                limbs.move(to: point(-0.09, 0.30)); limbs.addLine(to: point(-0.15, 0.55))
                limbs.move(to: point(0.09, 0.30)); limbs.addLine(to: point(0.36, 0.30))
                limbs.move(to: point(-0.06, 0.58)); limbs.addLine(to: point(-0.08, 0.95))
                limbs.move(to: point(0.06, 0.58)); limbs.addLine(to: point(0.10, 0.95))
            case .running:
                limbs.move(to: point(-0.04, 0.30)); limbs.addLine(to: point(-0.24, 0.42))
                limbs.move(to: point(0.14, 0.30)); limbs.addLine(to: point(0.30, 0.18))
                limbs.move(to: point(-0.06, 0.58)); limbs.addLine(to: point(-0.30, 0.82))
                limbs.move(to: point(0.06, 0.58)); limbs.addLine(to: point(0.26, 0.92))
            case .reading:
                limbs.move(to: point(-0.09, 0.30)); limbs.addLine(to: point(-0.12, 0.46))
                limbs.move(to: point(0.09, 0.30)); limbs.addLine(to: point(0.12, 0.46))
                limbs.move(to: point(-0.06, 0.58)); limbs.addLine(to: point(-0.08, 0.95))
                limbs.move(to: point(0.06, 0.58)); limbs.addLine(to: point(0.08, 0.95))
            }
            context.stroke(limbs, with: ink, style: limb)

            if self.pose == .reading {
                let book = CGRect(x: point(-0.20, 0.42).x, y: point(0, 0.42).y, width: unit * 0.40, height: unit * 0.14)
                context.fill(Path(book), with: .color(DemoInk.paper))
                context.stroke(Path(book), with: ink, lineWidth: unit * 0.025)
                var spine = Path()
                spine.move(to: CGPoint(x: book.midX, y: book.minY))
                spine.addLine(to: CGPoint(x: book.midX, y: book.maxY))
                context.stroke(spine, with: ink, lineWidth: unit * 0.02)
            }
        }
    }
}
