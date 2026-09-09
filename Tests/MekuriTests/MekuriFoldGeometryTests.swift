import Testing
import SwiftUI
@testable import Mekuri

@Suite struct MekuriFoldGeometryTests {
    private let geometry = MekuriFoldGeometry(pageWidth: 400, configuration: .default)

    @Test func axisStartsAtTrailingEdgeAndEndsAtLeading() {
        #expect(self.geometry.foldAxisOffset(progress: 0) == 400)
        #expect(self.geometry.foldAxisOffset(progress: 1) == 0)
    }

    @Test func axisIsMonotonic() {
        let samples = stride(from: 0.0, through: 1.0, by: 0.1)
            .map { self.geometry.foldAxisOffset(progress: $0) }
        #expect(zip(samples, samples.dropFirst()).allSatisfy { $0 >= $1 })
    }

    @Test func pageIsFlatOnlyAtRest() {
        #expect(self.geometry.isFlat(progress: 0))
        #expect(!self.geometry.isFlat(progress: 0.001))
    }

    @Test func creaseShadowTracksTheAxis() {
        let size = CGSize(width: 400, height: 800)
        let shadow = self.geometry.creaseShadowRect(progress: 0.5, pageSize: size)
        #expect(shadow.midX == self.geometry.foldAxisOffset(progress: 0.5))
        #expect(shadow.width == 400 * MekuriConfiguration.default.creaseShadowWidthRatio)
        #expect(shadow.height == 800)
    }
}

extension MekuriFoldGeometryTests {
    @Test func aStraightCreaseIsTheOldBehaviour() {
        let straight = MekuriFoldGeometry(pageWidth: 400, configuration: .straightCrease)
        #expect(straight.foldAxisOffset(progress: 0.5, y: 0, pageHeight: 800) == straight.foldAxisOffset(progress: 0.5, y: 800, pageHeight: 800))
    }

    @Test func aBowedCreaseLeadsWithTheFreeCorner() {
        let bowed = MekuriFoldGeometry(pageWidth: 400, configuration: .default)
        let atCorner = bowed.foldAxisOffset(progress: 0.5, y: 0, pageHeight: 800)
        let atMiddle = bowed.foldAxisOffset(progress: 0.5, y: 400, pageHeight: 800)
        #expect(atCorner < atMiddle)
    }

    @Test func theRadiusOpensTowardTheFreeCorner() {
        let geometry = MekuriFoldGeometry(pageWidth: 400, configuration: .default)
        #expect(geometry.radius(atFoldDistance: 0) < geometry.radius(atFoldDistance: 800))
    }
}

extension MekuriFoldGeometryTests {
    /// With only the bow removed, the sheared crease is the straight formula
    /// `W(1 - p) + shear(y - H/2)` at every row and every progress.
    @Test func aZeroBowKeepsTheStraightShearedAxis() {
        let unbowed = MekuriFoldGeometry(pageWidth: 400, configuration: MekuriConfiguration(creaseBow: 0))
        for progress: CGFloat in [0.1, 0.25, 0.5, 0.75, 0.9] {
            for y: CGFloat in [0, 200, 400, 600, 800] {
                let straight = 400 * (1 - progress) + 0.10 * (y - 400)
                #expect(unbowed.foldAxisOffset(progress: progress, y: y, pageHeight: 800) == straight)
            }
        }
    }

    @Test func aZeroRadiusOpeningKeepsTheRadiusConstantAlongTheFold() {
        let flat = MekuriFoldGeometry(pageWidth: 400, configuration: MekuriConfiguration(radiusOpening: 0))
        #expect(flat.heldRadius == 16)
        for distance: CGFloat in [0, 200, 400, 800] {
            #expect(flat.radius(atFoldDistance: distance) == flat.heldRadius)
        }
    }
}

extension MekuriFoldGeometryTests {
    /// A hinged leaf keeps its radius until the landing, then flattens to
    /// the floor at progress 1 without ever reaching zero.
    @Test func aHingedLeafFlattensAsItLands() {
        let geometry = MekuriFoldGeometry(pageWidth: 400, configuration: .default)
        let landingStart = 1 - MekuriFoldGeometry.landingFraction
        #expect(geometry.landingRadiusScale(progress: 0) == 1)
        #expect(geometry.landingRadiusScale(progress: 0.5) == 1)
        #expect(geometry.landingRadiusScale(progress: landingStart) == 1)
        #expect(geometry.landingRadiusScale(progress: 1) == MekuriFoldGeometry.landingFloor)
        #expect(geometry.landingRadiusScale(progress: 2) == MekuriFoldGeometry.landingFloor)

        let samples = stride(from: 0.0, through: 1.0, by: 0.02)
            .map { geometry.landingRadiusScale(progress: $0) }
        #expect(zip(samples, samples.dropFirst()).allSatisfy { $0 >= $1 })
        #expect(samples.allSatisfy { $0 > 0 })
    }
}

extension MekuriFoldGeometryTests {
    /// A leaf hinged at the centre of a two-page layer sweeps at half the
    /// shader's rate and its bow is gone when it lands.
    @Test func aHingedSweepStopsAtTheSpine() {
        let start = MekuriHingedSweep(progress: 0, creaseBow: 0.35, spine: 400, layerWidth: 800)
        #expect(start.shaderProgress == 0)
        #expect(start.creaseBow == 0.35)

        let end = MekuriHingedSweep(progress: 1, creaseBow: 0.35, spine: 400, layerWidth: 800)
        #expect(end.shaderProgress == 0.5)
        #expect(end.creaseBow == 0)

        let past = MekuriHingedSweep(progress: 1.5, creaseBow: 0.35, spine: 400, layerWidth: 800)
        #expect(past == end)
    }

    /// The remapped sweep over the whole layer draws the crease exactly where
    /// the page's own geometry puts it, shifted by the spine, at every row.
    @Test func aHingedSweepMatchesThePageGeometryPastTheSpine() {
        let page = MekuriFoldGeometry(pageWidth: 400, configuration: .default)
        for progress: CGFloat in [0.1, 0.25, 0.5, 0.75, 0.9, 1] {
            let sweep = MekuriHingedSweep(progress: progress, creaseBow: 0.35, spine: 400, layerWidth: 800)
            let layer = MekuriFoldGeometry(pageWidth: 800, configuration: MekuriConfiguration(creaseBow: sweep.creaseBow))
            for y: CGFloat in [0, 200, 400, 600, 800] {
                let expected = 400 + page.foldAxisOffset(progress: progress, y: y, pageHeight: 800)
                let actual = layer.foldAxisOffset(progress: sweep.shaderProgress, y: y, pageHeight: 800)
                #expect(abs(actual - expected) < 1e-9)
            }
        }
    }
}
