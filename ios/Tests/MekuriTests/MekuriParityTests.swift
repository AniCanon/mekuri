import CoreGraphics
import Testing
@testable import Mekuri

/// Every expected value here is a literal shared with `MekuriParityTest.kt`.
/// A number produced by one platform is never taken from the other.
@Suite struct MekuriParityTests {
    /// Absolute tolerance at page scale. Single precision at a page width of
    /// 400 carries about 3e-5 per unit in the last place.
    private let tolerance: CGFloat = 1e-3

    private let pageWidth: CGFloat = 400
    private let pageHeight: CGFloat = 800

    private var geometry: MekuriFoldGeometry {
        MekuriFoldGeometry(pageWidth: self.pageWidth, configuration: .default)
    }

    private var straightBow: MekuriFoldGeometry {
        MekuriFoldGeometry(pageWidth: self.pageWidth, configuration: MekuriConfiguration(creaseBow: 0))
    }

    private var straightCrease: MekuriFoldGeometry {
        MekuriFoldGeometry(pageWidth: self.pageWidth, configuration: .straightCrease)
    }

    private let coverAlone = MekuriSpreadLayout(pageCount: 6, coverStandsAlone: true)
    private let paired = MekuriSpreadLayout(pageCount: 6, coverStandsAlone: false)

    private func close(_ value: CGFloat, _ expected: CGFloat) -> Bool {
        abs(value - expected) < self.tolerance
    }

    // MARK: - The fold axis

    @Test func theStraightAxisMatchesTheKotlinImplementation() {
        #expect(self.close(self.geometry.foldAxisOffset(progress: 0), 400))
        #expect(self.close(self.geometry.foldAxisOffset(progress: 0.25), 300))
        #expect(self.close(self.geometry.foldAxisOffset(progress: 0.5), 200))
        #expect(self.close(self.geometry.foldAxisOffset(progress: 0.75), 100))
        #expect(self.close(self.geometry.foldAxisOffset(progress: 1), 0))
        #expect(self.close(self.geometry.foldAxisOffset(progress: -0.5), 400))
        #expect(self.close(self.geometry.foldAxisOffset(progress: 1.5), 0))
    }

    @Test func theBowedCreaseMatchesTheKotlinImplementationAtEveryRow() {
        let axis = { (progress: CGFloat, y: CGFloat) in
            self.geometry.foldAxisOffset(progress: progress, y: y, pageHeight: self.pageHeight)
        }
        #expect(self.close(axis(0.25, 0), 233.75))
        #expect(self.close(axis(0.25, 400), 293.4375))
        #expect(self.close(axis(0.25, 600), 318.359375))
        #expect(self.close(axis(0.25, 800), 340))
        #expect(self.close(axis(0.5, 0), 125))
        #expect(self.close(axis(0.5, 400), 191.25))
        #expect(self.close(axis(0.5, 600), 217.8125))
        #expect(self.close(axis(0.5, 800), 240))
        #expect(self.close(axis(0.75, 0), 33.75))
        #expect(self.close(axis(0.75, 400), 93.4375))
    }

    @Test func aZeroBowLeavesShearAloneOnBothPlatforms() {
        let axis = { (y: CGFloat) in
            self.straightBow.foldAxisOffset(progress: 0.25, y: y, pageHeight: self.pageHeight)
        }
        #expect(self.close(axis(0), 260))
        #expect(self.close(axis(400), 300))
        #expect(self.close(axis(800), 340))

        let straight = { (y: CGFloat) in
            self.straightCrease.foldAxisOffset(progress: 0.25, y: y, pageHeight: self.pageHeight)
        }
        #expect(self.close(straight(0), 300))
        #expect(self.close(straight(600), 300))
        #expect(self.close(straight(800), 300))
    }

    @Test func theBowLeadMatchesTheKotlinImplementation() {
        #expect(self.close(self.geometry.bowLead(progress: 0), 0))
        #expect(self.close(self.geometry.bowLead(progress: 0.25), 26.25))
        #expect(self.close(self.geometry.bowLead(progress: 0.5), 35))
        #expect(self.close(self.geometry.bowLead(progress: 0.75), 26.25))
        #expect(self.close(self.geometry.bowLead(progress: 1), 0))
        #expect(self.close(self.straightBow.bowLead(progress: 0.5), 0))
    }

    // MARK: - The radius profile

    @Test func theRadiusProfileMatchesTheKotlinImplementationAtBothEnds() {
        #expect(self.close(self.geometry.heldRadius, 16))
        #expect(self.close(self.geometry.radiusSlope, 0.04))
        #expect(self.close(self.geometry.radius(atFoldDistance: 0), 16))
        #expect(self.close(self.geometry.radius(atFoldDistance: 400), 32))
        #expect(self.close(self.geometry.radius(atFoldDistance: 800), 48))
        #expect(self.close(self.straightCrease.radiusSlope, 0))
        #expect(self.close(self.straightCrease.radius(atFoldDistance: 800), 16))
    }

    @Test func theLandingScaleMatchesTheKotlinImplementation() {
        #expect(self.close(self.geometry.landingRadiusScale(progress: 0), 1))
        #expect(self.close(self.geometry.landingRadiusScale(progress: 0.88), 1))
        #expect(self.close(self.geometry.landingRadiusScale(progress: 0.94), 0.5))
        #expect(self.close(self.geometry.landingRadiusScale(progress: 1), 0.01))
    }

    @Test func theCreaseShadowBandMatchesTheKotlinImplementation() {
        let rect = self.geometry.creaseShadowRect(
            progress: 0.25,
            pageSize: CGSize(width: self.pageWidth, height: self.pageHeight)
        )
        #expect(self.close(rect.minX, 280))
        #expect(self.close(rect.maxX, 320))
        #expect(self.close(rect.minY, 0))
        #expect(self.close(rect.maxY, 800))
    }

    // MARK: - The spread rule

    @Test func theSpreadFloorMatchesTheKotlinImplementation() {
        #expect(self.close(MekuriSpread.minimumDoublePageWidth, 275))
        #expect(MekuriSpread.automatic.isDouble(containerSize: CGSize(width: 1200, height: 550), pageAspectRatio: 0.5))
        #expect(MekuriSpread.automatic.isDouble(containerSize: CGSize(width: 1200, height: 552), pageAspectRatio: 0.5))
        #expect(!MekuriSpread.automatic.isDouble(containerSize: CGSize(width: 1200, height: 548), pageAspectRatio: 0.5))
        #expect(!MekuriSpread.automatic.isDouble(containerSize: CGSize(width: 2000, height: 500), pageAspectRatio: 0.5))
        #expect(MekuriSpread.automatic.isDouble(containerSize: CGSize(width: 956, height: 440), pageAspectRatio: 0.7))
        #expect(!MekuriSpread.automatic.isDouble(containerSize: CGSize(width: 440, height: 956), pageAspectRatio: 0.7))
    }

    @Test func theSpreadPageSizeMatchesTheKotlinImplementation() {
        let heightLimited = MekuriSpread.pageSize(fitting: CGSize(width: 1200, height: 600), pageAspectRatio: 2.0 / 3.0)
        #expect(self.close(heightLimited.width, 400))
        #expect(self.close(heightLimited.height, 600))

        let widthLimited = MekuriSpread.pageSize(fitting: CGSize(width: 900, height: 800), pageAspectRatio: 2.0 / 3.0)
        #expect(self.close(widthLimited.width, 450))
        #expect(self.close(widthLimited.height, 675))
    }

    // MARK: - The six-page matrix

    @Test func sixPagesPairTheSameWayOnBothPlatforms() {
        #expect(self.coverAlone.spreadCount == 4)
        #expect(self.coverAlone.pages(inSpread: 0) == (nil, 0))
        #expect(self.coverAlone.pages(inSpread: 1) == (1, 2))
        #expect(self.coverAlone.pages(inSpread: 2) == (3, 4))
        #expect(self.coverAlone.pages(inSpread: 3) == (5, nil))
        #expect(self.coverAlone.spreadIndex(containing: 0) == 0)
        #expect(self.coverAlone.spreadIndex(containing: 4) == 2)

        #expect(self.paired.spreadCount == 3)
        #expect(self.paired.pages(inSpread: 0) == (0, 1))
        #expect(self.paired.pages(inSpread: 1) == (2, 3))
        #expect(self.paired.pages(inSpread: 2) == (4, 5))
        #expect(self.paired.spreadIndex(containing: 4) == 2)
    }

    @Test func theLeafTableMatchesTheKotlinImplementationWithACoverAlone() {
        #expect(self.coverAlone.leaf(turn: .forward, spreadIndex: 0)
            == MekuriLeaf(front: 0, back: 1, revealed: 2, landsIn: .leading))
        #expect(self.coverAlone.leaf(turn: .forward, spreadIndex: 1)
            == MekuriLeaf(front: 2, back: 3, revealed: 4, landsIn: .leading))
        #expect(self.coverAlone.leaf(turn: .forward, spreadIndex: 2)
            == MekuriLeaf(front: 4, back: 5, revealed: nil, landsIn: .leading))
        #expect(self.coverAlone.leaf(turn: .forward, spreadIndex: 3) == nil)
        #expect(self.coverAlone.leaf(turn: .backward, spreadIndex: 0) == nil)
        #expect(self.coverAlone.leaf(turn: .backward, spreadIndex: 1)
            == MekuriLeaf(front: 1, back: 0, revealed: nil, landsIn: .trailing))
        #expect(self.coverAlone.leaf(turn: .backward, spreadIndex: 2)
            == MekuriLeaf(front: 3, back: 2, revealed: 1, landsIn: .trailing))
    }

    @Test func theLeafTableMatchesTheKotlinImplementationWhenPagesPairFromZero() {
        #expect(self.paired.leaf(turn: .forward, spreadIndex: 0)
            == MekuriLeaf(front: 1, back: 2, revealed: 3, landsIn: .leading))
        #expect(self.paired.leaf(turn: .forward, spreadIndex: 2) == nil)
        #expect(self.paired.leaf(turn: .backward, spreadIndex: 1)
            == MekuriLeaf(front: 2, back: 1, revealed: 0, landsIn: .trailing))
        #expect(self.paired.leaf(turn: .backward, spreadIndex: 0) == nil)
    }

    // MARK: - The turn and the selection

    @Test func theTurnArithmeticMatchesTheKotlinImplementation() {
        #expect(MekuriTurn.forward.targetIndex(from: 0, pageCount: 6) == 1)
        #expect(MekuriTurn.forward.targetIndex(from: 5, pageCount: 6) == nil)
        #expect(MekuriTurn.backward.targetIndex(from: 5, pageCount: 6) == 4)
        #expect(MekuriTurn.backward.targetIndex(from: 0, pageCount: 6) == nil)
        #expect(MekuriTurn.from(zone: .trailing, direction: .leftToRight) == .forward)
        #expect(MekuriTurn.from(zone: .leading, direction: .leftToRight) == .backward)
        #expect(MekuriTurn.from(zone: .trailing, direction: .rightToLeft) == .backward)
        #expect(MekuriTurn.from(zone: .leading, direction: .rightToLeft) == .forward)
        #expect(MekuriTurn.from(zone: .center, direction: .leftToRight) == nil)
    }

    @Test func theSelectionRulesMatchTheKotlinImplementation() {
        #expect(self.coverAlone.selection(afterTurn: .forward, spreadIndex: 0) == 1)
        #expect(self.coverAlone.selection(afterTurn: .forward, spreadIndex: 1) == 3)
        #expect(self.coverAlone.selection(afterTurn: .forward, spreadIndex: 2) == 5)
        #expect(self.coverAlone.selection(afterTurn: .forward, spreadIndex: 3) == nil)
        #expect(self.coverAlone.selection(afterTurn: .backward, spreadIndex: 1) == 0)
        #expect(self.coverAlone.selection(afterTurn: .backward, spreadIndex: 2) == 1)
        #expect(self.coverAlone.selection(afterTurn: .backward, spreadIndex: 0) == nil)
        #expect(self.paired.selection(afterTurn: .forward, spreadIndex: 0) == 2)
        #expect(self.paired.selection(afterTurn: .backward, spreadIndex: 1) == 0)
    }

    @Test func aSelectionChangeChoosesTheSameTransitionOnBothPlatforms() {
        #expect(MekuriTransition.between(from: 2, to: 2) == MekuriTransition.none)
        #expect(MekuriTransition.between(from: 2, to: 3) == .curl(.forward))
        #expect(MekuriTransition.between(from: 2, to: 1) == .curl(.backward))
        #expect(MekuriTransition.between(from: 2, to: 5) == .crossfade)
        #expect(MekuriTransition.between(from: 1, to: 2, layout: self.coverAlone) == MekuriTransition.none)
        #expect(MekuriTransition.between(from: 0, to: 1, layout: self.coverAlone) == .curl(.forward))
        #expect(MekuriTransition.between(from: 4, to: 0, layout: self.coverAlone) == .crossfade)
        #expect(MekuriTransition.between(from: 0, to: 1, layout: self.paired) == MekuriTransition.none)
        #expect(MekuriTransition.between(from: 1, to: 2, layout: self.paired) == .curl(.forward))
    }

    @Test func aLeafBeginsWithTheSameFacesOnBothPlatforms() {
        let single = MekuriTurnState.begin(id: 0, turn: .forward, from: 2, pageCount: 6)
        #expect(single.targetIndex == 3)
        #expect(single.leading == nil)
        #expect(single.trailing == 3)
        #expect(single.leafFront == 2)
        #expect(single.leafBack == nil)

        let blocked = MekuriTurnState.begin(id: 0, turn: .forward, from: 5, pageCount: 6)
        #expect(blocked.targetIndex == nil)
        #expect(blocked.trailing == nil)
        #expect(blocked.leafFront == 5)

        let opening = MekuriTurnState.begin(id: 0, turn: .forward, from: 0, layout: self.coverAlone)
        #expect(opening.targetIndex == 1)
        #expect(opening.leading == nil)
        #expect(opening.trailing == 2)
        #expect(opening.leafFront == 0)
        #expect(opening.leafBack == 1)

        let back = MekuriTurnState.begin(id: 0, turn: .backward, from: 3, layout: self.coverAlone)
        #expect(back.targetIndex == 1)
        #expect(back.leading == 1)
        #expect(back.trailing == 4)
        #expect(back.leafFront == 2)
        #expect(back.leafBack == 3)

        let end = MekuriTurnState.begin(id: 0, turn: .forward, from: 5, layout: self.coverAlone)
        #expect(end.targetIndex == nil)
        #expect(end.leading == 5)
        #expect(end.trailing == nil)
        #expect(!end.hasLeaf)
    }

    @Test func theFoldProgressOfABackwardTurnMatchesTheKotlinImplementation() {
        var forward = MekuriTurnState.begin(id: 0, turn: .forward, from: 2, pageCount: 6)
        forward.progress = 0.25
        #expect(self.close(forward.foldProgress, 0.25))

        var backward = MekuriTurnState.begin(id: 0, turn: .backward, from: 2, pageCount: 6)
        backward.progress = 0.25
        #expect(self.close(backward.foldProgress, 0.75))
    }

    // MARK: - The shift, the sweep and the pass

    @Test func theSpreadShiftMatchesTheKotlinImplementation() {
        #expect(self.close(
            MekuriSpreadShift.atRest(leading: nil, trailing: 0, pageWidth: 400, direction: .leftToRight),
            -200
        ))
        #expect(self.close(
            MekuriSpreadShift.atRest(leading: nil, trailing: 0, pageWidth: 400, direction: .rightToLeft),
            200
        ))
        #expect(self.close(
            MekuriSpreadShift.atRest(leading: 5, trailing: nil, pageWidth: 400, direction: .leftToRight),
            200
        ))
        #expect(self.close(
            MekuriSpreadShift.atRest(leading: 1, trailing: 2, pageWidth: 400, direction: .leftToRight),
            0
        ))

        var turn = MekuriTurnState.begin(id: 0, turn: .forward, from: 0, layout: self.coverAlone)
        turn.progress = 0.5
        let span = MekuriSpreadShift.span(of: turn, layout: self.coverAlone, pageWidth: 400, direction: .leftToRight)
        #expect(self.close(span.start, -200))
        #expect(self.close(span.end, 0))
        #expect(self.close(span.value(at: 0.5), -100))
        #expect(self.close(span.value(at: 1.5), 0))
    }

    @Test func theHingedSweepMatchesTheKotlinImplementation() {
        let half = MekuriHingedSweep(progress: 0.5, creaseBow: 0.35, spine: 400, layerWidth: 800)
        #expect(self.close(half.shaderProgress, 0.25))
        #expect(self.close(half.creaseBow, 0.2333333))

        let rest = MekuriHingedSweep(progress: 0, creaseBow: 0.35, spine: 400, layerWidth: 800)
        #expect(self.close(rest.shaderProgress, 0))
        #expect(self.close(rest.creaseBow, 0.35))

        let landed = MekuriHingedSweep(progress: 1, creaseBow: 0.35, spine: 400, layerWidth: 800)
        #expect(self.close(landed.shaderProgress, 0.5))
        #expect(self.close(landed.creaseBow, 0))
    }

    @Test func theFoldPassMatchesTheKotlinImplementation() {
        let forward = MekuriFoldPass(direction: .leftToRight, progress: 0.4)
        #expect(!forward.isMirrored)
        #expect(self.close(forward.shaderProgress, 0.4))
        #expect(self.close(forward.mirrorScale, 1))

        let mirrored = MekuriFoldPass(direction: .rightToLeft, progress: 0.4)
        #expect(mirrored.isMirrored)
        #expect(self.close(mirrored.shaderProgress, 0.4))
        #expect(self.close(mirrored.mirrorScale, -1))
    }

    // MARK: - The drag and the release

    @Test func theDragArithmeticMatchesTheKotlinImplementation() {
        #expect(self.close(MekuriDrag.axis(turn: .forward, direction: .leftToRight), -1))
        #expect(self.close(MekuriDrag.axis(turn: .backward, direction: .leftToRight), 1))
        #expect(self.close(MekuriDrag.axis(turn: .forward, direction: .rightToLeft), 1))
        #expect(self.close(
            MekuriDrag.progress(start: 0.2, translation: -80, width: 400, axis: -1, isBlocked: false),
            0.4
        ))
        #expect(self.close(
            MekuriDrag.progress(start: 0.2, translation: -80, width: 400, axis: -1, isBlocked: true),
            0.2666667
        ))
        #expect(self.close(
            MekuriDrag.progress(start: 0.9, translation: -80, width: 400, axis: -1, isBlocked: false),
            1
        ))
        #expect(self.close(
            MekuriDrag.progress(start: 0.1, translation: 80, width: 400, axis: -1, isBlocked: false),
            0
        ))
        #expect(self.close(MekuriDrag.projectedVelocity(-900, axis: -1), 900))
    }

    @Test func theReleaseDecisionMatchesTheKotlinImplementation() {
        let configuration = MekuriConfiguration.default
        #expect(MekuriTurnDecision.resolve(progress: 0.35, velocity: 0, configuration: configuration) == .commit)
        #expect(MekuriTurnDecision.resolve(progress: 0.34, velocity: 0, configuration: configuration) == .revert)
        #expect(MekuriTurnDecision.resolve(progress: 0.1, velocity: 600, configuration: configuration) == .commit)
        #expect(MekuriTurnDecision.resolve(progress: 0.1, velocity: -900, configuration: configuration) == .revert)
    }

    @Test func theTapZonesMatchTheKotlinImplementation() {
        let configuration = MekuriConfiguration.default
        #expect(MekuriZone.resolve(x: 0, width: 400, configuration: configuration) == .leading)
        #expect(MekuriZone.resolve(x: 99, width: 400, configuration: configuration) == .leading)
        #expect(MekuriZone.resolve(x: 100, width: 400, configuration: configuration) == .center)
        #expect(MekuriZone.resolve(x: 300, width: 400, configuration: configuration) == .center)
        #expect(MekuriZone.resolve(x: 301, width: 400, configuration: configuration) == .trailing)
    }
}
