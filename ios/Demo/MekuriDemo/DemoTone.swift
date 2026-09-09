import SwiftUI

/// Screen tone: a dot grid whose dots grow toward the bottom of the area.
struct DemoHalftone: View {
    var spacing: CGFloat = 9
    var opacity: Double = 0.55

    var body: some View {
        Canvas { context, size in
            let columns = Int(size.width / self.spacing) + 1
            let rows = Int(size.height / self.spacing) + 1
            for row in 0..<rows {
                let growth = CGFloat(row) / CGFloat(max(rows - 1, 1))
                let radius = 0.6 + growth * (self.spacing * 0.42)
                for column in 0..<columns {
                    let stagger = row.isMultiple(of: 2) ? 0 : self.spacing / 2
                    let center = CGPoint(x: CGFloat(column) * self.spacing + stagger, y: CGFloat(row) * self.spacing)
                    let dot = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
                    context.fill(Path(ellipseIn: dot), with: .color(DemoInk.ink.opacity(self.opacity)))
                }
            }
        }
    }
}

/// Speed lines radiating from a focus point, leaving a clear disc around it.
struct DemoSpeedLines: View {
    var focus = CGPoint(x: 0.5, y: 0.5)
    var count = 72
    var clearRadius: CGFloat = 0.22

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: self.focus.x * size.width, y: self.focus.y * size.height)
            let reach = hypot(size.width, size.height)
            let clear = self.clearRadius * min(size.width, size.height)
            for index in 0..<self.count {
                let angle = CGFloat(index) / CGFloat(self.count) * .pi * 2
                let jitter = CGFloat((index * 37) % 11) / 11
                let start = clear * (1 + jitter * 0.6)
                let width = 0.8 + jitter * 2.2
                var path = Path()
                path.move(to: CGPoint(x: center.x + cos(angle) * start, y: center.y + sin(angle) * start))
                path.addLine(to: CGPoint(x: center.x + cos(angle) * reach, y: center.y + sin(angle) * reach))
                context.stroke(path, with: .color(DemoInk.ink), lineWidth: width)
            }
        }
    }
}

/// Horizontal scanlines for a panel that reads as a screen.
struct DemoScanlines: View {
    var spacing: CGFloat = 4

    var body: some View {
        Canvas { context, size in
            var y: CGFloat = 0
            while y < size.height {
                let line = CGRect(x: 0, y: y, width: size.width, height: 1)
                context.fill(Path(line), with: .color(DemoInk.ink.opacity(0.10)))
                y += self.spacing
            }
        }
    }
}
