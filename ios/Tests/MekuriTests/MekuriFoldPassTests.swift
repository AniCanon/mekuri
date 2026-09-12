import Testing
import CoreGraphics
@testable import Mekuri

@Suite struct MekuriFoldPassTests {
    @Test(arguments: [CGFloat(0), 0.4, 1])
    func leftToRightIsNeverMirrored(progress: CGFloat) {
        let pass = MekuriFoldPass(direction: .leftToRight, progress: progress)
        #expect(pass.isMirrored == false)
        #expect(pass.mirrorScale == 1)
        #expect(pass.shaderProgress == progress)
    }

    @Test(arguments: [CGFloat(0), 0.4, 1])
    func rightToLeftIsMirroredWithNonNegativeProgress(progress: CGFloat) {
        let pass = MekuriFoldPass(direction: .rightToLeft, progress: progress)
        #expect(pass.isMirrored == true)
        #expect(pass.mirrorScale == -1)
        #expect(pass.shaderProgress == progress)
        #expect(pass.shaderProgress >= 0)
    }

    @Test func aBottomLiftFlipsTheLayerVerticallyInEitherDirection() {
        for direction in [MekuriDirection.leftToRight, .rightToLeft] {
            let pass = MekuriFoldPass(direction: direction, progress: 0.4, liftsFromBottom: true)
            #expect(pass.verticalScale == -1)
            #expect(pass.mirrorScale == (direction == .rightToLeft ? -1 : 1))
            #expect(pass.shaderProgress == 0.4)
        }
        #expect(MekuriFoldPass(direction: .leftToRight, progress: 0.4).verticalScale == 1)
    }

    @Test func shaderProgressFollowsTheSweepMagnitude() {
        for direction in [MekuriDirection.leftToRight, .rightToLeft] {
            let pass = MekuriFoldPass(direction: direction, progress: 0.4)
            #expect(pass.shaderProgress == abs(direction.sweep(progress: 0.4)))
        }
    }
}
