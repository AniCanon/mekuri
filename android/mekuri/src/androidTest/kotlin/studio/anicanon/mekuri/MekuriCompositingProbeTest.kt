package studio.anicanon.mekuri

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableIntStateOf
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
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * The same fold over a page of N draw-modifier nodes, and over a page of N
 * children that each carry their own graphics layer, must differ by zero pixels
 * between N = 1 and N = 8. The control that stacks two shadow passes must
 * differ by more than zero.
 */
@RunWith(AndroidJUnit4::class)
class MekuriCompositingProbeTest {

    @get:Rule
    val rule = createComposeRule()

    @Test
    fun theFoldIsIndependentOfTheNumberOfDrawingNodes() {
        val count = mutableIntStateOf(1)
        rule.setFoldOverStackedPage { MekuriStackedPage(count.intValue, STACK_GROUND) }
        assertEquals(0, rule.differenceAcrossNodeCount(count))
    }

    @Test
    fun theFoldIsIndependentOfTheNumberOfLayeredChildren() {
        val count = mutableIntStateOf(1)
        rule.setFoldOverStackedPage { MekuriLayeredStackedPage(count.intValue, STACK_GROUND) }
        assertEquals(0, rule.differenceAcrossNodeCount(count))
    }

    @Test
    fun aSecondShadowPassIsVisibleToTheSameMeasurement() {
        val count = mutableIntStateOf(1)
        rule.setContent {
            MekuriProbeScene {
                MekuriStackedPage(1, Color.White)
                repeat(count.intValue) {
                    MekuriLeafShadow(
                        progress = { PROBE_PROGRESS },
                        direction = MekuriDirection.LeftToRight,
                        configuration = MekuriConfiguration(),
                        modifier = Modifier.fillMaxSize(),
                    )
                }
            }
        }
        assertTrue(rule.differenceAcrossNodeCount(count, second = 2) > 0)
    }
}

@Composable
private fun MekuriProbeScene(content: @Composable () -> Unit) {
    Box(Modifier.fillMaxSize().drawBehind { drawRect(Color.White) }, Alignment.Center) {
        Box(
            Modifier
                .width(240.dp)
                .height(420.dp)
                .testTag(SCENE_TAG)
                .drawBehind { drawRect(Color.White) },
        ) {
            content()
        }
    }
}

private fun ComposeContentTestRule.setFoldOverStackedPage(page: @Composable () -> Unit) {
    setContent {
        MekuriProbeScene {
            MekuriFoldedPage(
                progress = { PROBE_PROGRESS },
                direction = MekuriDirection.LeftToRight,
                configuration = MekuriConfiguration(),
                modifier = Modifier.fillMaxSize(),
                content = page,
            )
        }
    }
}

private fun ComposeContentTestRule.differenceAcrossNodeCount(
    count: androidx.compose.runtime.MutableIntState,
    second: Int = 8,
): Int {
    val first = onNodeWithTag(SCENE_TAG).captureToImage().pixels()
    runOnIdle { count.intValue = second }
    waitForIdle()
    val stacked = onNodeWithTag(SCENE_TAG).captureToImage().pixels()
    return countDifferences(first, stacked)
}

private val STACK_GROUND = Color(0xFF6E8FB8)
private const val PROBE_PROGRESS = 0.40f
