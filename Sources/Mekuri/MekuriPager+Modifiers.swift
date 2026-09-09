import SwiftUI

public extension View {
    /// Spine edge for ``MekuriPager`` views in this hierarchy. Page indices
    /// stay in reading order. Defaults to `.leftToRight`.
    func mekuriDirection(_ direction: MekuriDirection) -> some View {
        self.environment(\.mekuriDirection, direction)
    }

    /// With paging off, drags and edge taps are ignored; centre taps still
    /// report. Defaults to enabled.
    func mekuriPagingEnabled(_ enabled: Bool) -> some View {
        self.environment(\.mekuriPagingEnabled, enabled)
    }

    /// Called for a tap in the centre zone. Mekuri does nothing else with it.
    func mekuriOnCenterTap(_ action: @escaping () -> Void) -> some View {
        self.environment(\.mekuriOnCenterTap, action)
    }

    /// Cylinder radius of the fold as a ratio of the page width. Defaults to 0.04.
    func mekuriFoldRadius(_ ratio: CGFloat) -> some View {
        self.environment(\.mekuriFoldRadius, ratio)
    }

    /// Horizontal travel of the fold line per unit of vertical distance from
    /// the page centre. A ratio, not an angle. Defaults to 0.10.
    func mekuriCornerLift(_ ratio: CGFloat) -> some View {
        self.environment(\.mekuriCornerLift, ratio)
    }

    /// Width of each tap-to-turn edge zone as a ratio of the page width.
    /// Defaults to 0.25.
    func mekuriTapZone(_ ratio: CGFloat) -> some View {
        self.environment(\.mekuriTapZone, ratio)
    }

    /// Turn progress, 0...1, past which a released drag completes the turn.
    /// Defaults to 0.35.
    func mekuriSnapThreshold(_ progress: CGFloat) -> some View {
        self.environment(\.mekuriSnapThreshold, progress)
    }

    /// Animation used to settle a released turn. Defaults to nil, which uses
    /// the package spring with response 0.35 and damping fraction 0.86.
    func mekuriSettleAnimation(_ animation: Animation?) -> some View {
        self.environment(\.mekuriSettleAnimation, animation)
    }

    /// Overrides the system reduce-motion setting in either direction when
    /// non-nil. Defaults to nil, which follows the system.
    func mekuriReducedMotion(_ reduced: Bool?) -> some View {
        self.environment(\.mekuriReducedMotion, reduced)
    }
}
