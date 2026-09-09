import CoreGraphics

/// Horizontal region of the page a touch lands in. Each edge zone spans
/// `tapZoneRatio` of the width; points on a boundary fall in the centre.
public enum MekuriZone: Equatable, Sendable {
    case leading
    case center
    case trailing

    public static func resolve(x: CGFloat, width: CGFloat, configuration: MekuriConfiguration) -> MekuriZone {
        let edge = width * configuration.tapZoneRatio
        if x < edge { return .leading }
        if x > width - edge { return .trailing }
        return .center
    }
}

/// A page turn in reading order. Forward is always index plus one; direction
/// only decides which screen edge advances the story.
public enum MekuriTurn: Equatable, Sendable {
    case forward
    case backward

    /// The centre zone never turns a page.
    public static func from(zone: MekuriZone, direction: MekuriDirection) -> MekuriTurn? {
        switch (zone, direction) {
        case (.center, _): nil
        case (.trailing, .leftToRight), (.leading, .rightToLeft): .forward
        case (.leading, .leftToRight), (.trailing, .rightToLeft): .backward
        }
    }

    /// Nil when the turn would leave `0..<pageCount`.
    public func targetIndex(from index: Int, pageCount: Int) -> Int? {
        let target = switch self {
        case .forward: index + 1
        case .backward: index - 1
        }
        return (0..<pageCount).contains(target) ? target : nil
    }
}

/// Outcome of releasing a drag.
public enum MekuriTurnDecision: Equatable, Sendable {
    case commit
    case revert

    /// `velocity` is measured along the turn, in points per second; a fling
    /// against the turn never commits.
    public static func resolve(progress: CGFloat, velocity: CGFloat, configuration: MekuriConfiguration) -> MekuriTurnDecision {
        progress >= configuration.snapThreshold || velocity >= configuration.flingVelocity ? .commit : .revert
    }
}
