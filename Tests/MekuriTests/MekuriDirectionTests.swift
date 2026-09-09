import Testing
@testable import Mekuri

@Suite struct MekuriDirectionTests {
    @Test func sweepMirrorsProgressForRightToLeft() {
        #expect(MekuriDirection.leftToRight.sweep(progress: 0.4) == 0.4)
        #expect(MekuriDirection.rightToLeft.sweep(progress: 0.4) == -0.4)
    }

    @Test func sweepIsFlatAtRestInBothDirections() {
        #expect(MekuriDirection.leftToRight.sweep(progress: 0) == 0)
        #expect(MekuriDirection.rightToLeft.sweep(progress: 0) == 0)
    }
}
