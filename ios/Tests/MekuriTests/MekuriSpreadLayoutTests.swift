import CoreGraphics
import Testing
@testable import Mekuri

@Suite struct MekuriSpreadLayoutTests {
    private let coverAlone = MekuriSpreadLayout(pageCount: 6, coverStandsAlone: true)
    private let paired = MekuriSpreadLayout(pageCount: 6, coverStandsAlone: false)

    @Test func slotsPairFromTheCover() {
        #expect(self.coverAlone.pages(inSpread: 0) == (nil, 0))
        #expect(self.coverAlone.pages(inSpread: 1) == (1, 2))
        #expect(self.coverAlone.pages(inSpread: 3) == (5, nil))
        #expect(self.coverAlone.spreadCount == 4)
    }

    @Test func slotsPairFromTheFirstPage() {
        #expect(self.paired.pages(inSpread: 0) == (0, 1))
        #expect(self.paired.pages(inSpread: 2) == (4, 5))
        #expect(self.paired.spreadCount == 3)
    }

    @Test func aForwardTurnCarriesTheTrailingPageOver() {
        let leaf = self.coverAlone.leaf(turn: .forward, spreadIndex: 1)
        #expect(leaf?.front == 2)
        #expect(leaf?.back == 3)
        #expect(leaf?.revealed == 4)
        #expect(leaf?.landsIn == .leading)
        #expect(self.coverAlone.selection(afterTurn: .forward, spreadIndex: 1) == 3)
    }

    @Test func aForwardTurnFromTheCoverOpensTheBook() {
        let leaf = self.coverAlone.leaf(turn: .forward, spreadIndex: 0)
        #expect(leaf?.front == 0)
        #expect(leaf?.back == 1)
        #expect(leaf?.revealed == 2)
    }

    @Test func theLastLeafHasNothingBehindIt() {
        let leaf = self.coverAlone.leaf(turn: .forward, spreadIndex: 2)
        #expect(leaf?.front == 4)
        #expect(leaf?.back == 5)
        #expect(leaf?.revealed == nil)
        #expect(self.coverAlone.selection(afterTurn: .forward, spreadIndex: 2) == 5)
    }

    @Test func turnsRefuseAtBothEnds() {
        #expect(self.coverAlone.leaf(turn: .forward, spreadIndex: 3) == nil)
        #expect(self.coverAlone.leaf(turn: .backward, spreadIndex: 0) == nil)
    }

    @Test func aBackwardTurnCarriesTheLeadingPageBack() {
        let leaf = self.coverAlone.leaf(turn: .backward, spreadIndex: 2)
        #expect(leaf?.front == 3)
        #expect(leaf?.back == 2)
        #expect(leaf?.revealed == 1)
        #expect(leaf?.landsIn == .trailing)
        #expect(self.coverAlone.selection(afterTurn: .backward, spreadIndex: 2) == 1)
    }

    @Test func aBackwardTurnIntoTheCoverSelectsTheOnlyPageThere() {
        let leaf = self.coverAlone.leaf(turn: .backward, spreadIndex: 1)
        #expect(leaf?.back == 0)
        #expect(leaf?.revealed == nil)
        #expect(self.coverAlone.selection(afterTurn: .backward, spreadIndex: 1) == 0)
    }

    @Test func pairedTurnsMoveOneSpreadToo() {
        #expect(self.paired.leaf(turn: .forward, spreadIndex: 0)?.front == 1)
        #expect(self.paired.leaf(turn: .forward, spreadIndex: 0)?.back == 2)
        #expect(self.paired.selection(afterTurn: .forward, spreadIndex: 0) == 2)
        #expect(self.paired.leaf(turn: .backward, spreadIndex: 1)?.back == 1)
        #expect(self.paired.selection(afterTurn: .backward, spreadIndex: 1) == 0)
    }

    @Test func aPageIsFoundInItsSpread() {
        #expect(self.coverAlone.spreadIndex(containing: 0) == 0)
        #expect(self.coverAlone.spreadIndex(containing: 4) == 2)
        #expect(self.paired.spreadIndex(containing: 4) == 2)
    }

    @Test func twoPagesAppearOnlyWhenTheyFitAndStayReadable() {
        let aspect: CGFloat = 2.0 / 3.0
        #expect(MekuriSpread.automatic.isDouble(containerSize: CGSize(width: 1194, height: 834), pageAspectRatio: aspect))
        #expect(MekuriSpread.automatic.isDouble(containerSize: CGSize(width: 956, height: 440), pageAspectRatio: aspect))
        #expect(!MekuriSpread.automatic.isDouble(containerSize: CGSize(width: 852, height: 393), pageAspectRatio: aspect))
        #expect(!MekuriSpread.automatic.isDouble(containerSize: CGSize(width: 834, height: 1194), pageAspectRatio: aspect))
        #expect(MekuriSpread.automatic.isDouble(containerSize: CGSize(width: 700, height: 800), pageAspectRatio: aspect))
        #expect(!MekuriSpread.automatic.isDouble(containerSize: CGSize(width: 600, height: 800), pageAspectRatio: aspect))
        #expect(MekuriSpread.double.isDouble(containerSize: CGSize(width: 852, height: 393), pageAspectRatio: aspect))
        #expect(!MekuriSpread.single.isDouble(containerSize: CGSize(width: 1194, height: 834), pageAspectRatio: aspect))
    }
}
