import Mekuri
import SwiftUI

/// Counter and controls the centre tap shows and hides. The counter reads
/// the same binding the pager writes.
struct DemoChromeView: View {
    @Binding var currentPage: Int
    @Binding var direction: MekuriDirection
    @Binding var pagingEnabled: Bool
    @Binding var slowTurns: Bool
    let pageCount: Int

    var body: some View {
        VStack {
            self.header
            Spacer()
            self.controls
        }
    }

    private var header: some View {
        HStack {
            Text("Mekuri")
                .font(.system(.title2, design: .rounded, weight: .bold))
            Spacer()
            Text("Page \(self.currentPage + 1) of \(self.pageCount)")
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .monospacedDigit()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Stepper(value: self.$currentPage, in: 0...(self.pageCount - 1)) {
                Text("Page \(self.currentPage + 1)")
                    .monospacedDigit()
            }
            self.switchRow("Right to left", isOn: self.direction == .rightToLeft) {
                self.direction = self.direction == .rightToLeft ? .leftToRight : .rightToLeft
            }
            self.switchRow("Paging enabled", isOn: self.pagingEnabled) {
                self.pagingEnabled.toggle()
            }
            self.switchRow("Slow turns", isOn: self.slowTurns) {
                self.slowTurns.toggle()
            }
        }
        .font(.system(.body, design: .rounded, weight: .medium))
        .padding(20)
        .background(.ultraThinMaterial)
    }

    /// A button rather than a Toggle: a UISwitch ignores synthesised taps, which
    /// makes the demo undriveable from a script.
    private func switchRow(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                Text(isOn ? "ON" : "OFF")
                    .font(.system(.footnote, design: .rounded, weight: .heavy))
                    .foregroundStyle(isOn ? Color.black : Color.white)
                    .frame(width: 54, height: 30)
                    .background(isOn ? Color.green : Color.secondary, in: Capsule())
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var isRightToLeft: Binding<Bool> {
        Binding(
            get: { self.direction == .rightToLeft },
            set: { self.direction = $0 ? .rightToLeft : .leftToRight }
        )
    }
}
