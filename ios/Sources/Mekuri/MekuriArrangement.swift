import CoreGraphics

/// What the container holds: one page across its whole width, or a spread
/// of two `pageSize` slots side by side, centred, with the spine between
/// them. Every turn and selection change is judged against it.
enum MekuriArrangement: Equatable {
    case single(pageCount: Int)
    case spread(MekuriSpreadLayout, pageSize: CGSize)

    static func resolve(
        containerSize: CGSize,
        pageCount: Int,
        spread: MekuriSpread,
        coverStandsAlone: Bool,
        pageAspectRatio: CGFloat
    ) -> MekuriArrangement {
        guard spread.isDouble(containerSize: containerSize, pageAspectRatio: pageAspectRatio) else {
            return .single(pageCount: pageCount)
        }
        return .spread(
            MekuriSpreadLayout(pageCount: pageCount, coverStandsAlone: coverStandsAlone),
            pageSize: MekuriSpread.pageSize(fitting: containerSize, pageAspectRatio: pageAspectRatio)
        )
    }

    /// Distance the free edge travels across a whole turn, so the edge stays
    /// under the finger. A single page's edge crosses the container and as far
    /// again past the spine, beyond any drag; a spread's crosses both slots.
    func turnWidth(containerWidth: CGFloat) -> CGFloat {
        switch self {
        case .single: containerWidth * 2
        case .spread(_, let pageSize): pageSize.width * 2
        }
    }

    /// Share of a turn a drag across the whole page or spread reaches.
    var dragReach: CGFloat {
        switch self {
        case .single: 0.5
        case .spread: 1
        }
    }

    /// Progress as a release is judged: the share of the travel a drag can
    /// reach, so the snap threshold means the same distance in either mode.
    func releaseProgress(_ progress: CGFloat) -> CGFloat {
        progress / self.dragReach
    }

    func turnState(id: Int, turn: MekuriTurn, from page: Int) -> MekuriTurnState {
        switch self {
        case .single(let pageCount):
            MekuriTurnState.begin(id: id, turn: turn, from: page, pageCount: pageCount)
        case .spread(let layout, _):
            MekuriTurnState.begin(id: id, turn: turn, from: page, layout: layout)
        }
    }

    func transition(from: Int, to: Int) -> MekuriTransition {
        switch self {
        case .single:
            MekuriTransition.between(from: from, to: to)
        case .spread(let layout, _):
            MekuriTransition.between(from: from, to: to, layout: layout)
        }
    }

    /// Live pages at rest with `page` selected. Single mode fills the
    /// trailing slot only.
    func slots(showing page: Int) -> (leading: Int?, trailing: Int?) {
        switch self {
        case .single(let pageCount):
            (nil, (0..<pageCount).contains(page) ? page : nil)
        case .spread(let layout, _):
            layout.pages(inSpread: layout.spreadIndex(containing: page))
        }
    }

    /// Shift of the spread stack at rest with `page` selected, or across
    /// `turn`. Always zero in single mode.
    func shiftSpan(showing page: Int, turn: MekuriTurnState?, direction: MekuriDirection) -> MekuriSpreadShift.Span {
        switch self {
        case .single:
            return MekuriSpreadShift.Span.zero
        case .spread(let layout, let pageSize):
            if let turn {
                return MekuriSpreadShift.span(of: turn, layout: layout, pageWidth: pageSize.width, direction: direction)
            }
            let rest = MekuriSpreadShift.atRest(inSpreadContaining: page, layout: layout, pageWidth: pageSize.width, direction: direction)
            return MekuriSpreadShift.Span(start: rest, end: rest)
        }
    }
}
