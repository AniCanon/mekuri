import CoreGraphics

/// The shader sweeps its axis across the whole layer. A leaf hinged `spine`
/// points from the leading edge sweeps only the page past the hinge, so its
/// progress is scaled by that share of the layer and its bow rescaled so the
/// crease is straight again at the end of the turn. Progress clamps to
/// 0...1; `spine` must be positive.
struct MekuriHingedSweep: Equatable {
    let shaderProgress: CGFloat
    let creaseBow: CGFloat

    init(progress: CGFloat, creaseBow: CGFloat, spine: CGFloat, layerWidth: CGFloat) {
        let progress = min(max(progress, 0), 1)
        let shaderProgress = progress * (layerWidth - spine) / layerWidth
        self.shaderProgress = shaderProgress
        self.creaseBow = creaseBow * (1 - progress) / (1 - shaderProgress)
    }
}
