import Mekuri
import SwiftUI

/// Pulsing dot and running clock. Only ever drawn on a live page; a turning
/// page draws `DemoFrozenIndicator` instead.
struct DemoLiveIndicator: View {
    var size: CGFloat = 20

    var body: some View {
        TimelineView(.animation) { context in
            let phase = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1)
            HStack(spacing: self.size * 0.5) {
                Circle()
                    .fill(DemoInk.accent)
                    .frame(width: self.size * 0.7, height: self.size * 0.7)
                    .scaleEffect(0.6 + 0.4 * abs(sin(phase * .pi)))
                Text("LIVE")
                    .fontWeight(.heavy)
                Text(context.date, format: .dateTime.hour().minute().second())
                    .monospacedDigit()
            }
            .font(.system(size: self.size, weight: .semibold, design: .rounded))
            .foregroundStyle(DemoInk.ink)
        }
    }
}

/// Static replacement for the live indicator while the page is turning.
struct DemoFrozenIndicator: View {
    var size: CGFloat = 20

    var body: some View {
        HStack(spacing: self.size * 0.5) {
            Circle()
                .stroke(DemoInk.ink, lineWidth: 2)
                .frame(width: self.size * 0.7, height: self.size * 0.7)
            Text("TURNING")
                .fontWeight(.heavy)
            Text("--:--:--")
                .monospacedDigit()
        }
        .font(.system(size: self.size, weight: .semibold, design: .rounded))
        .foregroundStyle(DemoInk.ink)
    }
}

/// A television drawn into a panel. Its screen shows the live indicator on
/// a settled page and the frozen one on a turning face.
struct DemoBroadcastPanel: View {
    @Environment(\.mekuriPageMode) private var mode
    var size: CGFloat = 18

    var body: some View {
        VStack(spacing: 0) {
            self.antenna
                .frame(width: self.size * 3, height: self.size * 1.4)
            ZStack {
                DemoScanlines(spacing: max(3, self.size * 0.22))
                VStack(spacing: self.size * 0.5) {
                    Text("ON AIR")
                        .font(DemoInk.sfx(self.size * 0.6))
                        .tracking(self.size * 0.2)
                        .foregroundStyle(self.mode == .live ? DemoInk.accent : DemoInk.ink)
                    self.indicator
                }
                .padding(.horizontal, self.size)
                .padding(.vertical, self.size * 0.9)
            }
            .fixedSize()
            .background(
                RoundedRectangle(cornerRadius: self.size * 0.8, style: .continuous)
                    .fill(DemoInk.paper)
                    .stroke(DemoInk.ink, lineWidth: DemoInk.panelStroke)
            )
        }
    }

    @ViewBuilder
    private var indicator: some View {
        switch self.mode {
        case .live: DemoLiveIndicator(size: self.size)
        case .turning: DemoFrozenIndicator(size: self.size)
        }
    }

    private var antenna: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: size.width / 2, y: size.height))
            path.addLine(to: CGPoint(x: size.width * 0.1, y: 0))
            path.move(to: CGPoint(x: size.width / 2, y: size.height))
            path.addLine(to: CGPoint(x: size.width * 0.9, y: 0))
            context.stroke(path, with: .color(DemoInk.ink), style: StrokeStyle(lineWidth: DemoInk.bubbleStroke, lineCap: .round))
        }
    }
}
