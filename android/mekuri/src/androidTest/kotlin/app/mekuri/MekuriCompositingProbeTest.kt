package app.mekuri

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.unit.dp
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Assert.assertEquals
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * The shader's translucent output must composite once however many drawing
 * nodes the page holds, or the contact shadow's darkness depends on the
 * consumer's content. Same fold over a page of one node and of eight.
 */
@RunWith(AndroidJUnit4::class)
class MekuriCompositingProbeTest {

    @get:Rule
    val rule = createComposeRule()

    @Test
    fun theFoldIsIndependentOfTheNumberOfDrawingNodes() {
        val nodeCount = mutableIntStateOf(1)
        rule.setContent {
            Box(Modifier.fillMaxSize().drawBehind { drawRect(Color.White) }, Alignment.Center) {
                Box(
                    Modifier
                        .width(240.dp)
                        .height(420.dp)
                        .testTag(SCENE_TAG)
                        .drawBehind { drawRect(Color.White) },
                ) {
                    MekuriFoldedPage(
                        progress = { 0.40f },
                        direction = MekuriDirection.LeftToRight,
                        configuration = MekuriConfiguration(),
                        modifier = Modifier.fillMaxSize(),
                    ) {
                        MekuriStackedPage(nodeCount.intValue, Color(0xFF6E8FB8))
                    }
                }
            }
        }
        val single = rule.onNodeWithTag(SCENE_TAG).captureToImage().pixels()
        rule.runOnIdle { nodeCount.intValue = 8 }
        rule.waitForIdle()
        val stacked = rule.onNodeWithTag(SCENE_TAG).captureToImage().pixels()
        assertEquals(0, countDifferences(single, stacked))
    }
}
