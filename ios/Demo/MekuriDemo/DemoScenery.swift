import SwiftUI

/// A row of buildings along the bottom of its area, with lit windows.
struct DemoSkyline: View {
    var body: some View {
        Canvas { context, size in
            var x: CGFloat = 0
            var seed = 7
            while x < size.width {
                seed = (seed * 1103515245 + 12345) % 2147483648
                let width = size.width * (0.06 + CGFloat(seed % 9) / 100)
                let height = size.height * (0.25 + CGFloat((seed / 9) % 45) / 100)
                let building = CGRect(x: x, y: size.height - height, width: width, height: height)
                context.fill(Path(building), with: .color(DemoInk.ink))
                let pane = max(3, width * 0.16)
                var wy = building.minY + pane
                while wy + pane < building.maxY {
                    var wx = building.minX + pane
                    while wx + pane < building.maxX {
                        seed = (seed * 1103515245 + 12345) % 2147483648
                        if seed % 3 != 0 {
                            context.fill(Path(CGRect(x: wx, y: wy, width: pane * 0.7, height: pane * 0.9)), with: .color(DemoInk.paper))
                        }
                        wx += pane * 1.6
                    }
                    wy += pane * 1.8
                }
                x += width + max(2, width * 0.12)
            }
            let ground = CGRect(x: 0, y: size.height - 3, width: size.width, height: 3)
            context.fill(Path(ground), with: .color(DemoInk.ink))
        }
    }
}

/// A moon: an ink ring with a toned crescent.
struct DemoMoon: View {
    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                Circle()
                    .fill(DemoInk.paper)
                DemoHalftone(spacing: max(6, side * 0.045), opacity: 0.45)
                    .clipShape(Circle())
                    .mask {
                        Circle()
                            .offset(x: -side * 0.28, y: -side * 0.1)
                            .blendMode(.destinationOut)
                            .background(Circle())
                            .compositingGroup()
                    }
                Circle()
                    .stroke(DemoInk.ink, lineWidth: DemoInk.panelStroke)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// A mountain range along the bottom of its area, filled with tone.
struct DemoMountains: View {
    var body: some View {
        Canvas { context, size in
            let peaks: [CGPoint] = [
                CGPoint(x: 0.00, y: 0.70), CGPoint(x: 0.08, y: 0.45), CGPoint(x: 0.16, y: 0.62),
                CGPoint(x: 0.27, y: 0.28), CGPoint(x: 0.36, y: 0.55), CGPoint(x: 0.44, y: 0.40),
                CGPoint(x: 0.53, y: 0.66), CGPoint(x: 0.62, y: 0.33), CGPoint(x: 0.71, y: 0.58),
                CGPoint(x: 0.80, y: 0.22), CGPoint(x: 0.90, y: 0.50), CGPoint(x: 1.00, y: 0.64),
            ]
            var range = Path()
            range.move(to: CGPoint(x: 0, y: size.height))
            for peak in peaks {
                range.addLine(to: CGPoint(x: peak.x * size.width, y: peak.y * size.height))
            }
            range.addLine(to: CGPoint(x: size.width, y: size.height))
            range.closeSubpath()
            context.fill(range, with: .color(DemoInk.ink.opacity(0.85)))
            context.stroke(range, with: .color(DemoInk.ink), lineWidth: DemoInk.panelStroke)
        }
    }
}
