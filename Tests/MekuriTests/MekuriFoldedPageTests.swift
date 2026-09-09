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
