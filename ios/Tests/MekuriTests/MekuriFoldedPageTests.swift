import Testing
import SwiftUI
@testable import Mekuri

@Suite struct MekuriFoldedPageTests {
    @MainActor @Test func atRestTheFoldIsNotApplied() {
        let page = MekuriFoldedPage(progress: 0, direction: .leftToRight, configuration: .default) {
            Color.red
        }
        #expect(page.isFolded == false)

        let turning = MekuriFoldedPage(progress: 0.4, direction: .leftToRight, configuration: .default) {
            Color.red
        }
        #expect(turning.isFolded == true)
    }
}

extension MekuriFoldedPageTests {
    @MainActor @Test func theViewFoldsThroughTheDirectionalPass() {
        let forward = MekuriFoldedPage(progress: 0.4, direction: .leftToRight, configuration: .default) {
            Color.red
        }
        #expect(forward.foldPass.isMirrored == false)
        #expect(forward.foldPass.shaderProgress == 0.4)

        let backward = MekuriFoldedPage(progress: 0.4, direction: .rightToLeft, configuration: .default) {
            Color.red
        }
        #expect(backward.foldPass.isMirrored == true)
        #expect(backward.foldPass.shaderProgress == 0.4)
    }
}

extension MekuriFoldedPageTests {
    @MainActor @Test func aLeafWithABackFaceDrawsTwoPasses() {
        let mirrored = MekuriFoldedLeaf(progress: 0.4, direction: .leftToRight, configuration: .default) {
            Color.red
        } back: {
            Color.blue
        }
        #expect(mirrored.hasDistinctBackFace)

        let showThrough = MekuriFoldedLeaf(progress: 0.4, direction: .leftToRight, configuration: .default) {
            Color.red
        }
        #expect(!showThrough.hasDistinctBackFace)
    }
}

extension MekuriFoldedPageTests {
    @MainActor @Test func theShadowLayerFoldsThroughTheDirectionalPass() {
        let atRest = MekuriLeafShadow(progress: 0, direction: .leftToRight, configuration: .default)
        #expect(atRest.isFolded == false)

        let backward = MekuriLeafShadow(progress: 0.4, direction: .rightToLeft, configuration: .default)
        #expect(backward.isFolded == true)
        #expect(backward.foldPass.isMirrored == true)
        #expect(backward.foldPass.shaderProgress == 0.4)
    }

    @Test func eachFaceHasItsOwnShaderArgument() {
        #expect(MekuriFace.whole.rawValue == 0)
        #expect(MekuriFace.front.rawValue == 1)
        #expect(MekuriFace.back.rawValue == 2)
        #expect(MekuriFace.shadow.rawValue == 3)
    }

    @Test func aLeafHingesAtTheCentreOfItsSpread() {
        #expect(MekuriFoldShader.hinge(in: CGSize(width: 800, height: 600)) == 400)
    }
}
