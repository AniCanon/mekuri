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
            Toggle("Right to left", isOn: self.isRightToLeft)
            Toggle("Paging enabled", isOn: self.$pagingEnabled)
            Toggle("Slow turns", isOn: self.$slowTurns)
        }
        .font(.system(.body, design: .rounded, weight: .medium))
        .padding(20)
        .background(.ultraThinMaterial)
    }

    private var isRightToLeft: Binding<Bool> {
        Binding(
            get: { self.direction == .rightToLeft },
            set: { self.direction = $0 ? .rightToLeft : .leftToRight }
        )
    }
}
