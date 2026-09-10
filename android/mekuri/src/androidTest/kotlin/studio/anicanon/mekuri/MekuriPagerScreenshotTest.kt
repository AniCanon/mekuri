package studio.anicanon.mekuri

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.click
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.unit.dp
import androidx.test.ext.junit.runners.AndroidJUnit4
import kotlin.math.pow
import kotlin.math.sqrt
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Drives the public pager through its own gestures and captures the result. A
 * drag held down settles nothing, so each scene is a fixed progress with
 * nothing animating. The configuration pins reduced motion off; the system
 * setting would otherwise decide whether these scenes fold at all.
 */
@RunWith(AndroidJUnit4::class)
class MekuriPagerScreenshotTest {

    @get:Rule
    val rule = createComposeRule()

    private val configuration = MekuriConfiguration(reducedMotionOverride = false)

    @Test
    fun aSinglePageTurnsUnderTheFinger() {
        val state = MekuriPagerState(pageCount = { 6 }, initialPage = 2)
        this.rule.setContent {
            MekuriPagerScene(width = SINGLE_WIDTH, height = SINGLE_HEIGHT) {
                MekuriPager(
                    state = state,
                    configuration = this.configuration,
                    spread = MekuriSpread.Single,
                ) { page -> MekuriBookPage(page) }
            }
        }
        this.rule.onNodeWithTag(SCENE_TAG).performTouchInput {
            down(Offset(this.width * 0.94f, this.height / 2f))
            moveBy(Offset(-this.width * 0.45f, 0f))
        }
        this.rule.waitForIdle()
        this.rule.onNodeWithTag(SCENE_TAG).captureToImage().saveScene("01-single-page-turn")
        assertEquals(2, state.currentPage)
    }

    @Test
    fun aSpreadTurnsItsBackFaceAcrossTheSpine() {
        val state = MekuriPagerState(pageCount = { 8 }, initialPage = 1)
        this.rule.setContent {
            MekuriPagerScene(width = SPREAD_WIDTH, height = SPREAD_HEIGHT) {
                MekuriPager(
                    state = state,
                    configuration = this.configuration,
                    spread = MekuriSpread.Double,
                ) { page -> MekuriBookPage(page) }
            }
        }
        this.rule.onNodeWithTag(SCENE_TAG).performTouchInput {
            down(Offset(this.width * 0.97f, this.height / 2f))
            moveBy(Offset(-this.width * 0.58f, 0f))
        }
        this.rule.waitForIdle()
        this.rule.onNodeWithTag(SCENE_TAG).captureToImage().saveScene("02-spread-turn")
        assertEquals(1, state.currentPage)
    }

    @Test
    fun aLoneCoverSitsCentredInItsSpread() {
        val state = MekuriPagerState(pageCount = { 8 }, initialPage = 0)
        this.rule.setContent {
            MekuriPagerScene(width = SPREAD_WIDTH, height = SPREAD_HEIGHT) {
                MekuriPager(
                    state = state,
                    configuration = this.configuration,
                    spread = MekuriSpread.Double,
                    coverStandsAlone = true,
                ) { page -> MekuriBookPage(page) }
            }
        }
        this.rule.waitForIdle()
        this.rule.onNodeWithTag(SCENE_TAG).captureToImage().saveScene("03-lone-cover")
    }

    @Test
    fun theCoverSlidesToItsSlotAsItOpens() {
        val state = MekuriPagerState(pageCount = { 8 }, initialPage = 0)
        this.rule.setContent {
            MekuriPagerScene(width = SPREAD_WIDTH, height = SPREAD_HEIGHT) {
                MekuriPager(
                    state = state,
                    configuration = this.configuration,
                    spread = MekuriSpread.Double,
                    coverStandsAlone = true,
                ) { page -> MekuriBookPage(page) }
            }
        }
        this.rule.onNodeWithTag(SCENE_TAG).performTouchInput {
            down(Offset(this.width * 0.72f, this.height / 2f))
            moveBy(Offset(-this.width * 0.30f, 0f))
        }
        this.rule.waitForIdle()
        this.rule.onNodeWithTag(SCENE_TAG).captureToImage().saveScene("04-cover-opening")
        assertEquals(0, state.currentPage)
    }

    @Test
    fun anEdgeTapTurnsThePageAndACentreTapReports() {
        val state = MekuriPagerState(pageCount = { 6 }, initialPage = 2)
        var centreTaps = 0
        this.rule.setContent {
            MekuriPagerScene(width = SINGLE_WIDTH, height = SINGLE_HEIGHT) {
                MekuriPager(
                    state = state,
                    configuration = this.configuration,
                    spread = MekuriSpread.Single,
                    onCenterTap = { centreTaps += 1 },
                ) { page -> MekuriBookPage(page) }
            }
        }
        this.rule.onNodeWithTag(SCENE_TAG).performTouchInput {
            click(Offset(this.width / 2f, this.height / 2f))
        }
        this.rule.waitForIdle()
        assertEquals(1, centreTaps)
        assertEquals(2, state.currentPage)

        this.rule.onNodeWithTag(SCENE_TAG).performTouchInput {
            click(Offset(this.width * 0.95f, this.height / 2f))
        }
        this.rule.waitForIdle()
        assertEquals(1, centreTaps)
        assertEquals(3, state.currentPage)
        this.rule.onNodeWithTag(SCENE_TAG).captureToImage().saveScene("05-after-an-edge-tap")
    }

    /**
     * A blocked turn has no base, so the ground behind the pager is the
     * end-of-book cue. Past the crease the capture must be that ground and not
     * the page, which is what a base falling back to the settled page would
     * draw there.
     */
    @Test
    fun aBlockedTurnLiftsThePageOverTheGround() {
        val state = MekuriPagerState(pageCount = { 6 }, initialPage = 5)
        this.rule.setContent {
            MekuriPagerScene(width = SINGLE_WIDTH, height = SINGLE_HEIGHT) {
                MekuriPager(
                    state = state,
                    configuration = this.configuration,
                    spread = MekuriSpread.Single,
                ) { page -> MekuriBookPage(page) }
            }
        }
        this.rule.onNodeWithTag(SCENE_TAG).performTouchInput {
            down(Offset(this.width * 0.94f, this.height / 2f))
            moveBy(Offset(-this.width * 0.85f, 0f))
        }
        this.rule.waitForIdle()
        val image = this.rule.onNodeWithTag(SCENE_TAG).captureToImage()
        image.saveScene("06-blocked-at-the-end")
        val pixels = image.toPixelMap()
        val sampled = pixels[(pixels.width * SAMPLE_X).toInt(), pixels.height / 2]
        assertEquals(5, state.currentPage)
        assertTrue("past the crease reads $sampled", sampled.distanceTo(SCENE_GROUND) < NEAR)
        assertTrue("past the crease reads $sampled", sampled.distanceTo(LAST_PAGE_GROUND) > NEAR)
    }

    @Composable
    private fun MekuriPagerScene(width: Int, height: Int, content: @Composable () -> Unit) {
        Box(
            Modifier
                .size(width.dp, height.dp)
                .testTag(SCENE_TAG)
                .drawBehind { drawRect(Color(0xFF1A1614)) },
        ) {
            content()
        }
    }

    private companion object {
        private const val SINGLE_WIDTH = 360
        private const val SINGLE_HEIGHT = 540
        private const val SPREAD_WIDTH = 400
        private const val SPREAD_HEIGHT = 270
        private const val SAMPLE_X = 0.97f
        private const val NEAR = 0.08f
        private val SCENE_GROUND = Color(0xFF1A1614)
        private val LAST_PAGE_GROUND = Color(0xFF6B3C7A)
    }
}

/** Straight-line distance in unpremultiplied RGB, alpha ignored. */
internal fun Color.distanceTo(other: Color): Float = sqrt(
    (this.red - other.red).pow(2) + (this.green - other.green).pow(2) + (this.blue - other.blue).pow(2),
)

/** A page whose number and colour make its slot and its face unmistakable. */
@Composable
internal fun MekuriBookPage(page: Int) {
    val grounds = listOf(
        Color(0xFFF4EFE4),
        Color(0xFF7A2E2E),
        Color(0xFF2E5A7A),
        Color(0xFFE0B93C),
        Color(0xFF3C6E4A),
        Color(0xFF6B3C7A),
    )
    val ground = grounds[page % grounds.size]
    val ink = if (page % grounds.size == 0 || page % grounds.size == 3) {
        Color(0xFF2B2118)
    } else {
        Color(0xFFF6F1E7)
    }
    MekuriHarnessPage(label = "${page + 1}", ground = ground, ink = ink)
}
