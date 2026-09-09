import CoreGraphics

/// Last progress SwiftUI presented for the turn in flight. Written from the
/// animation, read when a drag takes over a settle.
final class MekuriPresentedProgress: @unchecked Sendable {
    var value: CGFloat = 0
}
