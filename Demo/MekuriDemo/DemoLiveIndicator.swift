import SwiftUI

/// Pulsing dot and running clock. Only ever drawn on a live page; a turning
/// page draws `DemoFrozenIndicator` instead.
struct DemoLiveIndicator: View {
    let ink: Color

    var body: some View {
        TimelineView(.animation) { context in
            let phase = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1)
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 14, height: 14)
                    .scaleEffect(0.6 + 0.4 * abs(sin(phase * .pi)))
                Text("LIVE")
                    .fontWeight(.heavy)
                Text(context.date, format: .dateTime.hour().minute().second())
                    .monospacedDigit()
            }
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .foregroundStyle(self.ink)
        }
    }
}

/// Static replacement for the live indicator while the page is turning.
struct DemoFrozenIndicator: View {
    let ink: Color

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .stroke(self.ink, lineWidth: 2)
                .frame(width: 14, height: 14)
            Text("TURNING")
                .fontWeight(.heavy)
            Text("--:--:--")
                .monospacedDigit()
        }
        .font(.system(size: 20, weight: .semibold, design: .rounded))
        .foregroundStyle(self.ink)
    }
}
