package app.mekuri

import androidx.compose.ui.geometry.Offset
import kotlin.math.abs

/**
 * Pure arithmetic mapping a horizontal drag onto a turn. `axis` is the sign of
 * horizontal travel that advances a turn; velocities are projected onto it
 * before they reach [MekuriTurnDecision].
 */
internal object MekuriDrag {
    /**
     * Horizontal travel must exceed vertical travel times this before a drag
     * locks a turn; a tie does not lock.
     */
    const val HorizontalDominance: Float = 1f

    /** Travel fraction kept when the turn is blocked at the first or last page. */
    const val BlockedDamping: Float = 1f / 3f

    /**
     * Re-evaluated on every sample until a turn locks; never latched.
     */
    fun isHorizontallyDominant(translation: Offset): Boolean =
        abs(translation.x) > abs(translation.y) * HorizontalDominance

    fun axis(turn: MekuriTurn, direction: MekuriDirection): Float = when (direction) {
        MekuriDirection.LeftToRight -> if (turn == MekuriTurn.Forward) -1f else 1f
        MekuriDirection.RightToLeft -> if (turn == MekuriTurn.Forward) 1f else -1f
    }

    /** Null when there is no horizontal travel. */
    fun turn(translation: Float, direction: MekuriDirection): MekuriTurn? {
        if (translation == 0f) return null
        val forwardAxis = this.axis(MekuriTurn.Forward, direction)
        return if (translation * forwardAxis > 0f) MekuriTurn.Forward else MekuriTurn.Backward
    }

    /** Null unless the drag is horizontally dominant. */
    fun turn(translation: Offset, direction: MekuriDirection): MekuriTurn? {
        if (!this.isHorizontallyDominant(translation)) return null
        return this.turn(translation.x, direction)
    }

    /**
     * Progress after `translation` from a drag that took over at `start`.
     * Clamped to 0..1, so reversing past the origin flattens the page rather
     * than starting the opposite turn; a blocked turn keeps [BlockedDamping] of
     * its travel.
     */
    fun progress(
        start: Float,
        translation: Float,
        width: Float,
        axis: Float,
        isBlocked: Boolean,
    ): Float {
        if (width <= 0f) return start
        val damping = if (isBlocked) BlockedDamping else 1f
        return (start + translation * axis / width * damping).coerceIn(0f, 1f)
    }

    /** Velocity measured along the turn, positive toward completion. */
    fun projectedVelocity(velocity: Float, axis: Float): Float = velocity * axis
}
