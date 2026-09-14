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

    /// The finger's full range across a turn, against which a release is
    /// judged: the container for a single page, both slots for a spread.
    func turnWidth(containerWidth: CGFloat) -> CGFloat {
        switch self {
        case .single: containerWidth
        case .spread(_, let pageSize): pageSize.width * 2
        }
    }

    /// The drag mapping for a turn grabbed at `grabY` in the container. Pages
    /// are centred vertically; the grab clamps to the page. `stackTravel` is
    /// the spread stack's slide along the drag across the whole turn.
    func edgeTrack(
        turn: MekuriTurn,
        containerSize: CGSize,
        grabY: CGFloat,
        liftsFromBottom: Bool,
        configuration: MekuriConfiguration,
        stackTravel: CGFloat = 0
    ) -> MekuriEdgeTrack {
        let page = switch self {
        case .single: containerSize
        case .spread(_, let pageSize): pageSize
        }
        let y = min(max(grabY - (containerSize.height - page.height) / 2, 0), page.height)
        return MekuriEdgeTrack(
            turn: turn,
            geometry: MekuriFoldGeometry(pageWidth: page.width, configuration: configuration),
            pageHeight: page.height,
            row: liftsFromBottom ? page.height - y : y,
            reach: self.turnWidth(containerWidth: containerSize.width),
            stackTravel: stackTravel
        )
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
