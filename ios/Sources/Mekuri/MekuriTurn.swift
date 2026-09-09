import CoreGraphics

/// A page turn in reading order. Forward is always index plus one; direction
/// only decides which screen edge advances the story.
enum MekuriTurn: Equatable, Sendable {
    case forward
    case backward

    /// The centre zone never turns a page.
    static func from(zone: MekuriZone, direction: MekuriDirection) -> MekuriTurn? {
        switch (zone, direction) {
        case (.center, _): nil
        case (.trailing, .leftToRight), (.leading, .rightToLeft): .forward
        case (.leading, .leftToRight), (.trailing, .rightToLeft): .backward
        }
    }

    /// Nil when the turn would leave `0..<pageCount`.
    func targetIndex(from index: Int, pageCount: Int) -> Int? {
        let target = switch self {
        case .forward: index + 1
        case .backward: index - 1
        }
        return (0..<pageCount).contains(target) ? target : nil
    }
}
