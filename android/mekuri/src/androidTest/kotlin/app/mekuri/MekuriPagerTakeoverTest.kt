package app.mekuri

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.click
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.unit.dp
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/** A settle a finger catches mid-flight, over a settle nothing catches. */
@RunWith(AndroidJUnit4::class)
class MekuriPagerTakeoverTest {

    @get:Rule
    val rule = createComposeRule()

    /**
     * The grabbed settle continues from the presented progress: the fold holds
     * where the finger caught it instead of running on or jumping to rest, and
     * a release pushed back leaves the page the turn started from.
     */
    @Test
    fun aDragTakesOverASettleAndPushesItBack() {
        val rest = mutableListOf<ImageBitmap>()
        val state = this.settlingPager { rest += this.capture("android-0-at-rest") }
        this.capture("android-1-settling")

        this.rule.onNodeWithTag(SCENE_TAG).performTouchInput {
            down(Offset(this.width * GRAB_X, this.height / 2f))
            moveBy(Offset(-GRAB_TRAVEL, 0f))
        }
        repeat(FRAMES) { this.rule.mainClock.advanceTimeByFrame() }
        val grabbed = this.capture("android-2-grabbed")
        assertTrue(countDifferences(rest.single().pixels(), grabbed.pixels()) > 0)

        this.rule.mainClock.advanceTimeBy(HOLD_MILLIS)
        val held = this.capture("android-3-held")
        assertEquals(0, countDifferences(grabbed.pixels(), held.pixels()))

        this.rule.onNodeWithTag(SCENE_TAG).performTouchInput {
            moveBy(Offset(this.width * PUSH_BACK, 0f))
            up()
        }
        this.rule.mainClock.autoAdvance = true
        this.rule.waitForIdle()
        this.capture("android-4-pushed-back")
        assertEquals(START_PAGE, state.currentPage)
    }

    /** The same wait, ungrabbed: the settle runs on and the frame moves. */
    @Test
    fun anUngrabbedSettleKeepsMoving() {
        this.settlingPager()
        val settling = this.rule.onNodeWithTag(SCENE_TAG).captureToImage()
        this.rule.mainClock.advanceTimeBy(HOLD_MILLIS)
        val later = this.rule.onNodeWithTag(SCENE_TAG).captureToImage()
        assertTrue(countDifferences(settling.pixels(), later.pixels()) > 0)
    }

    /** Leaves a linear settle running, part way through, on a paused clock. */
    private fun settlingPager(atRest: () -> Unit = {}): MekuriPagerState {
        val state = MekuriPagerState(pageCount = { 6 }, initialPage = START_PAGE)
        this.rule.mainClock.autoAdvance = false
        this.rule.setContent {
            Scene {
                MekuriPager(
                    state = state,
                    configuration = MekuriConfiguration(
                        settleAnimation = tween(SETTLE_MILLIS, easing = LinearEasing),
                        reducedMotionOverride = false,
                    ),
                    spread = MekuriSpread.Single,
                ) { page -> MekuriBookPage(page) }
            }
        }
        this.rule.mainClock.advanceTimeByFrame()
        atRest()
        this.rule.onNodeWithTag(SCENE_TAG).performTouchInput {
            click(Offset(this.width * TRAILING_EDGE, this.height / 2f))
        }
        repeat(FRAMES) { this.rule.mainClock.advanceTimeByFrame() }
        this.rule.mainClock.advanceTimeBy(GRAB_MILLIS)
        return state
    }

    private fun capture(name: String): ImageBitmap {
        val image = this.rule.onNodeWithTag(SCENE_TAG).captureToImage()
        image.saveScene(name)
        return image
    }

    @Composable
    private fun Scene(content: @Composable () -> Unit) {
        Box(Modifier.size(SCENE_WIDTH.dp, SCENE_HEIGHT.dp).testTag(SCENE_TAG)) { content() }
    }

    private companion object {
        private const val SCENE_WIDTH = 360
        private const val SCENE_HEIGHT = 540
        private const val START_PAGE = 2
        private const val SETTLE_MILLIS = 4000
        private const val GRAB_MILLIS = 1000L
        private const val HOLD_MILLIS = 1500L
        private const val FRAMES = 3
        private const val TRAILING_EDGE = 0.95f
        private const val GRAB_X = 0.6f

        /** Comfortably past any device's touch slop. */
        private const val GRAB_TRAVEL = 60f
        private const val PUSH_BACK = 0.5f
    }
}
