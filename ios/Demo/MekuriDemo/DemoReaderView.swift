import Mekuri
import SwiftUI

struct DemoReaderView: View {
    @State private var currentPage = 0
    @State private var direction: MekuriDirection = .leftToRight
    @State private var pagingEnabled = true
    @State private var slowTurns = false
    @State private var spread: MekuriSpread = .automatic
    @State private var coverStandsAlone = true
    @State private var presentation = false
    @State private var chromeVisible = true
    /// Keyed by page index; page views are recreated across turns.
    @State private var tapCounts: [Int: Int] = [:]

    private let pageCount = 6

    private var settleAnimation: Animation? {
        self.slowTurns ? .linear(duration: 4) : nil
    }

    /// The spanning composition sits on the second spread, whose first page
    /// depends on whether the cover stands alone.
    private var spreadPairStart: Int {
        self.coverStandsAlone ? 3 : 2
    }

    /// Entering presentation mode hides the chrome with it; the centre tap
    /// brings the chrome back without leaving the mode.
    private var presentationBinding: Binding<Bool> {
        Binding(
            get: { self.presentation },
            set: { on in
                self.presentation = on
                if on {
                    withAnimation(.easeInOut(duration: 0.2)) { self.chromeVisible = false }
                }
            }
        )
    }

    var body: some View {
        ZStack {
            Color(white: 0.12)
                .ignoresSafeArea()
            MekuriPager(pageCount: self.pageCount, currentPage: self.$currentPage) { index in
                DemoPageView(
                    index: index,
                    pageCount: self.pageCount,
                    direction: self.direction,
                    spreadPairStart: self.spreadPairStart,
                    presentation: self.presentation,
                    tapCount: self.tapCounts[index, default: 0],
                    onButtonTap: { self.tapCounts[index, default: 0] += 1 }
                )
            }
            .mekuriDirection(self.direction)
            .mekuriPagingEnabled(self.pagingEnabled)
            .mekuriSettleAnimation(self.settleAnimation)
            .mekuriSpread(self.spread)
            .mekuriCoverStandsAlone(self.coverStandsAlone)
            .mekuriPageAspectRatio(2.0 / 3.0)
            .mekuriOnCenterTap {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.chromeVisible.toggle()
                }
            }
            .ignoresSafeArea()
            if self.chromeVisible {
                DemoChromeView(
                    currentPage: self.$currentPage,
                    direction: self.$direction,
                    pagingEnabled: self.$pagingEnabled,
                    slowTurns: self.$slowTurns,
                    spread: self.$spread,
                    coverStandsAlone: self.$coverStandsAlone,
                    presentation: self.presentationBinding,
                    pageCount: self.pageCount
                )
                .transition(.opacity)
            }
        }
        .statusBarHidden(self.presentation || !self.chromeVisible)
    }
}

#Preview {
    DemoReaderView()
}
