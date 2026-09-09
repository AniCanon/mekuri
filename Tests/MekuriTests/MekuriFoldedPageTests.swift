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
