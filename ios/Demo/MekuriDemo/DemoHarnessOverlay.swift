import Mekuri
import SwiftUI

/// The affordances the gesture checks are driven through: letters along
/// each edge that name which edge is lifting, and a button in the centre
/// zone that must win over the centre tap. Hidden in presentation mode.
struct DemoHarnessOverlay: View {
    @Environment(\.mekuriPageMode) private var mode

    let tapCount: Int
    let onButtonTap: () -> Void

    var body: some View {
        ZStack {
            HStack {
                DemoEdgeMarker(letter: "L")
                Spacer()
                DemoEdgeMarker(letter: "R")
            }
            Button(action: self.onButtonTap) {
                Text("Tap me · \(self.tapCount)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(DemoInk.ink, in: Capsule())
                    .foregroundStyle(DemoInk.paper)
            }
            .disabled(self.mode == .turning)
        }
    }
}

struct DemoEdgeMarker: View {
    let letter: String

    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<7, id: \.self) { _ in
                Text(self.letter)
                    .font(.system(size: 26, weight: .black, design: .monospaced))
            }
        }
        .foregroundStyle(DemoInk.ink.opacity(0.5))
        .frame(width: 44)
        .frame(maxHeight: .infinity)
        .background(DemoInk.ink.opacity(0.10))
    }
}
