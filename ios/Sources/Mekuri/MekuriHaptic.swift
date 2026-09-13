import SwiftUI

/// A tactile cue in a turn: the page lifting, a drag crossing the progress at
/// which its release completes the turn, and the page landing.
enum MekuriHaptic: Equatable, Sendable {
    case lift
    case detent
    case land

    /// Whether a drag from `old` to `new` crosses `threshold` in either
    /// direction, with the inclusive comparison a release resolves by.
    static func crossesThreshold(from old: CGFloat, to new: CGFloat, threshold: CGFloat) -> Bool {
        (old >= threshold) != (new >= threshold)
    }

    var feedback: SensoryFeedback {
        switch self {
        case .lift: .impact(flexibility: .soft, intensity: 0.5)
        case .detent: .selection
        case .land: .impact(flexibility: .soft, intensity: 0.9)
        }
    }
}

/// One played cue; the id makes a repeat of the same cue a new trigger.
struct MekuriHapticEvent: Equatable {
    let id: Int
    let haptic: MekuriHaptic
}
