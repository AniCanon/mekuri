import CoreGraphics

/// Outcome of releasing a drag.
enum MekuriTurnDecision: Equatable, Sendable {
    case commit
    case revert

    /// `velocity` is measured along the turn, in points per second; a fling
    /// against the turn never commits.
    static func resolve(progress: CGFloat, velocity: CGFloat, configuration: MekuriConfiguration) -> MekuriTurnDecision {
        progress >= configuration.snapThreshold || velocity >= configuration.flingVelocity ? .commit : .revert
    }
}
