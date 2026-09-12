package studio.anicanon.mekuri

import androidx.compose.ui.geometry.Size

/**
 * What the container holds: one page across its whole width, or a spread of two
 * [Spread.pageSize] slots side by side, centred, with the spine between them.
 * Every turn and selection change is judged against it.
 */
internal sealed interface MekuriArrangement {
    data class Single(val pageCount: Int) : MekuriArrangement

    data class Spread(val layout: MekuriSpreadLayout, val pageSize: Size) : MekuriArrangement

    /**
     * Distance the free edge travels across a whole turn, so the edge stays under
     * the finger. A single page's edge crosses the container and as far again
     * past the spine, beyond any drag; a spread's crosses both slots.
     */
    fun turnWidth(containerWidth: Float): Float = when (this) {
        is Single -> containerWidth * 2f
        is Spread -> this.pageSize.width * 2f
    }

    /** Share of a turn a drag across the whole page or spread reaches. */
    val dragReach: Float
        get() = when (this) {
            is Single -> 0.5f
            is Spread -> 1f
        }

    /**
     * Progress as a release is judged: the share of the travel a drag can reach,
     * so the snap threshold means the same distance in either mode.
     */
    fun releaseProgress(progress: Float): Float = progress / this.dragReach

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
