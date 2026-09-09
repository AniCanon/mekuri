package app.mekuri

import kotlin.math.abs

/**
 * What one fold render needs for a direction and progress. The shader only
 * folds a flap entering from the right, so a right-to-left turn mirrors the
 * page around it; [shaderProgress] is never negative.
 */
internal data class MekuriFoldPass(
    val isMirrored: Boolean,
    val shaderProgress: Float,
) {
    constructor(direction: MekuriDirection, progress: Float) : this(
        isMirrored = direction == MekuriDirection.RightToLeft,
        shaderProgress = abs(direction.sweep(progress)),
    )

    /** Horizontal scale applied on both sides of the fold effect. */
    val mirrorScale: Float
        get() = if (isMirrored) -1f else 1f

    internal companion object {
        /** The mirror depends on the direction alone, not on progress. */
        fun mirrorScale(direction: MekuriDirection): Float =
            MekuriFoldPass(direction, 0f).mirrorScale
    }
}
