import Mekuri
import SwiftUI

/// Floating control card the centre tap shows and hides. The counter reads
/// the same binding the pager writes and goes away in presentation mode.
struct DemoChromeView: View {
    @Binding var currentPage: Int
    @Binding var direction: MekuriDirection
    @Binding var pagingEnabled: Bool
    @Binding var slowTurns: Bool
    @Binding var spread: MekuriSpread
    @Binding var coverStandsAlone: Bool
    @Binding var presentation: Bool
    let pageCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            self.header
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
            self.pillRow("Spread", label: self.spreadLabel, isOn: self.spread != .single) {
                self.spread = self.nextSpread
            }
            self.switchRow("Cover stands alone", isOn: self.coverStandsAlone) {
                self.coverStandsAlone.toggle()
            }
            self.switchRow("Presentation", isOn: self.presentation) {
                self.presentation.toggle()
            }
        }
        .font(.system(.body, design: .rounded, weight: .medium))
        .padding(18)
        .frame(width: 340)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(.white.opacity(0.18)))
        .shadow(color: .black.opacity(0.35), radius: 24, y: 10)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }

    private var header: some View {
        HStack {
            Text("Mekuri")
                .font(.system(.title3, design: .rounded, weight: .bold))
            Spacer()
            if !self.presentation {
                Text("Page \(self.currentPage + 1) of \(self.pageCount)")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .monospacedDigit()
            }
        }
        .padding(.bottom, 4)
    }

    private var spreadLabel: String {
        switch self.spread {
        case .automatic: "AUTO"
        case .single: "SINGLE"
        case .double: "DOUBLE"
        }
    }

    private var nextSpread: MekuriSpread {
        switch self.spread {
        case .automatic: .single
        case .single: .double
        case .double: .automatic
        }
    }

    /// A button rather than a Toggle: a UISwitch ignores synthesised taps, which
    /// makes the demo undriveable from a script.
    private func switchRow(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        self.pillRow(title, label: isOn ? "ON" : "OFF", isOn: isOn, action: action)
    }

    private func pillRow(_ title: String, label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                Text(label)
                    .font(.system(.footnote, design: .rounded, weight: .heavy))
                    .foregroundStyle(isOn ? Color.black : Color.white)
                    .frame(minWidth: 54)
                    .frame(height: 30)
                    .padding(.horizontal, 8)
                    .background(isOn ? Color.green : Color.secondary, in: Capsule())
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
