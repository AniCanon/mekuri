package app.mekuri

import androidx.compose.ui.geometry.Size
import kotlin.math.min

/**
 * Whether one or two pages share the container. [Automatic] shows two when they
 * fit the container at the page aspect and each stays readable.
 */
public enum class MekuriSpread {
    /**
     * Two pages when they fit the container at the page aspect and each is at
     * least [MinimumDoublePageWidth] wide; otherwise one.
     */
    Automatic,

    /** One page across the container, whatever its size. */
    Single,

    /** Two pages side by side, scaled to fit the container. */
    Double,

    ;

    /**
     * `pageAspectRatio` is width over height. Under [Automatic], two pages laid
     * out to the container's height must fit its width and each must be at
     * least [MinimumDoublePageWidth] wide.
     */
    internal fun isDouble(containerSize: Size, pageAspectRatio: Float): Boolean = when (this) {
        Single -> false
        Double -> true
        Automatic -> {
            val pageWidth = containerSize.height * pageAspectRatio
            containerSize.width >= 2 * pageWidth && pageWidth >= MinimumDoublePageWidth
        }
    }

    internal companion object {
        /** Narrowest single page, in dp, at which two pages stay readable. */
        internal const val MinimumDoublePageWidth = 320f

        /**
         * Largest page at `pageAspectRatio` such that two of them, side by side,
         * fit the container. `pageAspectRatio` must be positive.
         */
        internal fun pageSize(containerSize: Size, pageAspectRatio: Float): Size {
            val height = min(containerSize.height, containerSize.width / (2 * pageAspectRatio))
            return Size(width = height * pageAspectRatio, height = height)
        }
    }
}
