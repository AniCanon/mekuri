import CoreGraphics
import Foundation

/// Pure fold arithmetic in page space. Progress runs 0 (flat) to 1 (turned);
/// the fold axis travels from the trailing edge to the leading edge. Fold
/// distance is measured from the held end, `y == pageHeight`, toward the free
/// corner at `y == 0`. These formulas are mirrored in `mekuriFold`.
struct MekuriFoldGeometry: Equatable, Sendable {
    let pageWidth: CGFloat
    let configuration: MekuriConfiguration

    init(pageWidth: CGFloat, configuration: MekuriConfiguration) {
        self.pageWidth = pageWidth
        self.configuration = configuration
    }

    /// Horizontal position of the fold axis at the page's vertical centre
    /// with no bow. Out-of-range progress clamps to 0...1.
    func foldAxisOffset(progress: CGFloat) -> CGFloat {
        self.pageWidth * (1 - self.clamped(progress))
    }

    /// Horizontal position of the crease at `y`, including shear and bow.
    func foldAxisOffset(progress: CGFloat, y: CGFloat, pageHeight: CGFloat) -> CGFloat {
        let held = 1 - y / pageHeight
        let shear = self.configuration.cornerShear * (y - pageHeight / 2)
        return self.foldAxisOffset(progress: progress) + shear - self.bowLead(progress: progress) * held * held
    }

    /// Distance the free corner runs ahead of the straight crease.
    func bowLead(progress: CGFloat) -> CGFloat {
        let progress = self.clamped(progress)
        return self.configuration.creaseBow * self.pageWidth * progress * (1 - progress)
    }

    /// Cylinder radius at `distance` points along the fold from the held end.
    func radius(atFoldDistance distance: CGFloat) -> CGFloat {
        self.heldRadius + self.radiusSlope * distance
    }

    /// Cylinder radius at the held end.
    var heldRadius: CGFloat {
        self.pageWidth * self.configuration.cylinderRadiusRatio
    }

    /// Radius growth per point of fold distance.
    var radiusSlope: CGFloat {
        self.configuration.cylinderRadiusRatio * self.configuration.radiusOpening
    }

    func isFlat(progress: CGFloat) -> Bool {
        progress <= 0
    }

    /// Share of the turn over which the roll flattens.
    static let landingFraction: CGFloat = 0.3

    /// Smallest radius scale; the contact shadow divides by the radius.
    static let landingFloor: CGFloat = 0.01

    /// Scale on the cylinder radius and corner shear: 1
    /// until the landing begins, `landingFloor` at progress 1.
    func landingRadiusScale(progress: CGFloat) -> CGFloat {
        let remaining = 1 - self.clamped(progress)
        return max(min(remaining / Self.landingFraction, 1), Self.landingFloor)
    }

    /// Full-height band centred on the fold axis.
    func creaseShadowRect(progress: CGFloat, pageSize: CGSize) -> CGRect {
        let width = self.pageWidth * self.configuration.creaseShadowWidthRatio
        let axis = self.foldAxisOffset(progress: progress)
        return CGRect(x: axis - width / 2, y: 0, width: width, height: pageSize.height)
    }

    /// Horizontal position of the sheet's free edge at row `y` of the
    /// shader's frame, as the shader draws it: on the roll while the flap is
    /// shorter than half a turn, lying flat past the crest beyond. Radius and
    /// shear land with the turn.
    func freeEdge(progress: CGFloat, y: CGFloat, pageHeight: CGFloat) -> CGFloat {
        let landing = self.landingRadiusScale(progress: progress)
        let held = 1 - y / pageHeight
        let shear = self.configuration.cornerShear * landing * (y - pageHeight / 2)
        let axis = self.foldAxisOffset(progress: progress) + shear - self.bowLead(progress: progress) * held * held
        let flap = self.pageWidth - axis
        let radius = self.radius(atFoldDistance: pageHeight - y) * landing
        let halfTurn = CGFloat.pi * radius
        return flap <= halfTurn ? axis + radius * sin(flap / radius) : axis - (flap - halfTurn)
    }

    private func clamped(_ progress: CGFloat) -> CGFloat {
        min(max(progress, 0), 1)
    }
}
