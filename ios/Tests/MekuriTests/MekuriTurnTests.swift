import Testing
@testable import Mekuri

@Suite struct MekuriTurnTests {
    private let config = MekuriConfiguration.default

    @Test func zonesSplitOnTheConfiguredRatio() {
        #expect(MekuriZone.resolve(x: 10, width: 400, configuration: self.config) == .leading)
        #expect(MekuriZone.resolve(x: 200, width: 400, configuration: self.config) == .center)
        #expect(MekuriZone.resolve(x: 390, width: 400, configuration: self.config) == .trailing)
    }

    @Test func trailingAdvancesLeftToRightAndRetreatsRightToLeft() {
        #expect(MekuriTurn.from(zone: .trailing, direction: .leftToRight) == .forward)
        #expect(MekuriTurn.from(zone: .trailing, direction: .rightToLeft) == .backward)
        #expect(MekuriTurn.from(zone: .leading, direction: .rightToLeft) == .forward)
        #expect(MekuriTurn.from(zone: .center, direction: .leftToRight) == nil)
    }

    @Test func releaseCommitsPastThresholdOrVelocity() {
        #expect(MekuriTurnDecision.resolve(progress: 0.5, velocity: 0, configuration: self.config) == .commit)
        #expect(MekuriTurnDecision.resolve(progress: 0.1, velocity: 0, configuration: self.config) == .revert)
        #expect(MekuriTurnDecision.resolve(progress: 0.1, velocity: 900, configuration: self.config) == .commit)
    }

    @Test func boundaryPointsFallInTheCentre() {
        #expect(MekuriZone.resolve(x: 100, width: 400, configuration: self.config) == .center)
        #expect(MekuriZone.resolve(x: 300, width: 400, configuration: self.config) == .center)
    }

    @Test func flingAgainstTheTurnNeverCommits() {
        #expect(MekuriTurnDecision.resolve(progress: 0.1, velocity: -900, configuration: self.config) == .revert)
    }

    @Test func turnsStopAtTheEnds() {
        #expect(MekuriTurn.forward.targetIndex(from: 0, pageCount: 3) == 1)
        #expect(MekuriTurn.forward.targetIndex(from: 2, pageCount: 3) == nil)
        #expect(MekuriTurn.backward.targetIndex(from: 0, pageCount: 3) == nil)
    }
}
