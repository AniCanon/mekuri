import CoreGraphics

/// What one fold render needs for a direction and progress. The shader only
/// folds a flap entering from the right, so a right-to-left turn mirrors the
/// page around it; `shaderProgress` is never negative.
struct MekuriFoldPass: Equatable {
    let isMirrored: Bool
    let shaderProgress: CGFloat

    init(direction: MekuriDirection, progress: CGFloat) {
        self.isMirrored = direction == .rightToLeft
        self.shaderProgress = abs(direction.sweep(progress: progress))
    }

    /// Horizontal scale applied on both sides of the layer effect.
    var mirrorScale: CGFloat { self.isMirrored ? -1 : 1 }
}
