import SwiftUI
import Testing
@testable import Mekuri

@Suite struct MekuriEnvironmentTests {
    @Test func theEnvironmentCarriesTheDefaults() {
        let values = EnvironmentValues()
        #expect(values.mekuriDirection == .leftToRight)
        #expect(values.mekuriFoldRadius == 0.04)
        #expect(values.mekuriCornerLift == 0.10)
        #expect(values.mekuriTapZone == 0.25)
        #expect(values.mekuriSnapThreshold == 0.35)
        #expect(values.mekuriPageMode == .live)
        #expect(values.mekuriReducedMotion == nil)
    }
}
