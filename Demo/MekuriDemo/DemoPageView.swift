import Mekuri
import SwiftUI

/// One demo page. The number, glyph and edge markers are identical in both
/// modes; only the indicator strip and the button differ. The vertical
/// insets keep the indicator and the button clear of the reader's chrome.
struct DemoPageView: View {
    let index: Int
    let mode: MekuriPageMode
    let tapCount: Int
    let onButtonTap: () -> Void

    private var style: DemoPageStyle { DemoPageStyle.style(for: self.index) }

    var body: some View {
        ZStack {
            self.style.paper
            self.edgeMarkers
            VStack(spacing: 16) {
                Image(systemName: self.style.glyph)
                    .font(.system(size: 64))
                    .foregroundStyle(self.style.ink.opacity(0.35))
                Text("\(self.index + 1)")
                    .font(.system(size: 160, weight: .black, design: .rounded))
                    .foregroundStyle(self.style.ink)
                Text(self.style.name)
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(self.style.ink)
            }
            self.indicator
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 124)
            self.button
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 244)
        }
    }

    @ViewBuilder
    private var indicator: some View {
        switch self.mode {
        case .live:
            DemoLiveIndicator(ink: self.style.ink)
        case .turning:
            DemoFrozenIndicator(ink: self.style.ink)
        }
    }

    private var button: some View {
        Button(action: self.onButtonTap) {
            Text("Tap me · \(self.tapCount)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(self.style.ink, in: Capsule())
                .foregroundStyle(self.style.paper)
        }
        .padding(.horizontal, 40)
        .disabled(self.mode == .turning)
    }

    /// Letters along each edge name which edge is lifting during a fold.
    private var edgeMarkers: some View {
        HStack {
            DemoEdgeMarker(letter: "L", ink: self.style.ink)
            Spacer()
            DemoEdgeMarker(letter: "R", ink: self.style.ink)
        }
    }
}

struct DemoEdgeMarker: View {
    let letter: String
    let ink: Color

    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<7, id: \.self) { _ in
                Text(self.letter)
                    .font(.system(size: 26, weight: .black, design: .monospaced))
            }
        }
        .foregroundStyle(self.ink.opacity(0.45))
        .frame(width: 44)
        .frame(maxHeight: .infinity)
        .background(self.ink.opacity(0.12))
    }
}
