package app.mekuri

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.runtime.MutableFloatState
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.ComposeContentTestRule
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.unit.dp
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Renders the fold at a fixed progress with nothing animating and saves the
 * result. The shader needs a device, so these run instrumented.
 */
@RunWith(AndroidJUnit4::class)
class MekuriFoldScreenshotTest {

    @get:Rule
    val rule = createComposeRule()

    @Test
    fun singlePageFoldedAtFixedProgress() {
        rule.setContent {
            MekuriScene(width = PAGE_WIDTH, height = PAGE_HEIGHT) {
                MekuriFoldedPage(
                    progress = { 0.40f },
                    direction = MekuriDirection.LeftToRight,
                    configuration = MekuriConfiguration(),
                    modifier = Modifier.fillMaxSize(),
                ) {
                    MekuriHarnessPage("FRONT", Color(0xFFF4EFE4), Color(0xFF2B2118))
                }
            }
        }
        rule.onNodeWithTag(SCENE_TAG).captureToImage().saveScene("01-folded-page")
    }

    @Test
    fun twoFacedLeafAtFixedProgress() {
        rule.setContent {
            MekuriScene(width = LEAF_WIDTH, height = PAGE_HEIGHT) {
                MekuriFoldedLeaf(
                    progress = { 0.55f },
                    direction = MekuriDirection.LeftToRight,
                    configuration = MekuriConfiguration(),
                    modifier = Modifier.fillMaxSize(),
                    back = { MekuriHarnessPage("BACK", Color(0xFF7A2E1E), Color(0xFFFFE9D6)) },
                    front = { MekuriHarnessPage("FRONT", Color(0xFFF4EFE4), Color(0xFF2B2118)) },
                )
            }
        }
        rule.onNodeWithTag(SCENE_TAG).captureToImage().saveScene("02-two-faced-leaf")
    }

    @Test
    fun leafShadowFallsOnTheRevealedPage() {
        rule.setContent {
            MekuriScene(width = LEAF_WIDTH, height = PAGE_HEIGHT) {
                Box(Modifier.fillMaxSize()) {
                    MekuriHarnessPage("REVEALED", Color(0xFFFFFFFF), Color(0xFF9AA7B4), barCount = 13)
                    MekuriLeafShadow(
                        progress = { 0.30f },
                        direction = MekuriDirection.LeftToRight,
                        configuration = MekuriConfiguration(),
                        modifier = Modifier.fillMaxSize(),
                    )
                    MekuriFoldedLeaf(
                        progress = { 0.30f },
                        direction = MekuriDirection.LeftToRight,
                        configuration = MekuriConfiguration(),
                        modifier = Modifier.fillMaxSize(),
                        back = { MekuriHarnessPage("BACK", Color(0xFF7A2E1E), Color(0xFFFFE9D6)) },
                        front = { MekuriHarnessPage("FRONT", Color(0xFFF4EFE4), Color(0xFF2B2118)) },
                    )
                }
            }
        }
        rule.onNodeWithTag(SCENE_TAG).captureToImage().saveScene("03-leaf-shadow")
    }

    @Test
    fun aRightToLeftTurnMirrorsTheSameFold() {
        rule.setContent {
            MekuriScene(width = LEAF_WIDTH, height = PAGE_HEIGHT) {
                MekuriFoldedLeaf(
                    progress = { 0.55f },
                    direction = MekuriDirection.RightToLeft,
                    configuration = MekuriConfiguration(),
                    modifier = Modifier.fillMaxSize(),
                    back = { MekuriHarnessPage("BACK", Color(0xFF7A2E1E), Color(0xFFFFE9D6)) },
                    front = { MekuriHarnessPage("FRONT", Color(0xFFF4EFE4), Color(0xFF2B2118)) },
                )
            }
        }
        rule.onNodeWithTag(SCENE_TAG).captureToImage().saveScene("04-right-to-left")
    }

    /** The progress must move and come back, or nothing redraws between captures. */
    @Test
    fun theSameSceneRendersIdenticallyAfterATurnAndBack() {
        val progress = mutableFloatStateOf(SETTLED_PROGRESS)
        rule.setContent {
            MekuriScene(width = PAGE_WIDTH, height = PAGE_HEIGHT) {
                MekuriFoldedPage(
                    progress = { progress.floatValue },
                    direction = MekuriDirection.LeftToRight,
                    configuration = MekuriConfiguration(),
                    modifier = Modifier.fillMaxSize(),
                ) {
                    MekuriHarnessPage("FRONT", Color(0xFFF4EFE4), Color(0xFF2B2118))
                }
            }
        }
        val first = rule.onNodeWithTag(SCENE_TAG).captureToImage().pixels()
        val moved = rule.captureAt(progress, 0.62f)
        assertNotEquals(0, countDifferences(first, moved))
        val second = rule.captureAt(progress, SETTLED_PROGRESS)
        assertEquals(0, countDifferences(first, second))
    }
}

@Composable
private fun MekuriScene(
    width: androidx.compose.ui.unit.Dp,
    height: androidx.compose.ui.unit.Dp,
    content: @Composable () -> Unit,
) {
    Box(Modifier.fillMaxSize().drawBehind { drawRect(Color(0xFF3B4250)) }, Alignment.Center) {
        Box(
            Modifier
                .width(width)
                .height(height)
                .testTag(SCENE_TAG)
                .drawBehind { drawRect(Color(0xFFDCE1E8)) },
        ) {
            content()
        }
    }
}

private fun ComposeContentTestRule.captureAt(progress: MutableFloatState, value: Float): IntArray {
    runOnIdle { progress.floatValue = value }
    waitForIdle()
    return onNodeWithTag(SCENE_TAG).captureToImage().pixels()
}

private const val SETTLED_PROGRESS = 0.15f
private val PAGE_WIDTH = 240.dp
private val LEAF_WIDTH = 340.dp
private val PAGE_HEIGHT = 420.dp
