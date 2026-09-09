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

    /// Distance a drag travels to complete a turn: the width of what turns.
    func turnWidth(containerWidth: CGFloat) -> CGFloat {
        switch self {
        case .single: containerWidth
        case .spread(_, let pageSize): pageSize.width * 2
        }
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
}
