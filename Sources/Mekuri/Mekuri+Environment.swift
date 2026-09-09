import SwiftUI

public extension EnvironmentValues {
    /// How the enclosing page is being drawn. Set by ``MekuriPager`` for
    /// each page's subtree; `.live` outside a pager.
    @Entry var mekuriPageMode: MekuriPageMode = .live
}

extension EnvironmentValues {
    @Entry var mekuriDirection: MekuriDirection = .leftToRight
    @Entry var mekuriPagingEnabled: Bool = true
    @Entry var mekuriOnCenterTap: (() -> Void)? = nil
    @Entry var mekuriFoldRadius: CGFloat = MekuriConfiguration.default.cylinderRadiusRatio
    @Entry var mekuriCornerLift: CGFloat = MekuriConfiguration.default.cornerShear
    @Entry var mekuriTapZone: CGFloat = MekuriConfiguration.default.tapZoneRatio
    @Entry var mekuriSnapThreshold: CGFloat = MekuriConfiguration.default.snapThreshold
    @Entry var mekuriSettleAnimation: Animation = MekuriConfiguration.default.settleAnimation
    @Entry var mekuriReducedMotion: Bool? = MekuriConfiguration.default.reducedMotionOverride
}
