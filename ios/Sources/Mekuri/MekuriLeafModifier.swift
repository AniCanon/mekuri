import SwiftUI

/// Turns a two-sided leaf across a spread: `content` is the front face and
/// `back` the reverse, both drawn `.turning`. The leaf's shadows are drawn
/// beneath it, over the revealed page. Frame the modified view to the full
/// two-slot width; the leaf hinges at its centre. `back` is a built view, not
/// a builder: the body runs every animation frame and must not rebuild it.
nonisolated struct MekuriLeafModifier<Back: View>: ViewModifier, Animatable {
    var turn: MekuriTurnState
    let direction: MekuriDirection
    let configuration: MekuriConfiguration
    let presented: MekuriPresentedProgress
    let back: Back

    var animatableData: CGFloat {
        get { self.turn.progress }
        set {
            self.turn.progress = newValue
            self.presented.value = newValue
        }
    }

    @MainActor func body(content: Content) -> some View {
        ZStack {
            MekuriLeafShadow(
                progress: self.turn.foldProgress,
                direction: self.direction,
                configuration: self.configuration
            )
            MekuriFoldedLeaf(
                progress: self.turn.foldProgress,
                direction: self.direction,
                configuration: self.configuration
            ) {
                content
            } back: {
                self.back
            }
        }
    }
}
