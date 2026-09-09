import CoreGraphics

/// One turn in flight, as what is on screen: two live base slots and the
/// leaf turning over them. `progress` runs 0 (nothing turned) to 1 (turned)
/// in the turn's own direction; the fold renderer reads `foldProgress`.
/// Single-page mode has no leading slot and no `leafBack`; its leaf is the
/// trailing page across the whole container, with its own front mirrored on
/// the reverse.
struct MekuriTurnState: Equatable {
    enum Phase: Equatable {
        case dragging
        case armed(MekuriTurnDecision)
        case settling(MekuriTurnDecision)
    }

    let id: Int
    let turn: MekuriTurn
    /// Page selected when the turn began.
    let fromIndex: Int
    /// Page selected once the turn lands; nil when the turn is blocked at
    /// either end.
    var targetIndex: Int?
    /// Live page in the leading slot; nil when absent.
    let leading: Int?
    /// Live page in the trailing slot; nil when absent.
    let trailing: Int?
    /// Page on the face of the leaf that lies in the trailing slot at fold
    /// progress 0.
    let leafFront: Int?
    /// Page on the face that lands in the leading slot at fold progress 1.
    let leafBack: Int?
    var progress: CGFloat = 0
    /// Progress the current drag started from; non-zero after a takeover.
    var startProgress: CGFloat = 0
    var phase: Phase = .dragging

    var isBlocked: Bool { self.targetIndex == nil }

    /// A turn with no face to draw has nothing to lift.
    var hasLeaf: Bool { self.leafFront != nil || self.leafBack != nil }

    var isSettling: Bool {
        switch self.phase {
        case .dragging: false
        case .armed, .settling: true
        }
    }

    /// Single-page mode: the page drawn live underneath the leaf.
    var baseIndex: Int? { self.trailing }

    /// Single-page mode: the page drawn folded above the base.
    var turningIndex: Int? { self.leafFront }

    /// Progress handed to the fold renderer. A backward turn starts fully
    /// folded and unfolds into place.
    var foldProgress: CGFloat {
        switch self.turn {
        case .forward: self.progress
        case .backward: 1 - self.progress
        }
    }

    /// Single-page mode. A forward turn lifts the current page off the next;
    /// a backward turn unfolds the previous page over the current.
    static func begin(id: Int, turn: MekuriTurn, from index: Int, pageCount: Int) -> MekuriTurnState {
        let target = turn.targetIndex(from: index, pageCount: pageCount)
        let (trailing, leafFront) = switch turn {
        case .forward: (target, Optional(index))
        case .backward: (Optional(index), target)
        }
        return MekuriTurnState(
            id: id,
            turn: turn,
            fromIndex: index,
            targetIndex: target,
            leading: nil,
            trailing: trailing,
            leafFront: leafFront,
            leafBack: nil
        )
    }

    /// Spread mode. A backward turn is the previous spread's forward leaf
    /// unfolding: its front is the page that lands in the trailing slot and
    /// its back is the leading page being lifted. A blocked turn lifts the
    /// departing page over nothing.
    static func begin(id: Int, turn: MekuriTurn, from index: Int, layout: MekuriSpreadLayout) -> MekuriTurnState {
        let spreadIndex = layout.spreadIndex(containing: index)
        let current = layout.pages(inSpread: spreadIndex)
        let leaf = layout.leaf(turn: turn, spreadIndex: spreadIndex)
        let (leading, trailing, leafFront, leafBack): (Int?, Int?, Int?, Int?) = switch (turn, leaf) {
        case (.forward, let leaf?): (current.leading, leaf.revealed, leaf.front, leaf.back)
        case (.backward, let leaf?): (leaf.revealed, current.trailing, leaf.back, leaf.front)
        case (.forward, nil): (current.leading, nil, current.trailing, nil)
        case (.backward, nil): (nil, current.trailing, nil, current.leading)
        }
        return MekuriTurnState(
            id: id,
            turn: turn,
            fromIndex: index,
            targetIndex: layout.selection(afterTurn: turn, spreadIndex: spreadIndex),
            leading: leading,
            trailing: trailing,
            leafFront: leafFront,
            leafBack: leafBack
        )
    }
}
