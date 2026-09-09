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
