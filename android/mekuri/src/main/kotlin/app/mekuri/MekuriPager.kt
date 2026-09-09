package app.mekuri

import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.semantics.CustomAccessibilityAction
import androidx.compose.ui.semantics.customActions
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription

/**
 * A page-curl pager over any content.
 *
 * Pages are addressed by index in reading order and [state] carries the
 * selection. A tap in an outer zone or a horizontal drag turns one page, or one
 * spread when two pages share the container; the reading direction decides which
 * edge is the spine and never touches the numbering.
 *
 * ```kotlin
 * val state = rememberMekuriPagerState(pageCount = pages.size)
 * MekuriPager(state = state, onCenterTap = { chromeHidden = !chromeHidden }) { page ->
 *     PageContent(pages[page])   // reads LocalMekuriPageMode.current
 * }
 * ```
 *
 * Only the visible page or spread and the two faces of a turning leaf are ever
 * built. A face reads [LocalMekuriPageMode] as [MekuriPageMode.Turning] and must
 * be drawable from what is already in memory. A blocked turn at either end lifts
 * the page over whatever is behind the pager, so give it a background.
 *
 * @param state selection and turn control; see [rememberMekuriPagerState].
 * @param pagingEnabled whether taps and drags turn pages. A centre tap still
 *   reports when they do not. A gesture keeps the value it began under, so a
 *   drag in flight when this turns false still releases its turn.
 * @param onCenterTap called for a tap outside both edge zones.
 * @param spread whether one or two pages share the container.
 * @param coverStandsAlone whether page 0 opens alone, like a cover.
 * @param pageAspectRatio width over height of one page.
 * @param content builds the page at an index.
 */
@Composable
public fun MekuriPager(
    state: MekuriPagerState,
    modifier: Modifier = Modifier,
    configuration: MekuriConfiguration = MekuriConfiguration(),
    pagingEnabled: Boolean = true,
    onCenterTap: (() -> Unit)? = null,
    spread: MekuriSpread = MekuriSpread.Automatic,
    coverStandsAlone: Boolean = true,
    pageAspectRatio: Float = DEFAULT_PAGE_ASPECT_RATIO,
    content: @Composable (Int) -> Unit,
) {
    val scope = rememberCoroutineScope()
    val controller = remember(state, scope) { MekuriPagerController(state, scope) }
    controller.configuration = configuration
    controller.reducesMotion = rememberMekuriReducesMotion(configuration.reducedMotionOverride)

    DisposableEffect(state, controller) {
        state.attach(controller)
        onDispose { state.detach(controller) }
    }

    BoxWithConstraints(
        modifier
            .mekuriGestures(controller, pagingEnabled, onCenterTap)
            .semantics {
                stateDescription = "Page ${state.currentPage + 1} of ${state.pageCount}"
                customActions = mekuriPageActions(controller, pagingEnabled)
            },
    ) {
        val size = Size(this.maxWidth.value, this.maxHeight.value)
        controller.containerSize = size
        val lastSize = remember(controller) { mutableStateOf(size) }
        LaunchedEffect(controller, size) {
            if (lastSize.value == size) return@LaunchedEffect
            lastSize.value = size
            controller.dropTurn()
        }
        val arrangement = MekuriArrangement.resolve(
            containerSize = size,
            pageCount = state.pageCount,
            spread = spread,
            coverStandsAlone = coverStandsAlone,
            pageAspectRatio = pageAspectRatio,
        )
        controller.arrangement = arrangement
        when (arrangement) {
            is MekuriArrangement.Single -> MekuriSingleLayers(controller, content)
            is MekuriArrangement.Spread -> MekuriSpreadLayers(controller, arrangement.pageSize, content)
        }
    }
}

private fun mekuriPageActions(
    controller: MekuriPagerController,
    pagingEnabled: Boolean,
): List<CustomAccessibilityAction> {
    if (!pagingEnabled) return emptyList()
    return listOf(
        CustomAccessibilityAction("Next page") {
            controller.perform(MekuriTurn.Forward)
            true
        },
        CustomAccessibilityAction("Previous page") {
            controller.perform(MekuriTurn.Backward)
            true
        },
    )
}

private const val DEFAULT_PAGE_ASPECT_RATIO = 2f / 3f
