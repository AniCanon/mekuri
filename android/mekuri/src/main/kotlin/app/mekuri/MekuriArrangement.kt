package app.mekuri

import androidx.compose.ui.geometry.Size

/**
 * What the container holds: one page across its whole width, or a spread of two
 * [Spread.pageSize] slots side by side, centred, with the spine between them.
 * Every turn and selection change is judged against it.
 */
internal sealed interface MekuriArrangement {
    data class Single(val pageCount: Int) : MekuriArrangement

    data class Spread(val layout: MekuriSpreadLayout, val pageSize: Size) : MekuriArrangement

    /** Distance a drag travels to complete a turn: the width of what turns. */
    fun turnWidth(containerWidth: Float): Float = when (this) {
        is Single -> containerWidth
        is Spread -> this.pageSize.width * 2f
    }

    fun turnState(id: Int, turn: MekuriTurn, from: Int): MekuriTurnState = when (this) {
        is Single -> MekuriTurnState.begin(id, turn, from, this.pageCount)
        is Spread -> MekuriTurnState.begin(id, turn, from, this.layout)
    }

    fun transition(from: Int, to: Int): MekuriTransition = when (this) {
        is Single -> MekuriTransition.between(from, to)
        is Spread -> MekuriTransition.between(from, to, this.layout)
    }

    /** Live pages at rest. Single mode fills the trailing slot only. */
    fun slots(page: Int): MekuriSpreadPages = when (this) {
        is Single -> MekuriSpreadPages(
            leading = null,
            trailing = if (page in 0 until this.pageCount) page else null,
        )
        is Spread -> this.layout.pages(this.layout.spreadIndex(page))
    }

    /** Always zero in single mode. */
    fun shiftSpan(page: Int, turn: MekuriTurnState?, direction: MekuriDirection): MekuriShiftSpan =
        when (this) {
            is Single -> MekuriShiftSpan.Zero
            is Spread -> if (turn != null) {
                MekuriSpreadShift.span(turn, this.layout, this.pageSize.width, direction)
            } else {
                val rest = MekuriSpreadShift.atRest(page, this.layout, this.pageSize.width, direction)
                MekuriShiftSpan(rest, rest)
            }
        }

    companion object {
        fun resolve(
            containerSize: Size,
            pageCount: Int,
            spread: MekuriSpread,
            coverStandsAlone: Boolean,
            pageAspectRatio: Float,
        ): MekuriArrangement {
            if (!spread.isDouble(containerSize, pageAspectRatio)) return Single(pageCount)
            return Spread(
                layout = MekuriSpreadLayout(pageCount, coverStandsAlone),
                pageSize = MekuriSpread.pageSize(containerSize, pageAspectRatio),
            )
        }
    }
}
