import SwiftUI

/// Folds the turning page. Animates and mirrors turn progress; the fold is
/// drawn from `turn.foldProgress`.
nonisolated struct MekuriFoldModifier: ViewModifier, Animatable {
    var turn: MekuriTurnState
    let direction: MekuriDirection
    let configuration: MekuriConfiguration
    let presented: MekuriPresentedProgress

    var animatableData: CGFloat {
        get { self.turn.progress }
        set {
            self.turn.progress = newValue
            self.presented.value = newValue
        }
    }

    @MainActor func body(content: Content) -> some View {
        MekuriFoldedPage(
            progress: self.turn.foldProgress,
            direction: self.direction,
            configuration: self.configuration
        ) {
            content
        }
    }
}
