import SwiftUI

/// Fold and gesture tuning shared by every page turn. Assembled by
/// ``MekuriPager`` from the environment; members without a modifier keep
/// their defaults.
struct MekuriConfiguration: Equatable, Sendable {
    /// Cylinder radius at the held end of the fold as a ratio of the page
    /// width.
    var cylinderRadiusRatio: CGFloat

    /// Growth of the cylinder radius per page width of fold distance from the
    /// held end, as a multiple of `cylinderRadiusRatio`. 0 keeps the radius
    /// constant along the fold.
    var radiusOpening: CGFloat

    /// How far the free corner runs ahead of a straight crease, 0...1. 0 is a
    /// straight crease.
    var creaseBow: CGFloat

    /// Horizontal travel of the fold line per unit of vertical distance from
    /// the page centre. A ratio, not an angle.
    var cornerShear: CGFloat

    /// Darkest brightness of the lit back face, 0...1, reached where the
    /// surface has turned fully away from the light.
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
        radiusOpening: CGFloat = 1.0,
        creaseBow: CGFloat = 0.35,
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
        self.radiusOpening = radiusOpening
        self.creaseBow = creaseBow
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

    /// A vertical straight crease with a constant radius.
    static let straightCrease = MekuriConfiguration(radiusOpening: 0, creaseBow: 0, cornerShear: 0)
}
