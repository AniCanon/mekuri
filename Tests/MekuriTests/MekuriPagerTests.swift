import Testing
@testable import Mekuri

@Suite struct MekuriPagerTests {
    @Test func aJumpOfMoreThanOnePageCrossfadesInsteadOfCurling() {
        #expect(MekuriTransition.between(from: 3, to: 4) == .curl(.forward))
        #expect(MekuriTransition.between(from: 3, to: 2) == .curl(.backward))
        #expect(MekuriTransition.between(from: 3, to: 9) == .crossfade)
        #expect(MekuriTransition.between(from: 3, to: 3) == .none)
    }
}

extension MekuriPagerTests {
    @Test func aDragTowardTheSpineTurnsForwardInBothDirections() {
        #expect(MekuriDrag.turn(translation: -40, direction: .leftToRight) == .forward)
        #expect(MekuriDrag.turn(translation: 40, direction: .leftToRight) == .backward)
        #expect(MekuriDrag.turn(translation: 40, direction: .rightToLeft) == .forward)
        #expect(MekuriDrag.turn(translation: -40, direction: .rightToLeft) == .backward)
        #expect(MekuriDrag.turn(translation: 0, direction: .leftToRight) == nil)
    }

    @Test func aFlickAgainstTheTurnProjectsNegativeAndReverts() {
        let axis = MekuriDrag.axis(turn: .forward, direction: .leftToRight)
        let projected = MekuriDrag.projectedVelocity(900, axis: axis)
        #expect(projected == -900)
        #expect(MekuriTurnDecision.resolve(progress: 0.1, velocity: projected, configuration: .default) == .revert)
        #expect(MekuriDrag.projectedVelocity(-900, axis: axis) == 900)
    }

    @Test func aBlockedDragKeepsAThirdOfItsTravel() {
        let free = MekuriDrag.progress(start: 0, translation: -300, width: 400, axis: -1, isBlocked: false)
        let blocked = MekuriDrag.progress(start: 0, translation: -300, width: 400, axis: -1, isBlocked: true)
        #expect(free == 0.75)
        #expect(blocked == 0.25)
    }

    @Test func dragProgressClampsAndResumesFromATakeover() {
        #expect(MekuriDrag.progress(start: 0, translation: -800, width: 400, axis: -1, isBlocked: false) == 1)
        #expect(MekuriDrag.progress(start: 0.6, translation: 400, width: 400, axis: -1, isBlocked: false) == 0)
        #expect(MekuriDrag.progress(start: 0.5, translation: -100, width: 400, axis: -1, isBlocked: false) == 0.75)
        #expect(MekuriDrag.progress(start: 0.5, translation: -100, width: 0, axis: -1, isBlocked: false) == 0.5)
    }

    @Test func aForwardTurnCurlsTheCurrentPageOverTheNext() {
        var state = MekuriTurnState.begin(id: 1, turn: .forward, from: 3, pageCount: 6)
        state.progress = 0.4
        #expect(state.baseIndex == 4)
        #expect(state.turningIndex == 3)
        #expect(state.foldProgress == 0.4)
        #expect(state.isBlocked == false)
    }

    @Test func aBackwardTurnUnfoldsThePreviousPageOverTheCurrent() {
        var state = MekuriTurnState.begin(id: 1, turn: .backward, from: 3, pageCount: 6)
        state.progress = 0.4
        #expect(state.baseIndex == 3)
        #expect(state.turningIndex == 2)
        #expect(state.foldProgress == 0.6)
    }

    @Test func blockedTurnsHaveNothingToRevealOrToCurl() {
        let last = MekuriTurnState.begin(id: 1, turn: .forward, from: 5, pageCount: 6)
        #expect(last.isBlocked)
        #expect(last.baseIndex == nil)
        #expect(last.turningIndex == 5)

        let first = MekuriTurnState.begin(id: 2, turn: .backward, from: 0, pageCount: 6)
        #expect(first.isBlocked)
        #expect(first.baseIndex == 0)
        #expect(first.turningIndex == nil)
    }
}
