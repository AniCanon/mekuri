package studio.anicanon.mekuri

import androidx.compose.runtime.ProvidableCompositionLocal
import androidx.compose.runtime.staticCompositionLocalOf

/**
 * How the enclosing page is being drawn. Provided by [MekuriPager] around every
 * slot and face it builds; [MekuriPageMode.Live] outside a pager.
 *
 * A [MekuriPageMode.Turning] page is sampled by the fold shader every frame and
 * must be drawable from what is already in memory: stand live playback down and
 * draw the last frame you have.
 */
public val LocalMekuriPageMode: ProvidableCompositionLocal<MekuriPageMode> =
    staticCompositionLocalOf { MekuriPageMode.Live }
