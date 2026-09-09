import SwiftUI
import Testing
@testable import Mekuri

@Suite struct MekuriEnvironmentTests {
    @Test func theEnvironmentCarriesTheDefaults() {
        let values = EnvironmentValues()
        #expect(values.mekuriDirection == .leftToRight)
        #expect(values.mekuriFoldRadius == 0.04)
        #expect(values.mekuriCornerLift == 0.10)
        #expect(values.mekuriCreaseBow == 0.35)
        #expect(values.mekuriTapZone == 0.25)
        #expect(values.mekuriSnapThreshold == 0.35)
        #expect(values.mekuriPageMode == .live)
        #expect(values.mekuriReducedMotion == nil)
        #expect(values.mekuriSettleAnimation == nil)
    }

    @Test func aNilSettleAnimationFallsBackToThePackageSpring() {
        var values = EnvironmentValues()
        values.mekuriSettleAnimation = .linear(duration: 4)
        #expect(values.mekuriSettleAnimation == .linear(duration: 4))
        values.mekuriSettleAnimation = nil
        #expect(values.mekuriSettleAnimation == nil)
        let resolved = values.mekuriSettleAnimation ?? MekuriConfiguration.default.settleAnimation
        #expect(resolved == .spring(response: 0.35, dampingFraction: 0.86))
    }
}
