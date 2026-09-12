import CoreGraphics

/// What one fold render needs for a direction, progress and lifting corner.
/// The shader only folds a flap entering from the right with its free corner
/// at the top, so a right-to-left turn mirrors the page horizontally around
/// it and a bottom lift mirrors it vertically; `shaderProgress` is never
/// negative.
struct MekuriFoldPass: Equatable {
    let isMirrored: Bool
    let liftsFromBottom: Bool
    let shaderProgress: CGFloat

    init(direction: MekuriDirection, progress: CGFloat, liftsFromBottom: Bool = false) {
        self.isMirrored = direction == .rightToLeft
        self.liftsFromBottom = liftsFromBottom
        self.shaderProgress = abs(direction.sweep(progress: progress))
    }

    /// Horizontal scale applied on both sides of the layer effect.
    var mirrorScale: CGFloat { self.isMirrored ? -1 : 1 }

    /// Vertical scale applied on both sides of the layer effect.
    var verticalScale: CGFloat { self.liftsFromBottom ? -1 : 1 }
}
