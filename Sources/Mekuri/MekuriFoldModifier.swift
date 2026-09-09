import SwiftUI

/// Last progress SwiftUI presented for the turn in flight. Written from the
/// animation, read when a drag takes over a settle.
final class MekuriPresentedProgress: @unchecked Sendable {
    var value: CGFloat = 0
}

/// Folds the turning page by an animatable progress. Reversal for backward
/// turns happens here so `progress` always means turn progress.
nonisolated struct MekuriFoldModifier: ViewModifier, Animatable {
    var progress: CGFloat
    let isReversed: Bool
    let direction: MekuriDirection
    let configuration: MekuriConfiguration
    let presented: MekuriPresentedProgress

    var animatableData: CGFloat {
        get { self.progress }
        set {
            self.progress = newValue
            self.presented.value = newValue
        }
    }

    @MainActor func body(content: Content) -> some View {
        MekuriFoldedPage(
            progress: self.isReversed ? 1 - self.progress : self.progress,
            direction: self.direction,
            configuration: self.configuration
        ) {
            content
        }
    }
}
