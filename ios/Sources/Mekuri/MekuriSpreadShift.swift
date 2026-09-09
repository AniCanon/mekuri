import SwiftUI

/// Horizontal shift of the whole spread stack. A spread holding one page is
/// shifted so that page sits centred in the container; a full spread is not
/// shifted. During a turn the shift runs from the departing spread's to the
/// landing spread's with the turn's progress, so slots and leaf slide as one
/// piece and the lone page reaches its slot as the turn lands.
enum MekuriSpreadShift {
    /// Shift at rest and at the end of a turn; equal while nothing turns.
    struct Span: Equatable {
        let start: CGFloat
        let end: CGFloat

        static let zero = Span(start: 0, end: 0)

        /// Progress clamps to 0...1.
        func value(at progress: CGFloat) -> CGFloat {
            self.start + (self.end - self.start) * min(max(progress, 0), 1)
        }
    }

    static func atRest(
        leading: Int?,
        trailing: Int?,
        pageWidth: CGFloat,
        direction: MekuriDirection
    ) -> CGFloat {
        let reading: CGFloat = direction == .leftToRight ? 1 : -1
        switch (leading, trailing) {
        case (nil, .some): return -reading * pageWidth / 2
        case (.some, nil): return reading * pageWidth / 2
        default: return 0
        }
    }

    static func atRest(
        inSpreadContaining page: Int,
        layout: MekuriSpreadLayout,
        pageWidth: CGFloat,
        direction: MekuriDirection
    ) -> CGFloat {
        let slots = layout.pages(inSpread: layout.spreadIndex(containing: page))
        return self.atRest(leading: slots.leading, trailing: slots.trailing, pageWidth: pageWidth, direction: direction)
    }

    /// A blocked turn lands where it began.
    static func span(
        of turn: MekuriTurnState,
        layout: MekuriSpreadLayout,
        pageWidth: CGFloat,
        direction: MekuriDirection
    ) -> Span {
        Span(
            start: self.atRest(inSpreadContaining: turn.fromIndex, layout: layout, pageWidth: pageWidth, direction: direction),
            end: self.atRest(inSpreadContaining: turn.targetIndex ?? turn.fromIndex, layout: layout, pageWidth: pageWidth, direction: direction)
        )
    }
}

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
