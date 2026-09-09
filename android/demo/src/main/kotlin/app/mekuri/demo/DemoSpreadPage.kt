package app.mekuri.demo

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.BiasAlignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.dp

enum class DemoSpreadHalf {
    Left,
    Right,
}

/**
 * One half of a composition drawn at twice the page width. The two pages of the
 * spread each show their half so the picture runs across the spine.
 */
@Composable
fun DemoSpreadPage(half: DemoSpreadHalf, scale: Float) {
    Layout(
        content = { DemoSpreadComposition(scale) },
        modifier = Modifier.fillMaxSize().clipToBounds(),
    ) { measurables, constraints ->
        val width = constraints.maxWidth
        val height = constraints.maxHeight
        val composition = measurables.first().measure(Constraints.fixed(width * 2, height))
        layout(width, height) {
            composition.place(x = if (half == DemoSpreadHalf.Left) 0 else -width, y = 0)
        }
    }
}

/**
 * The full spread: a moon over mountains straddling the spine, a bubble that
 * crosses it, and a figure and a broadcast on each page.
 */
@Composable
fun DemoSpreadComposition(scale: Float) {
    BoxWithConstraints(
        Modifier
            .fillMaxSize()
            .padding(DemoInk.Margin)
            .background(DemoInk.Paper)
            .clipToBounds()
            .border(DemoInk.PanelStroke, DemoInk.Ink),
    ) {
        val width = this.maxWidth
        val height = this.maxHeight
        DemoSpeedLines(
            modifier = Modifier.fillMaxSize(),
            focusY = 0.38f,
            count = 140,
            clearRadius = 0.36f,
        )
        DemoMoon(
            Modifier
                .size(height * 0.52f)
                .align(verticalBias(0.36f)),
        )
        DemoMountains(
            Modifier
                .fillMaxWidth()
                .height(height * 0.42f)
                .align(Alignment.BottomStart),
        )
        DemoFigure(
            pose = DemoPose.Pointing,
            modifier = Modifier
                .size(width = height * 0.24f, height = height * 0.30f)
                .align(BiasAlignment(horizontalBias = -0.68f, verticalBias = 0.36f)),
        )
        DemoFigure(
            pose = DemoPose.Running,
            modifier = Modifier
                .size(width = height * 0.24f, height = height * 0.30f)
                .align(BiasAlignment(horizontalBias = 0.68f, verticalBias = 0.40f)),
            mirrored = true,
        )
        DemoSpeechBubble(
            text = "Both pages are one leaf.",
            modifier = Modifier
                .width(width * 0.42f)
                .align(verticalBias(0.83f)),
            tail = DemoBubbleTail.None,
            size = 18 * scale,
        )
        DemoCaption(
            "Chapter Two — the spread",
            size = 13 * scale,
            modifier = Modifier.align(Alignment.BottomStart).padding(DemoInk.Margin),
        )
        Box(
            Modifier
                .align(Alignment.TopStart)
                .padding(DemoInk.Margin)
                .background(DemoInk.Paper)
                .border(DemoInk.PanelStroke, DemoInk.Ink)
                .padding((10 * scale).dp),
        ) {
            DemoBroadcastPanel(size = 13 * scale)
        }
        Box(
            Modifier
                .align(Alignment.TopEnd)
                .padding(DemoInk.Margin)
                .background(DemoInk.Paper)
                .border(DemoInk.PanelStroke, DemoInk.Ink)
                .padding((10 * scale).dp),
        ) {
            DemoBroadcastPanel(size = 13 * scale)
        }
        DemoSoundEffect(
            text = "FWIP",
            modifier = Modifier
                .align(BiasAlignment(horizontalBias = -0.40f, verticalBias = -0.48f))
                .rotate(-10f),
            size = 44 * scale,
            burst = true,
        )
    }
}
