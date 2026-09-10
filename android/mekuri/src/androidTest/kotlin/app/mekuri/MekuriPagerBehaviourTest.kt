package app.mekuri

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.click
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.unit.dp
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/** The pager's rules that no still frame can show. */
@RunWith(AndroidJUnit4::class)
class MekuriPagerBehaviourTest {

    @get:Rule
    val rule = createComposeRule()

    @Test
    fun pagingStoodDownStillReportsACentreTap() {
        val state = MekuriPagerState(pageCount = { 6 }, initialPage = 2)
        var centreTaps = 0
        this.rule.setContent {
            Scene {
                MekuriPager(
                    state = state,
                    configuration = MekuriConfiguration(reducedMotionOverride = false),
                    pagingEnabled = false,
                    onCenterTap = { centreTaps += 1 },
                    spread = MekuriSpread.Single,
                ) { page -> MekuriBookPage(page) }
            }
        }
        this.rule.onNodeWithTag(SCENE_TAG).performTouchInput {
            click(Offset(this.width / 2f, this.height / 2f))
        }
        this.rule.waitForIdle()
        assertEquals(1, centreTaps)

        this.rule.onNodeWithTag(SCENE_TAG).performTouchInput {
            click(Offset(this.width * 0.95f, this.height / 2f))
        }
        this.rule.waitForIdle()
        assertEquals(1, centreTaps)
        assertEquals(2, state.currentPage)

        this.rule.onNodeWithTag(SCENE_TAG).performTouchInput {
            down(Offset(this.width * 0.9f, this.height / 2f))
            moveBy(Offset(-this.width * 0.7f, 0f))
            up()
        }
        this.rule.waitForIdle()
        assertEquals(2, state.currentPage)
    }

    @Test
    fun aDragBlockedAtTheEndSpringsBack() {
        val state = MekuriPagerState(pageCount = { 6 }, initialPage = 5)
        this.rule.setContent {
            Scene {
                MekuriPager(
                    state = state,
                    configuration = MekuriConfiguration(reducedMotionOverride = false),
                    spread = MekuriSpread.Single,
                ) { page -> MekuriBookPage(page) }
            }
        }
        this.rule.onNodeWithTag(SCENE_TAG).performTouchInput {
            down(Offset(this.width * 0.9f, this.height / 2f))
            moveBy(Offset(-this.width * 0.85f, 0f))
            up()
        }
        this.rule.waitForIdle()
        assertEquals(5, state.currentPage)
    }

    @Test
    fun anEdgeTapUnderReducedMotionCutsToTheNextPage() {
        val state = this.tapTheTrailingEdge(reducesMotion = true)
        assertEquals(3, state.currentPage)
    }

    @Test
    fun anEdgeTapWithMotionSettlesRatherThanCutting() {
        val state = this.tapTheTrailingEdge(reducesMotion = false)
        assertEquals(2, state.currentPage)
        this.rule.mainClock.autoAdvance = true
        this.rule.waitForIdle()
        assertEquals(3, state.currentPage)
    }

    /** Leaves the clock paused a few frames after the tap. */
    private fun tapTheTrailingEdge(reducesMotion: Boolean): MekuriPagerState {
        val state = MekuriPagerState(pageCount = { 6 }, initialPage = 2)
        this.rule.mainClock.autoAdvance = false
        this.rule.setContent {
            Scene {
                MekuriPager(
                    state = state,
                    configuration = MekuriConfiguration(reducedMotionOverride = reducesMotion),
                    spread = MekuriSpread.Single,
                ) { page -> MekuriBookPage(page) }
            }
        }
        this.rule.mainClock.advanceTimeByFrame()
        this.rule.onNodeWithTag(SCENE_TAG).performTouchInput {
            click(Offset(this.width * 0.95f, this.height / 2f))
        }
        repeat(FRAMES_AFTER_A_TAP) { this.rule.mainClock.advanceTimeByFrame() }
        return state
    }

    @Test
    fun aTurningFaceTellsAChildAtAnyDepth() {
        val state = MekuriPagerState(pageCount = { 6 }, initialPage = 2)
        val modes = mutableMapOf<Int, MekuriPageMode>()
        this.rule.setContent {
            Scene {
                MekuriPager(
                    state = state,
                    configuration = MekuriConfiguration(reducedMotionOverride = false),
                    spread = MekuriSpread.Single,
                ) { page ->
                    Box(Modifier) {
                        Box(Modifier) {
                            Box(Modifier) { modes[page] = LocalMekuriPageMode.current }
                        }
                    }
                    MekuriBookPage(page)
                }
            }
        }
        this.rule.waitForIdle()
        assertEquals(mapOf(2 to MekuriPageMode.Live), modes.toMap())

        this.rule.onNodeWithTag(SCENE_TAG).performTouchInput {
            down(Offset(this.width * 0.9f, this.height / 2f))
            moveBy(Offset(-this.width * 0.4f, 0f))
        }
        this.rule.waitForIdle()
        assertEquals(MekuriPageMode.Turning, modes[2])
        assertEquals(MekuriPageMode.Live, modes[3])
    }

    @Test
    fun aContainerSizeChangeDropsTheTurnInFlight() {
        val state = MekuriPagerState(pageCount = { 6 }, initialPage = 2)
        var narrow by mutableStateOf(true)
        this.rule.setContent {
            Scene(width = if (narrow) SCENE_WIDTH else SCENE_WIDTH - 40) {
                MekuriPager(
                    state = state,
                    configuration = MekuriConfiguration(reducedMotionOverride = false),
                    spread = MekuriSpread.Single,
                ) { page -> MekuriBookPage(page) }
            }
        }
        this.rule.onNodeWithTag(SCENE_TAG).performTouchInput {
            down(Offset(this.width * 0.9f, this.height / 2f))
            moveBy(Offset(-this.width * 0.8f, 0f))
        }
        this.rule.waitForIdle()
        narrow = false
        this.rule.waitForIdle()
        this.rule.onNodeWithTag(SCENE_TAG).performTouchInput { up() }
        this.rule.waitForIdle()
        assertEquals(2, state.currentPage)
    }

    @Test
    fun aJumpOfMoreThanOnePageCrossfadesAndLands() {
        val state = MekuriPagerState(pageCount = { 6 }, initialPage = 0)
        var jump by mutableStateOf(false)
        this.rule.setContent {
            Scene {
                MekuriPager(
                    state = state,
                    configuration = MekuriConfiguration(reducedMotionOverride = false),
                    spread = MekuriSpread.Single,
                ) { page -> MekuriBookPage(page) }
                if (jump) LaunchedEffect(Unit) { state.animateToPage(4) }
            }
        }
        this.rule.waitForIdle()
        jump = true
        this.rule.waitForIdle()
        assertEquals(4, state.currentPage)
    }

    /**
     * The base slot changes page the moment a turn begins. Page state must not
     * survive that swap: a page born in one slot is born as itself.
     */
    @Test
    fun aSlotThatChangesPageBuildsANewPage() {
        val state = MekuriPagerState(pageCount = { 6 }, initialPage = 2)
        val bornAs = mutableMapOf<Int, Int>()
        this.rule.setContent {
            Scene {
                MekuriPager(
                    state = state,
                    configuration = MekuriConfiguration(reducedMotionOverride = false),
                    spread = MekuriSpread.Single,
                ) { page ->
                    val born = remember { page }
                    bornAs[page] = born
                    MekuriBookPage(page)
                }
            }
        }
        this.rule.waitForIdle()
        this.rule.onNodeWithTag(SCENE_TAG).performTouchInput {
            click(Offset(this.width * 0.95f, this.height / 2f))
        }
        this.rule.waitForIdle()
        assertEquals(3, state.currentPage)
        assertEquals(mapOf(2 to 2, 3 to 3), bornAs.toMap())
    }

    /**
     * A recomposition mid-drag may not restart the pointer loop: the gesture
     * would end with neither a release nor a cancel and leave a turn in flight
     * that swallows every later tap.
     */
    @Test
    fun pagingFlippedMidDragStillReleasesTheTurn() {
        val state = MekuriPagerState(pageCount = { 6 }, initialPage = 2)
        var paging by mutableStateOf(true)
        this.rule.setContent {
            Scene {
                MekuriPager(
                    state = state,
                    configuration = MekuriConfiguration(reducedMotionOverride = false),
                    pagingEnabled = paging,
                    spread = MekuriSpread.Single,
                ) { page -> MekuriBookPage(page) }
            }
        }
        this.rule.onNodeWithTag(SCENE_TAG).performTouchInput {
            down(Offset(this.width * 0.9f, this.height / 2f))
            moveBy(Offset(-this.width * 0.5f, 0f))
        }
        this.rule.waitForIdle()
        paging = false
        this.rule.waitForIdle()
        this.rule.onNodeWithTag(SCENE_TAG).performTouchInput { up() }
        this.rule.waitForIdle()
        assertEquals(3, state.currentPage)

        paging = true
        this.rule.waitForIdle()
        this.rule.onNodeWithTag(SCENE_TAG).performTouchInput {
            click(Offset(this.width * 0.95f, this.height / 2f))
        }
        this.rule.waitForIdle()
        assertEquals(4, state.currentPage)
    }

    /** A cancelled caller cancels the curl; it may not land the page anyway. */
    @Test
    fun cancellingTheCallerOfAnAnimationDropsTheCurl() {
        val state = MekuriPagerState(pageCount = { 6 }, initialPage = 2)
        var animating by mutableStateOf(false)
        this.rule.mainClock.autoAdvance = false
        this.rule.setContent {
            Scene {
                MekuriPager(
                    state = state,
                    configuration = MekuriConfiguration(reducedMotionOverride = false),
                    spread = MekuriSpread.Single,
                ) { page -> MekuriBookPage(page) }
                if (animating) LaunchedEffect(Unit) { state.animateToPage(3) }
            }
        }
        this.rule.mainClock.advanceTimeByFrame()
        animating = true
        repeat(FRAMES_AFTER_A_TAP) { this.rule.mainClock.advanceTimeByFrame() }
        animating = false
        repeat(FRAMES_AFTER_A_TAP) { this.rule.mainClock.advanceTimeByFrame() }
        this.rule.mainClock.autoAdvance = true
        this.rule.waitForIdle()
        assertEquals(2, state.currentPage)
    }

    /** The later of two animations owns the turn; the dropped one lets go. */
    @Test
    fun aSecondAnimationLandsOverTheFirst() {
        val state = MekuriPagerState(pageCount = { 6 }, initialPage = 2)
        var first by mutableStateOf(false)
        var second by mutableStateOf(false)
        this.rule.mainClock.autoAdvance = false
        this.rule.setContent {
            Scene {
                MekuriPager(
                    state = state,
                    configuration = MekuriConfiguration(reducedMotionOverride = false),
                    spread = MekuriSpread.Single,
                ) { page -> MekuriBookPage(page) }
                if (first) LaunchedEffect(Unit) { state.animateToPage(3) }
                if (second) LaunchedEffect(Unit) { state.animateToPage(1) }
            }
        }
        this.rule.mainClock.advanceTimeByFrame()
        first = true
        repeat(FRAMES_AFTER_A_TAP) { this.rule.mainClock.advanceTimeByFrame() }
        second = true
        repeat(FRAMES_AFTER_A_TAP) { this.rule.mainClock.advanceTimeByFrame() }
        this.rule.mainClock.autoAdvance = true
        this.rule.waitForIdle()
        assertEquals(1, state.currentPage)
    }

    @Composable
    private fun Scene(width: Int = SCENE_WIDTH, content: @Composable () -> Unit) {
        Box(Modifier.size(width.dp, SCENE_HEIGHT.dp).testTag(SCENE_TAG)) { content() }
    }

    private companion object {
        private const val SCENE_WIDTH = 360
        private const val SCENE_HEIGHT = 540
        private const val FRAMES_AFTER_A_TAP = 3
    }
}
