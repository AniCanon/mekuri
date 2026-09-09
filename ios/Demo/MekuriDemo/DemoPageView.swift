import Mekuri
import SwiftUI

/// One page: a drawn composition chosen by index, a folio, and the harness
/// affordances when presentation mode is off. `spreadPairStart` is the
/// first of the two pages that share the spanning composition; under
/// right-to-left reading that page sits on the right.
struct DemoPageView: View {
    let index: Int
    let pageCount: Int
    let direction: MekuriDirection
    let spreadPairStart: Int
    let presentation: Bool
    let tapCount: Int
    let onButtonTap: () -> Void

    private enum Kind {
        case title
        case spread(DemoSpreadHalf)
        case grid(DemoPageLayout)
    }

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width, proxy.size.height) / 400
            ZStack {
                DemoInk.paper
                self.composition(scale: scale)
                Text("— \(self.index + 1) —")
                    .font(DemoInk.narration(11 * scale))
                    .foregroundStyle(DemoInk.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 2)
                if !self.presentation {
                    DemoHarnessOverlay(tapCount: self.tapCount, onButtonTap: self.onButtonTap)
                }
            }
        }
    }

    @ViewBuilder
    private func composition(scale: CGFloat) -> some View {
        switch self.kind {
        case .title:
            DemoTitlePage(scale: scale)
        case let .spread(half):
            DemoSpreadPage(half: half, scale: scale)
        case let .grid(layout):
            DemoGridPage(layout: layout, scale: scale)
        }
    }

    private var kind: Kind {
        let leadingHalf: DemoSpreadHalf = self.direction == .leftToRight ? .left : .right
        let trailingHalf: DemoSpreadHalf = self.direction == .leftToRight ? .right : .left
        if self.index == 0 { return .title }
        if self.index == self.spreadPairStart { return .spread(leadingHalf) }
        if self.index == self.spreadPairStart + 1 { return .spread(trailingHalf) }
        if self.index == self.pageCount - 1 { return .grid(.ending) }
        return .grid(self.index.isMultiple(of: 2) ? .threePanel : .fourGrid)
    }
}
