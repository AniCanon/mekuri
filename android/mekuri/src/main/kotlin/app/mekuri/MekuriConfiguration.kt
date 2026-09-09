package app.mekuri

import androidx.compose.animation.core.AnimationSpec
import androidx.compose.animation.core.spring

/**
 * Fold and gesture tuning shared by every page turn.
 *
 * Every numeric member is held in parity with the iOS type. [settleAnimation]
 * is not: the two animation systems have no shared representation.
 */
data class MekuriConfiguration(
    /** Cylinder radius at the held end of the fold as a ratio of the page width. */
    val cylinderRadiusRatio: Float = 0.04f,

    /**
     * Growth of the cylinder radius per page width of fold distance from the
     * held end, as a multiple of [cylinderRadiusRatio]. 0 keeps the radius
     * constant along the fold.
     */
    val radiusOpening: Float = 1.0f,

    /**
     * How far the free corner runs ahead of a straight crease, 0..1. 0 is a
     * straight crease.
     */
    val creaseBow: Float = 0.35f,

    /**
     * Horizontal travel of the fold line per unit of vertical distance from the
     * page centre. A ratio, not an angle.
     */
    val cornerShear: Float = 0.10f,

    /**
     * Darkest brightness of the lit back face, 0..1, reached where the surface
     * has turned fully away from the light.
     */
    val backFaceDim: Float = 0.86f,

    /** Width of the crease shadow as a ratio of the page width. */
    val creaseShadowWidthRatio: Float = 0.10f,

    /** Peak opacity of the crease shadow, 0..1. */
    val creaseShadowOpacity: Float = 0.35f,

    /** Turn progress, 0..1, past which a released drag completes the turn. */
    val snapThreshold: Float = 0.35f,

    /**
     * Drag velocity in dp per second, projected onto the turn's axis, at which
     * a release completes the turn regardless of progress.
     */
    val flingVelocity: Float = 600f,

    /** Width of each tap-to-turn edge zone as a ratio of the container width. */
    val tapZoneRatio: Float = 0.25f,

    /** Animation used to settle a released turn. */
    val settleAnimation: AnimationSpec<Float> = DefaultSettleAnimation,

    /** Overrides the system reduce-motion setting when non-null. */
    val reducedMotionOverride: Boolean? = null,
) {
    companion object {
        /** Not held in numeric parity with the iOS settle spring. */
        val DefaultSettleAnimation: AnimationSpec<Float> = spring(
            dampingRatio = 0.86f,
            stiffness = 320f,
        )

        val Default = MekuriConfiguration()

        /** A vertical straight crease with a constant radius. */
        val StraightCrease = MekuriConfiguration(
            radiusOpening = 0f,
            creaseBow = 0f,
            cornerShear = 0f,
        )
    }
}
