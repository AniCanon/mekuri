import CoreGraphics

/// Spine placement and sweep direction. Page indices stay in reading order
/// regardless of direction.
public enum MekuriDirection: Equatable, Sendable {
    case leftToRight
    case rightToLeft

    /// Signed fold travel. Positive sweeps the flap from the right edge toward
    /// the left; negative mirrors it so the spine sits on the opposite edge.
    func sweep(progress: CGFloat) -> CGFloat {
        switch self {
        case .leftToRight: progress
        case .rightToLeft: -progress
        }
    }
}
