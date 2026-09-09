package app.mekuri

/**
 * Spine placement and sweep direction. Page indices stay in reading order
 * regardless of direction.
 */
public enum class MekuriDirection {
    /** The spine is the left edge; a forward turn lifts the right edge. */
    LeftToRight,

    /** The spine is the right edge; a forward turn lifts the left edge. */
    RightToLeft,

    ;

    /**
     * Signed fold travel. Positive sweeps the flap from the right edge toward
     * the left; negative mirrors it so the spine sits on the opposite edge.
     */
    internal fun sweep(progress: Float): Float = when (this) {
        LeftToRight -> progress
        RightToLeft -> -progress
    }
}
