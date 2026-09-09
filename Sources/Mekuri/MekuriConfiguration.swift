import SwiftUI

/// Fold and gesture tuning shared by every page turn. Assembled by
/// ``MekuriPager`` from the environment; members without a modifier keep
/// their defaults.
struct MekuriConfiguration: Equatable, Sendable {
    /// Cylinder radius of the fold as a ratio of the page width.
    var cylinderRadiusRatio: CGFloat

    /// Horizontal travel of the fold line per unit of vertical distance from
    /// the page centre. A ratio, not an angle.
    var cornerShear: CGFloat

    /// Brightness multiplier applied to the back face, 0...1.
    var backFaceDim: CGFloat

    /// Width of the crease shadow as a ratio of the page width.
    var creaseShadowWidthRatio: CGFloat

    /// Peak opacity of the crease shadow, 0...1.
    var creaseShadowOpacity: CGFloat

    /// Turn progress, 0...1, past which a released drag completes the turn.
    var snapThreshold: CGFloat

    /// Horizontal velocity in points per second at which a release completes
    /// the turn regardless of progress.
    var flingVelocity: CGFloat

    /// Width of each tap-to-turn edge zone as a ratio of the page width.
    var tapZoneRatio: CGFloat

    /// Animation used to settle a released turn.
    var settleAnimation: Animation

    /// Overrides the system reduce-motion setting when non-nil.
    var reducedMotionOverride: Bool?

    init(
        cylinderRadiusRatio: CGFloat = 0.04,
        cornerShear: CGFloat = 0.10,
        backFaceDim: CGFloat = 0.86,
        creaseShadowWidthRatio: CGFloat = 0.10,
        creaseShadowOpacity: CGFloat = 0.35,
        snapThreshold: CGFloat = 0.35,
        flingVelocity: CGFloat = 600,
        tapZoneRatio: CGFloat = 0.25,
        settleAnimation: Animation = .spring(response: 0.35, dampingFraction: 0.86),
        reducedMotionOverride: Bool? = nil
    ) {
        self.cylinderRadiusRatio = cylinderRadiusRatio
        self.cornerShear = cornerShear
        self.backFaceDim = backFaceDim
        self.creaseShadowWidthRatio = creaseShadowWidthRatio
        self.creaseShadowOpacity = creaseShadowOpacity
        self.snapThreshold = snapThreshold
        self.flingVelocity = flingVelocity
        self.tapZoneRatio = tapZoneRatio
        self.settleAnimation = settleAnimation
        self.reducedMotionOverride = reducedMotionOverride
    }

    static let `default` = MekuriConfiguration()
}
