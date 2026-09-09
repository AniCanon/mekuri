import Mekuri
import SwiftUI

struct DemoReaderView: View {
    @State private var currentPage = 0
    @State private var direction: MekuriDirection = .leftToRight
    @State private var pagingEnabled = true
    @State private var slowTurns = false
    @State private var chromeVisible = true
    /// Keyed by page index; page views are recreated across turns.
    @State private var tapCounts: [Int: Int] = [:]

    private let pageCount = DemoPageStyle.count

    private var configuration: MekuriConfiguration {
        self.slowTurns
            ? MekuriConfiguration(settleAnimation: .linear(duration: 4))
            : .default
    }

    var body: some View {
        ZStack {
            Color(white: 0.12)
                .ignoresSafeArea()
            MekuriPager(
                pageCount: self.pageCount,
                currentPage: self.$currentPage,
                direction: self.direction,
                configuration: self.configuration
            ) { index, mode in
                DemoPageView(
                    index: index,
                    mode: mode,
                    tapCount: self.tapCounts[index, default: 0],
                    onButtonTap: { self.tapCounts[index, default: 0] += 1 }
                )
            }
            .mekuriPagingEnabled(self.pagingEnabled)
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
                    pageCount: self.pageCount
                )
                .transition(.opacity)
            }
        }
        .statusBarHidden(!self.chromeVisible)
    }
}

#Preview {
    DemoReaderView()
}
