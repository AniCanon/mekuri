import CoreGraphics

/// Horizontal region of the page a touch lands in. Each edge zone spans
/// `tapZoneRatio` of the width; points on a boundary fall in the centre.
enum MekuriZone: Equatable, Sendable {
    case leading
    case center
    case trailing

    static func resolve(x: CGFloat, width: CGFloat, configuration: MekuriConfiguration) -> MekuriZone {
        let edge = width * configuration.tapZoneRatio
        if x < edge { return .leading }
        if x > width - edge { return .trailing }
        return .center
    }
}
