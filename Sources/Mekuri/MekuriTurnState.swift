import CoreGraphics

/// One turn in flight. `progress` runs 0 (nothing turned) to 1 (turned) in
/// the turn's own direction; the fold renderer reads `foldProgress`.
struct MekuriTurnState: Equatable {
    enum Phase: Equatable {
        case dragging
        case armed(MekuriTurnDecision)
        case settling(MekuriTurnDecision)
    }

    let id: Int
    let turn: MekuriTurn
    let fromIndex: Int
    /// Nil when the turn is blocked at the first or last page.
    let targetIndex: Int?
    var progress: CGFloat = 0
    /// Progress the current drag started from; non-zero after a takeover.
    var startProgress: CGFloat = 0
    var phase: Phase = .dragging

    var isBlocked: Bool { self.targetIndex == nil }

    var isSettling: Bool {
        switch self.phase {
        case .dragging: false
        case .armed, .settling: true
        }
    }

    /// Page drawn live underneath; nil when a blocked forward turn reveals
    /// nothing.
    var baseIndex: Int? {
        switch self.turn {
        case .forward: self.targetIndex
        case .backward: self.fromIndex
        }
    }

    /// Page drawn folded above the base. A backward turn has no page to curl
    /// when it is blocked.
    var turningIndex: Int? {
        switch self.turn {
        case .forward: self.fromIndex
        case .backward: self.targetIndex
        }
    }

    /// Progress handed to the fold renderer. A backward turn starts fully
    /// folded and unfolds into place.
    var foldProgress: CGFloat {
        switch self.turn {
        case .forward: self.progress
        case .backward: 1 - self.progress
        }
    }

    static func begin(id: Int, turn: MekuriTurn, from index: Int, pageCount: Int) -> MekuriTurnState {
        MekuriTurnState(
            id: id,
            turn: turn,
            fromIndex: index,
            targetIndex: turn.targetIndex(from: index, pageCount: pageCount)
        )
    }
}
