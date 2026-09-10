package studio.anicanon.mekuri.demo

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.BiasAlignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp

/**
 * The cover: one full panel with the title over a skyline, and a small inset
 * panel for the broadcast.
 */
@Composable
fun DemoTitlePage(scale: Float) {
    DemoPanelGrid(frames = listOf(Rect(0f, 0f, 1f, 1f))) {
        DemoPanel(Modifier.fillMaxSize()) {
            BoxWithConstraints(Modifier.fillMaxSize()) {
                val width = this.maxWidth
                val height = this.maxHeight
                DemoMoon(
                    Modifier
                        .size(width * 0.42f)
                        .align(BiasAlignment(horizontalBias = 0.4f, verticalBias = -0.52f)),
                )
                DemoSkyline(
                    Modifier
                        .fillMaxWidth()
                        .height(height * 0.30f)
                        .align(Alignment.BottomStart),
                )
                Column(
                    Modifier
                        .align(verticalBias(0.60f))
                        .background(DemoInk.Paper)
                        .border(DemoInk.PanelStroke, DemoInk.Ink)
                        .padding(horizontal = (20 * scale).dp, vertical = (14 * scale).dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy((6 * scale).dp),
                ) {
                    BasicText("Chapter One", style = DemoInk.narration(16 * scale))
                    BasicText(
                        "MEKURI",
                        style = DemoInk.title(58 * scale).copy(textAlign = TextAlign.Center),
                    )
                    BasicText(
                        "the page turns the way paper does",
                        style = DemoInk.narration(14 * scale).copy(textAlign = TextAlign.Center),
                    )
                }
                Box(
                    Modifier
                        .align(Alignment.BottomStart)
                        .background(DemoInk.Paper)
                        .border(DemoInk.PanelStroke, DemoInk.Ink)
                        .padding((10 * scale).dp),
                ) {
                    DemoBroadcastPanel(size = 13 * scale)
                }
            }
        }
    }
}
