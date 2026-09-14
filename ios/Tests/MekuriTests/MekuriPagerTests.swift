import CoreGraphics
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

    @Test func aFlickAgainstTheTurnProjectsNegativeAndRevertsRightToLeft() {
        let axis = MekuriDrag.axis(turn: .forward, direction: .rightToLeft)
        let projected = MekuriDrag.projectedVelocity(-900, axis: axis)
        #expect(axis == 1)
        #expect(projected == -900)
        #expect(MekuriTurnDecision.resolve(progress: 0.1, velocity: projected, configuration: .default) == .revert)
        #expect(MekuriDrag.projectedVelocity(900, axis: axis) == 900)
        #expect(MekuriTurnDecision.resolve(progress: 0.1, velocity: 900, configuration: .default) == .commit)
    }

    @Test func aDragLocksATurnOnlyWhenHorizontallyDominant() {
        #expect(MekuriDrag.turn(translation: CGSize(width: -40, height: 12), direction: .leftToRight) == .forward)
        #expect(MekuriDrag.turn(translation: CGSize(width: 40, height: 12), direction: .rightToLeft) == .forward)
        #expect(MekuriDrag.turn(translation: CGSize(width: -12, height: 40), direction: .leftToRight) == nil)
        #expect(MekuriDrag.turn(translation: CGSize(width: 12, height: -40), direction: .rightToLeft) == nil)
        #expect(MekuriDrag.turn(translation: CGSize(width: -30, height: 30), direction: .leftToRight) == nil)
        #expect(MekuriDrag.turn(translation: CGSize(width: 0, height: 0), direction: .leftToRight) == nil)
    }

    private static func edgeTrack() -> MekuriEdgeTrack {
        MekuriEdgeTrack(
            turn: .forward,
            geometry: MekuriFoldGeometry(pageWidth: 400, configuration: .default),
            pageHeight: 800,
            row: 400,
            reach: 400
        )
    }

    @Test func aBlockedDragKeepsAThirdOfItsTravel() {
        let track = Self.edgeTrack()
        let free = MekuriDrag.progress(start: 0, translation: -300, axis: -1, isBlocked: false, track: track)
        let blocked = MekuriDrag.progress(start: 0, translation: -300, axis: -1, isBlocked: true, track: track)
        #expect(abs(track.travel(progress: free) - 300) < 0.05)
        #expect(abs(track.travel(progress: blocked) - 100) < 0.05)
    }

    @Test func dragProgressClampsAndResumesFromATakeover() {
        let track = Self.edgeTrack()
        #expect(MekuriDrag.progress(start: 0, translation: -2000, axis: -1, isBlocked: false, track: track) == 1)
        #expect(MekuriDrag.progress(start: 0.6, translation: 2000, axis: -1, isBlocked: false, track: track) == 0)
        let resumed = MekuriDrag.progress(start: 0.5, translation: -100, axis: -1, isBlocked: false, track: track)
        #expect(abs(track.travel(progress: resumed) - track.travel(progress: 0.5) - 100) < 0.05)
    }

    @Test func aSlidingStackStillLandsTheEdgeUnderTheFinger() {
        let track = MekuriEdgeTrack(
            turn: .forward,
            geometry: MekuriFoldGeometry(pageWidth: 400, configuration: .default),
            pageHeight: 800,
            row: 400,
            reach: 800,
            stackTravel: -200
        )
        for distance: CGFloat in [10, 140, 500] {
            #expect(abs(track.travel(progress: track.progress(travel: distance)) - distance) < 0.05)
        }
    }

    @Test func theFreeEdgeStaysUnderTheFinger() {
        let track = Self.edgeTrack()
        for distance: CGFloat in [10, 60, 140, 300, 600] {
            #expect(abs(track.travel(progress: track.progress(travel: distance)) - distance) < 0.05)
        }
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

extension MekuriPagerTests {
    @Test func aCrossfadeIsJudgedInSpreadsWhileSpreadsAreOn() {
        let layout = MekuriSpreadLayout(pageCount: 6, coverStandsAlone: true)
        #expect(MekuriTransition.between(from: 2, to: 3, layout: layout) == .curl(.forward))
        #expect(MekuriTransition.between(from: 3, to: 4, layout: layout) == .none)
        #expect(MekuriTransition.between(from: 3, to: 2, layout: layout) == .curl(.backward))
        #expect(MekuriTransition.between(from: 2, to: 5, layout: layout) == .crossfade)
    }
}

extension MekuriPagerTests {
    private var coverAlone: MekuriSpreadLayout { MekuriSpreadLayout(pageCount: 6, coverStandsAlone: true) }

    @Test func aForwardSpreadTurnLiftsTheTrailingPageAndLandsTheNextOneLeading() {
        var state = MekuriTurnState.begin(id: 1, turn: .forward, from: 2, layout: self.coverAlone)
        state.progress = 0.4
        #expect(state.leading == 1)
        #expect(state.trailing == 4)
        #expect(state.leafFront == 2)
        #expect(state.leafBack == 3)
        #expect(state.targetIndex == 3)
        #expect(state.foldProgress == 0.4)
        #expect(state.hasLeaf)
    }

    @Test func aBackwardSpreadTurnUnfoldsThePreviousLeafOverTheCurrentSpread() {
        var state = MekuriTurnState.begin(id: 1, turn: .backward, from: 4, layout: self.coverAlone)
        state.progress = 0.4
        #expect(state.leading == 1)
        #expect(state.trailing == 4)
        #expect(state.leafFront == 2)
        #expect(state.leafBack == 3)
        #expect(state.targetIndex == 1)
        #expect(state.foldProgress == 0.6)
    }

    @Test func turningFromTheCoverOpensTheBookAndSelectsTheLeadingPage() {
        let state = MekuriTurnState.begin(id: 1, turn: .forward, from: 0, layout: self.coverAlone)
        #expect(state.leading == nil)
        #expect(state.trailing == 2)
        #expect(state.leafFront == 0)
        #expect(state.leafBack == 1)
        #expect(state.targetIndex == 1)

        let back = MekuriTurnState.begin(id: 2, turn: .backward, from: 2, layout: self.coverAlone)
        #expect(back.leading == nil)
        #expect(back.trailing == 2)
        #expect(back.leafFront == 0)
        #expect(back.leafBack == 1)
        #expect(back.targetIndex == 0)
    }

    @Test func blockedSpreadTurnsLiftTheDepartingPageOverNothing() {
        let last = MekuriTurnState.begin(id: 1, turn: .forward, from: 5, layout: self.coverAlone)
        #expect(last.isBlocked)
        #expect(last.leading == 5)
        #expect(!last.hasLeaf)

        let paired = MekuriSpreadLayout(pageCount: 6, coverStandsAlone: false)
        let lastPaired = MekuriTurnState.begin(id: 2, turn: .forward, from: 4, layout: paired)
        #expect(lastPaired.isBlocked)
        #expect(lastPaired.leading == 4)
        #expect(lastPaired.trailing == nil)
        #expect(lastPaired.leafFront == 5)
        #expect(lastPaired.leafBack == nil)

        let first = MekuriTurnState.begin(id: 3, turn: .backward, from: 0, layout: self.coverAlone)
        #expect(first.isBlocked)
        #expect(!first.hasLeaf)
    }

    @Test func anArrangementIsSingleUntilTwoPagesFit() {
        let aspect: CGFloat = 2.0 / 3.0
        let phone = MekuriArrangement.resolve(containerSize: CGSize(width: 402, height: 874), pageCount: 6, spread: .automatic, coverStandsAlone: true, pageAspectRatio: aspect)
        #expect(phone == .single(pageCount: 6))
        #expect(phone.turnWidth(containerWidth: 402) == 402)
        #expect(phone.slots(showing: 3) == (nil, 3))

        let pad = MekuriArrangement.resolve(containerSize: CGSize(width: 1194, height: 834), pageCount: 6, spread: .automatic, coverStandsAlone: true, pageAspectRatio: aspect)
        #expect(pad == .spread(MekuriSpreadLayout(pageCount: 6, coverStandsAlone: true), pageSize: CGSize(width: 556, height: 834)))
        #expect(pad.turnWidth(containerWidth: 1194) == 1112)
        #expect(pad.slots(showing: 4) == (3, 4))
        #expect(pad.transition(from: 3, to: 4) == .none)
    }

    @Test func aSpreadPageFitsTwoAcrossTheContainer() {
        let wide = MekuriSpread.pageSize(fitting: CGSize(width: 1194, height: 834), pageAspectRatio: 2.0 / 3.0)
        #expect(wide == CGSize(width: 556, height: 834))
        let narrow = MekuriSpread.pageSize(fitting: CGSize(width: 600, height: 834), pageAspectRatio: 2.0 / 3.0)
        #expect(narrow == CGSize(width: 300, height: 450))
    }
}

extension MekuriPagerTests {
    @Test func aDragTicksOnlyWhenItCrossesTheCommitPoint() {
        #expect(MekuriHaptic.crossesThreshold(from: 0.3, to: 0.35, threshold: 0.35))
        #expect(MekuriHaptic.crossesThreshold(from: 0.4, to: 0.34, threshold: 0.35))
        #expect(!MekuriHaptic.crossesThreshold(from: 0.1, to: 0.34, threshold: 0.35))
        #expect(!MekuriHaptic.crossesThreshold(from: 0.35, to: 0.9, threshold: 0.35))
    }
}
