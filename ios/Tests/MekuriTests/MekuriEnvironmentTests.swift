import SwiftUI
import Testing
@testable import Mekuri

@Suite struct MekuriEnvironmentTests {
    @Test func theEnvironmentCarriesTheDefaults() {
        let values = EnvironmentValues()
        #expect(values.mekuriDirection == .leftToRight)
        #expect(values.mekuriFoldRadius == 0.25)
        #expect(values.mekuriCornerLift == 0.10)
        #expect(values.mekuriCreaseBow == 0.35)
        #expect(values.mekuriTapZone == 0.25)
        #expect(values.mekuriSnapThreshold == 0.35)
        #expect(values.mekuriPageMode == .live)
        #expect(values.mekuriReducedMotion == nil)
        #expect(values.mekuriSettleAnimation == nil)
    }

    @Test func aNilSettleAnimationFallsBackToThePackageCurve() {
        var values = EnvironmentValues()
        values.mekuriSettleAnimation = .linear(duration: 4)
        #expect(values.mekuriSettleAnimation == .linear(duration: 4))
        values.mekuriSettleAnimation = nil
        #expect(values.mekuriSettleAnimation == nil)
        let resolved = values.mekuriSettleAnimation ?? MekuriConfiguration.default.settleAnimation
        #expect(resolved == .timingCurve(0.35, 0.1, 0.75, 0.85, duration: 0.42))
    }
}

extension MekuriEnvironmentTests {
    @Test func theSpreadSettingsCarryTheirDefaults() {
        let values = EnvironmentValues()
        let twoThirds: CGFloat = 2.0 / 3.0
        #expect(values.mekuriSpread == .automatic)
        #expect(values.mekuriCoverStandsAlone == true)
        #expect(values.mekuriPageAspectRatio == twoThirds)
    }
}
