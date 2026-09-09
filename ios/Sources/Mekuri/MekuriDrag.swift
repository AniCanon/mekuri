import CoreGraphics

/// Pure arithmetic mapping a horizontal drag onto a turn. `axis` is the sign
/// of horizontal travel that advances a turn; velocities are projected onto
/// it before they reach `MekuriTurnDecision`.
enum MekuriDrag {
    /// Points a drag must travel before it reports.
    static let minimumDistance: CGFloat = 10

    /// Horizontal travel must exceed vertical travel times this before a drag
    /// locks a turn; a tie does not lock.
    static let horizontalDominance: CGFloat = 1

    /// Travel fraction kept when the turn is blocked at the first or last page.
    static let blockedDamping: CGFloat = 1 / 3

    static func isHorizontallyDominant(_ translation: CGSize) -> Bool {
        abs(translation.width) > abs(translation.height) * self.horizontalDominance
    }

    static func axis(turn: MekuriTurn, direction: MekuriDirection) -> CGFloat {
        switch (turn, direction) {
        case (.forward, .leftToRight), (.backward, .rightToLeft): -1
        case (.backward, .leftToRight), (.forward, .rightToLeft): 1
        }
    }

    /// Nil when there is no horizontal travel.
    static func turn(translation: CGFloat, direction: MekuriDirection) -> MekuriTurn? {
        if translation == 0 { return nil }
        let forwardAxis = self.axis(turn: .forward, direction: direction)
        return translation * forwardAxis > 0 ? .forward : .backward
    }

    /// Nil unless the drag is horizontally dominant.
    static func turn(translation: CGSize, direction: MekuriDirection) -> MekuriTurn? {
        guard self.isHorizontallyDominant(translation) else { return nil }
        return self.turn(translation: translation.width, direction: direction)
    }

    /// Progress after `translation` from a drag that took over at `start`.
    /// Clamped to 0...1; a blocked turn keeps `blockedDamping` of its travel.
    static func progress(
        start: CGFloat,
        translation: CGFloat,
        width: CGFloat,
        axis: CGFloat,
        isBlocked: Bool
    ) -> CGFloat {
        guard width > 0 else { return start }
        let damping = isBlocked ? self.blockedDamping : 1
        let raw = start + translation * axis / width * damping
        return min(max(raw, 0), 1)
    }

    /// Velocity measured along the turn, positive toward completion.
    static func projectedVelocity(_ velocity: CGFloat, axis: CGFloat) -> CGFloat {
        velocity * axis
    }
}
