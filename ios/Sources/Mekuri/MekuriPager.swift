import SwiftUI

/// A page-curl pager over any content.
///
/// Pages are addressed by index in reading order and `currentPage` is the
/// selection, read and written by the consumer. A tap in an outer zone or a
/// horizontal drag turns one page, or one spread when two pages share the
/// container; the reading direction decides which edge is the spine and never
/// touches the numbering. Everything beyond the page count, the selection and
/// the content is an environment-backed modifier that cascades from any
/// ancestor:
///
/// ```swift
/// MekuriPager(pageCount: pages.count, currentPage: $index) { pageIndex in
///     PageView(page: pages[pageIndex])   // reads @Environment(\.mekuriPageMode)
/// }
/// .mekuriDirection(.rightToLeft)        // spine on the right, indices unchanged
/// .mekuriSpread(.automatic)             // two pages whenever they fit
/// .mekuriCoverStandsAlone(true)         // page 0 opens alone, like a cover
/// .mekuriPageAspectRatio(2.0 / 3.0)     // width over height of one page
/// .mekuriPagingEnabled(!isZoomed)
/// .mekuriOnCenterTap { chromeHidden.toggle() }
/// ```
///
/// Each page reads `\.mekuriPageMode`. The faces of the leaf being turned are
/// drawn `.turning` and rasterized by the fold shader; the pages beneath stay
/// `.live`. Only the visible page or spread and the two faces of a turning
/// leaf are ever built, and a settled pager evaluates nothing.
///
/// > Note: A `.turning` face must be drawable from what is already in memory.
/// > The fold samples a flattened copy of the page each frame, so content that
/// > arrives asynchronously turns as whatever is on screen when the turn
/// > begins, and anything animating inside it is rasterized as it plays. Stand
/// > live playback down in `.turning` and draw the last frame you have.
///
/// A blocked turn at either end lifts the page over the pager's own
/// background, so give the pager one.
public struct MekuriPager<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var systemReducesMotion
    @Environment(\.mekuriDirection) var direction
    @Environment(\.mekuriPagingEnabled) var pagingEnabled
    @Environment(\.mekuriOnCenterTap) var onCenterTap
    @Environment(\.mekuriFoldRadius) private var foldRadius
    @Environment(\.mekuriCornerLift) private var cornerLift
    @Environment(\.mekuriCreaseBow) private var creaseBow
    @Environment(\.mekuriTapZone) private var tapZone
    @Environment(\.mekuriSnapThreshold) private var snapThreshold
    @Environment(\.mekuriSettleAnimation) private var settleAnimation
    @Environment(\.mekuriReducedMotion) private var reducedMotionOverride
    @Environment(\.mekuriSpread) private var spread
    @Environment(\.mekuriCoverStandsAlone) private var coverStandsAlone
    @Environment(\.mekuriPageAspectRatio) private var pageAspectRatio

    let pageCount: Int
    @Binding var currentPage: Int
    let content: (Int) -> Content

    /// The page Mekuri is showing, or the page of the shown spread the
    /// consumer selected. Drives every layer; the binding follows it.
    @State var settledPage: Int
    @State var turn: MekuriTurnState?
    @State var presented = MekuriPresentedProgress()
    @State var nextTurnID = 0
    @State var settleCount = 0
    @State var ignoresCurrentDrag = false

    /// - Parameters:
    ///   - pageCount: Number of pages, in reading order.
    ///   - currentPage: The selected page. Written when a turn lands. A change
    ///     from outside curls to a neighbouring page or spread and crossfades
    ///     to anything further; a change within the shown spread moves
    ///     nothing.
    ///   - content: Builds the page at an index. Called for the visible page or
    ///     spread and for the faces of a turning leaf, never for any other.
    public init(
        pageCount: Int,
        currentPage: Binding<Int>,
        @ViewBuilder content: @escaping (Int) -> Content
    ) {
        self.pageCount = pageCount
        self._currentPage = currentPage
        self.content = content
        self._settledPage = State(initialValue: currentPage.wrappedValue)
    }

    var configuration: MekuriConfiguration {
        MekuriConfiguration(
            cylinderRadiusRatio: self.foldRadius,
            creaseBow: self.creaseBow,
            cornerShear: self.cornerLift,
            snapThreshold: self.snapThreshold,
            tapZoneRatio: self.tapZone,
            settleAnimation: self.settleAnimation ?? MekuriConfiguration.default.settleAnimation,
            reducedMotionOverride: self.reducedMotionOverride
        )
    }

    var reducesMotion: Bool {
        self.reducedMotionOverride ?? self.systemReducesMotion
    }

    func arrangement(for size: CGSize) -> MekuriArrangement {
        MekuriArrangement.resolve(
            containerSize: size,
            pageCount: self.pageCount,
            spread: self.spread,
            coverStandsAlone: self.coverStandsAlone,
            pageAspectRatio: self.pageAspectRatio
        )
    }

    /// A size change re-lays out without animation and drops any turn.
    public var body: some View {
        GeometryReader { proxy in
            let arrangement = self.arrangement(for: proxy.size)
            self.layers(size: proxy.size, arrangement: arrangement)
                .contentShape(Rectangle())
                .gesture(
                    self.dragGesture(width: arrangement.turnWidth(containerWidth: proxy.size.width), arrangement: arrangement),
                    including: self.pagingEnabled ? .all : .subviews
                )
                .gesture(self.tapGesture(width: proxy.size.width, arrangement: arrangement))
                .accessibilityElement(children: .contain)
                .accessibilityValue(Text("Page \(self.settledPage + 1) of \(self.pageCount)"))
                .accessibilityAdjustableAction { adjustment in
                    self.adjust(adjustment, in: arrangement)
                }
                .onChange(of: self.currentPage) { _, newValue in
                    self.selectionChanged(to: newValue, in: arrangement)
                }
                .onChange(of: proxy.size) { _, _ in
                    self.dropTurn()
                }
                .transaction(value: arrangement) { transaction in
                    transaction.animation = nil
                }
        }
    }

    private func adjust(_ adjustment: AccessibilityAdjustmentDirection, in arrangement: MekuriArrangement) {
        guard self.pagingEnabled else { return }
        switch adjustment {
        case .increment: self.perform(.forward, in: arrangement)
        case .decrement: self.perform(.backward, in: arrangement)
        @unknown default: break
        }
    }

    /// A selection inside the shown spread moves nothing on screen and is
    /// never written back. A curl driven by the selection lands on the
    /// selected page, not on the spread's own leading page.
    private func selectionChanged(to newValue: Int, in arrangement: MekuriArrangement) {
        guard newValue != self.settledPage else { return }
        if self.turn != nil {
            self.dropTurn()
            self.withoutAnimation {
                self.settledPage = newValue
            }
            return
        }
        switch arrangement.transition(from: self.settledPage, to: newValue) {
        case .none:
            self.withoutAnimation {
                self.settledPage = newValue
            }
        case .curl(let turn):
            var state = self.beginTurn(turn, in: arrangement)
            if self.reducesMotion || state.isBlocked {
                self.settledPage = newValue
            } else {
                state.targetIndex = newValue
                self.arm(state, decision: .commit)
            }
        case .crossfade:
            if self.reducesMotion {
                self.settledPage = newValue
            } else {
                withAnimation(self.configuration.settleAnimation) {
                    self.settledPage = newValue
                }
            }
        }
    }
}
