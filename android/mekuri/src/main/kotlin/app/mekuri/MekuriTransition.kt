package app.mekuri

/**
 * How a selection change is animated. Only a change of exactly one step curls;
 * any larger jump crossfades. With a spread layout the change is measured in
 * spreads, so the two pages of one spread are no change at all.
 */
internal sealed interface MekuriTransition {
    data object None : MekuriTransition

    data class Curl(val turn: MekuriTurn) : MekuriTransition

    data object Crossfade : MekuriTransition

    companion object {
        fun between(from: Int, to: Int): MekuriTransition = when (to - from) {
            0 -> None
            1 -> Curl(MekuriTurn.Forward)
            -1 -> Curl(MekuriTurn.Backward)
            else -> Crossfade
        }

        fun between(from: Int, to: Int, layout: MekuriSpreadLayout): MekuriTransition =
            this.between(layout.spreadIndex(from), layout.spreadIndex(to))
    }
}
