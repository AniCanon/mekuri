import SwiftUI

/// Shifts the spread stack by the span's value at the animated progress.
/// The offset must be computed from the interpolated progress: an animated
/// offset above a layer effect leaves the effect at the model placement.
nonisolated struct MekuriSpreadShiftModifier: ViewModifier, Animatable {
    var progress: CGFloat
    let span: MekuriSpreadShift.Span

    var animatableData: CGFloat {
        get { self.progress }
        set { self.progress = newValue }
    }

    @MainActor func body(content: Content) -> some View {
        content.offset(x: self.span.value(at: self.progress))
    }
}
