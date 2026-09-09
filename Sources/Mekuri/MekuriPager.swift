import SwiftUI

/// A page-curl pager over arbitrary content. Page indices are in reading
/// order; the spine edge and every tuning value come from the environment.
/// Each page reads its `\.mekuriPageMode`: the page being turned is drawn
/// `.turning` and its `.live` view leaves the hierarchy until the turn
/// settles.
public struct MekuriPager<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var systemReducesMotion
    @Environment(\.mekuriDirection) var direction
    @Environment(\.mekuriPagingEnabled) var pagingEnabled
    @Environment(\.mekuriOnCenterTap) var onCenterTap
    @Environment(\.mekuriFoldRadius) private var foldRadius
    @Environment(\.mekuriCornerLift) private var cornerLift
    @Environment(\.mekuriTapZone) private var tapZone
    @Environment(\.mekuriSnapThreshold) private var snapThreshold
    @Environment(\.mekuriSettleAnimation) private var settleAnimation
    @Environment(\.mekuriReducedMotion) private var reducedMotionOverride

    let pageCount: Int
    @Binding var currentPage: Int
    let content: (Int) -> Content

    /// The page Mekuri is showing. Drives every layer; the binding follows it.
    @State var settledPage: Int
    @State var turn: MekuriTurnState?
    @State var presented = MekuriPresentedProgress()
    @State var nextTurnID = 0
    @State var settleCount = 0
    @State var ignoresCurrentDrag = false

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
            cornerShear: self.cornerLift,
            snapThreshold: self.snapThreshold,
            tapZoneRatio: self.tapZone,
            settleAnimation: self.settleAnimation,
            reducedMotionOverride: self.reducedMotionOverride
        )
    }

    var reducesMotion: Bool {
        self.reducedMotionOverride ?? self.systemReducesMotion
    }

    var baseIndex: Int? {
        let index = self.turn.map(\.baseIndex) ?? self.settledPage
        guard let index, (0..<self.pageCount).contains(index) else { return nil }
        return index
    }

    public var body: some View {
        GeometryReader { proxy in
            self.layers(size: proxy.size)
                .contentShape(Rectangle())
                .gesture(self.dragGesture(width: proxy.size.width), including: self.pagingEnabled ? .all : .subviews)
                .gesture(self.tapGesture(width: proxy.size.width))
        }
        .accessibilityElement(children: .contain)
        .accessibilityValue(Text("Page \(self.settledPage + 1) of \(self.pageCount)"))
        .accessibilityAdjustableAction { adjustment in
            self.adjust(adjustment)
        }
        .onChange(of: self.currentPage) { _, newValue in
            self.selectionChanged(to: newValue)
        }
    }

    @ViewBuilder
    private func layers(size: CGSize) -> some View {
        ZStack {
            if let baseIndex = self.baseIndex {
                self.content(baseIndex)
                    .environment(\.mekuriPageMode, .live)
                    .frame(width: size.width, height: size.height)
                    .id(baseIndex)
                    .transition(.opacity)
            }
            if let turn = self.turn, let turningIndex = turn.turningIndex {
                self.content(turningIndex)
                    .environment(\.mekuriPageMode, .turning)
                    .frame(width: size.width, height: size.height)
                    .modifier(self.foldModifier(for: turn))
                    .id(turn.id)
                    .onAppear { self.startArmedSettle(id: turn.id) }
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func foldModifier(for turn: MekuriTurnState) -> MekuriFoldModifier {
        MekuriFoldModifier(
            turn: turn,
            direction: self.direction,
            configuration: self.configuration,
            presented: self.presented
        )
    }

    private func adjust(_ adjustment: AccessibilityAdjustmentDirection) {
        guard self.pagingEnabled else { return }
        switch adjustment {
        case .increment: self.perform(.forward)
        case .decrement: self.perform(.backward)
        @unknown default: break
        }
    }

    private func selectionChanged(to newValue: Int) {
        guard newValue != self.settledPage else { return }
        if self.turn != nil {
            self.dropTurn()
            self.withoutAnimation {
                self.settledPage = newValue
            }
            return
        }
        switch MekuriTransition.between(from: self.settledPage, to: newValue) {
        case .none:
            break
        case .curl(let turn):
            if self.reducesMotion || turn.targetIndex(from: self.settledPage, pageCount: self.pageCount) == nil {
                self.settledPage = newValue
            } else {
                self.arm(turn, decision: .commit)
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
