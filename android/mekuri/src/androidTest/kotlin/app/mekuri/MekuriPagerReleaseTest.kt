package app.mekuri

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.swipe
import androidx.compose.ui.test.swipeWithVelocity
import androidx.compose.ui.unit.dp
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * What a released drag lands on. A synthesised `moveBy` followed by `up` carries
 * an enormous velocity — two samples one frame apart — so every drag here is a
 * `swipe` with an explicit duration, and the fling case names its end velocity.
 */
@RunWith(AndroidJUnit4::class)
class MekuriPagerReleaseTest {

    @get:Rule
    val rule = createComposeRule()

    @Test
    fun aSlowDragPastTheSnapThresholdCommits() {
        val state = this.pager()
        this.rule.onNodeWithTag(SCENE_TAG).performTouchInput {
            swipe(
                start = Offset(this.width * DRAG_START, this.height / 2f),
                end = Offset(this.width * (DRAG_START - PAST_THRESHOLD), this.height / 2f),
                durationMillis = SLOW_MILLIS,
            )
        }
        this.rule.waitForIdle()
        assertEquals(3, state.currentPage)
    }

    @Test
    fun aSlowDragShortOfTheSnapThresholdReverts() {
        val state = this.pager()
        this.rule.onNodeWithTag(SCENE_TAG).performTouchInput {
            swipe(
                start = Offset(this.width * DRAG_START, this.height / 2f),
                end = Offset(this.width * (DRAG_START - SHORT_OF_THRESHOLD), this.height / 2f),
                durationMillis = SLOW_MILLIS,
            )
        }
        this.rule.waitForIdle()
        assertEquals(2, state.currentPage)
    }

    /** The same travel as the reverting drag, flicked rather than dragged. */
    @Test
    fun aFlickShortOfTheSnapThresholdCommits() {
        val state = this.pager()
        val density = this.rule.density.density
        this.rule.onNodeWithTag(SCENE_TAG).performTouchInput {
            swipeWithVelocity(
                start = Offset(this.width * DRAG_START, this.height / 2f),
                end = Offset(this.width * (DRAG_START - SHORT_OF_THRESHOLD), this.height / 2f),
                endVelocity = FLICK_DP_PER_SECOND * density,
                durationMillis = FLICK_MILLIS,
            )
        }
        this.rule.waitForIdle()
        assertEquals(3, state.currentPage)
    }

    private fun pager(): MekuriPagerState {
        val state = MekuriPagerState(pageCount = 6, initialPage = 2)
        this.rule.setContent {
            Scene {
                MekuriPager(
                    state = state,
                    configuration = MekuriConfiguration(reducedMotionOverride = false),
                    spread = MekuriSpread.Single,
                ) { page -> MekuriBookPage(page) }
            }
        }
        this.rule.waitForIdle()
        return state
    }

    @Composable
    private fun Scene(content: @Composable () -> Unit) {
        Box(Modifier.size(SCENE_WIDTH.dp, SCENE_HEIGHT.dp).testTag(SCENE_TAG)) { content() }
    }

    private companion object {
        private const val SCENE_WIDTH = 360
        private const val SCENE_HEIGHT = 540
        private const val DRAG_START = 0.9f
        private const val PAST_THRESHOLD = 0.5f
        private const val SHORT_OF_THRESHOLD = 0.2f
        private const val SLOW_MILLIS = 2000L
        private const val FLICK_MILLIS = 80L
        private const val FLICK_DP_PER_SECOND = 1500f
    }
}
