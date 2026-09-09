import CoreGraphics
import Testing
@testable import Mekuri

@Suite struct MekuriSpreadShiftTests {
    private let coverAlone = MekuriSpreadLayout(pageCount: 6, coverStandsAlone: true)
    private let width: CGFloat = 556

    @Test func aLoneCoverSitsCentredAtRestInBothDirections() {
        #expect(MekuriSpreadShift.atRest(leading: nil, trailing: 0, pageWidth: self.width, direction: .leftToRight) == -278)
        #expect(MekuriSpreadShift.atRest(leading: nil, trailing: 0, pageWidth: self.width, direction: .rightToLeft) == 278)
        #expect(MekuriSpreadShift.atRest(inSpreadContaining: 0, layout: self.coverAlone, pageWidth: self.width, direction: .leftToRight) == -278)
    }

    @Test func aLoneFinalPageSitsCentredAtRest() {
        #expect(MekuriSpreadShift.atRest(leading: 5, trailing: nil, pageWidth: self.width, direction: .leftToRight) == 278)
        #expect(MekuriSpreadShift.atRest(leading: 5, trailing: nil, pageWidth: self.width, direction: .rightToLeft) == -278)
        #expect(MekuriSpreadShift.atRest(inSpreadContaining: 5, layout: self.coverAlone, pageWidth: self.width, direction: .leftToRight) == 278)

        let paired = MekuriSpreadLayout(pageCount: 5, coverStandsAlone: false)
        #expect(MekuriSpreadShift.atRest(inSpreadContaining: 4, layout: paired, pageWidth: self.width, direction: .leftToRight) == 278)
        #expect(MekuriSpreadShift.atRest(inSpreadContaining: 3, layout: paired, pageWidth: self.width, direction: .leftToRight) == 0)
    }

    @Test func aFullSpreadAndSingleModeAreNeverShifted() {
        #expect(MekuriSpreadShift.atRest(leading: 1, trailing: 2, pageWidth: self.width, direction: .leftToRight) == 0)
        #expect(MekuriSpreadShift.atRest(leading: nil, trailing: nil, pageWidth: self.width, direction: .leftToRight) == 0)
        let single = MekuriArrangement.single(pageCount: 6)
        let turn = MekuriTurnState.begin(id: 1, turn: .forward, from: 0, pageCount: 6)
        #expect(single.shiftSpan(showing: 0, turn: nil, direction: .leftToRight).value(at: 0) == 0)
        #expect(single.shiftSpan(showing: 0, turn: turn, direction: .leftToRight).value(at: turn.progress) == 0)
    }

    @Test func openingTheCoverSlidesTheStackToItsSlotsWithTheTurn() {
        var turn = MekuriTurnState.begin(id: 1, turn: .forward, from: 0, layout: self.coverAlone)
        #expect(MekuriSpreadShift.span(of: turn, layout: self.coverAlone, pageWidth: self.width, direction: .leftToRight).value(at: turn.progress) == -278)
        turn.progress = 0.5
        #expect(MekuriSpreadShift.span(of: turn, layout: self.coverAlone, pageWidth: self.width, direction: .leftToRight).value(at: turn.progress) == -139)
        turn.progress = 1
        #expect(MekuriSpreadShift.span(of: turn, layout: self.coverAlone, pageWidth: self.width, direction: .leftToRight).value(at: turn.progress) == 0)
        turn.progress = 1.02
        #expect(MekuriSpreadShift.span(of: turn, layout: self.coverAlone, pageWidth: self.width, direction: .leftToRight).value(at: turn.progress) == 0)
    }

    @Test func closingTheCoverSlidesTheStackBackToCentre() {
        var turn = MekuriTurnState.begin(id: 1, turn: .backward, from: 2, layout: self.coverAlone)
        #expect(MekuriSpreadShift.span(of: turn, layout: self.coverAlone, pageWidth: self.width, direction: .leftToRight).value(at: turn.progress) == 0)
        turn.progress = 0.5
        #expect(MekuriSpreadShift.span(of: turn, layout: self.coverAlone, pageWidth: self.width, direction: .leftToRight).value(at: turn.progress) == -139)
        turn.progress = 1
        #expect(MekuriSpreadShift.span(of: turn, layout: self.coverAlone, pageWidth: self.width, direction: .leftToRight).value(at: turn.progress) == -278)
    }

    @Test func theLoneFinalPageCentresAsItLandsAndLeavesCentre() {
        var forward = MekuriTurnState.begin(id: 1, turn: .forward, from: 4, layout: self.coverAlone)
        forward.progress = 0.25
        #expect(MekuriSpreadShift.span(of: forward, layout: self.coverAlone, pageWidth: self.width, direction: .leftToRight).value(at: forward.progress) == 69.5)
        forward.progress = 1
        #expect(MekuriSpreadShift.span(of: forward, layout: self.coverAlone, pageWidth: self.width, direction: .leftToRight).value(at: forward.progress) == 278)

        var backward = MekuriTurnState.begin(id: 2, turn: .backward, from: 5, layout: self.coverAlone)
        #expect(MekuriSpreadShift.span(of: backward, layout: self.coverAlone, pageWidth: self.width, direction: .leftToRight).value(at: backward.progress) == 278)
        backward.progress = 1
        #expect(MekuriSpreadShift.span(of: backward, layout: self.coverAlone, pageWidth: self.width, direction: .leftToRight).value(at: backward.progress) == 0)
    }

    @Test func aBlockedTurnOnALonePageLiftsItInPlace() {
        let layout = MekuriSpreadLayout(pageCount: 1, coverStandsAlone: true)
        var turn = MekuriTurnState.begin(id: 1, turn: .forward, from: 0, layout: layout)
        #expect(turn.isBlocked && turn.hasLeaf)
        turn.progress = 0.3
        #expect(MekuriSpreadShift.span(of: turn, layout: layout, pageWidth: self.width, direction: .leftToRight).value(at: turn.progress) == -278)
    }

    @Test func theArrangementShiftsTheSpreadStackAtRestAndInFlight() {
        let arrangement = MekuriArrangement.spread(self.coverAlone, pageSize: CGSize(width: self.width, height: 834))
        #expect(arrangement.shiftSpan(showing: 0, turn: nil, direction: .leftToRight).value(at: 0) == -278)
        #expect(arrangement.shiftSpan(showing: 3, turn: nil, direction: .leftToRight).value(at: 0) == 0)
        #expect(arrangement.shiftSpan(showing: 5, turn: nil, direction: .rightToLeft).value(at: 0) == -278)
        var turn = MekuriTurnState.begin(id: 1, turn: .forward, from: 0, layout: self.coverAlone)
        turn.progress = 0.5
        #expect(arrangement.shiftSpan(showing: 0, turn: turn, direction: .leftToRight).value(at: turn.progress) == -139)
    }
}

extension MekuriSpreadShiftTests {
    @Test func aSpanRunsBetweenTheTwoSpreadsAndClamps() {
        let turn = MekuriTurnState.begin(id: 1, turn: .forward, from: 0, layout: self.coverAlone)
        let span = MekuriSpreadShift.span(of: turn, layout: self.coverAlone, pageWidth: self.width, direction: .leftToRight)
        #expect(span == MekuriSpreadShift.Span(start: -278, end: 0))
        #expect(span.value(at: -0.2) == -278)
        #expect(span.value(at: 0.25) == -208.5)
        #expect(span.value(at: 1.3) == 0)

        let arrangement = MekuriArrangement.spread(self.coverAlone, pageSize: CGSize(width: self.width, height: 834))
        #expect(arrangement.shiftSpan(showing: 0, turn: nil, direction: .leftToRight) == MekuriSpreadShift.Span(start: -278, end: -278))
        #expect(arrangement.shiftSpan(showing: 0, turn: turn, direction: .leftToRight) == span)
        #expect(MekuriArrangement.single(pageCount: 6).shiftSpan(showing: 0, turn: turn, direction: .leftToRight) == .zero)
    }
}
