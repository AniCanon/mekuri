package studio.anicanon.mekuri.demo

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.geometry.Rect

/**
 * One bordered panel: paper behind the content, the content clipped to the
 * panel, the ink border drawn over both.
 */
@Composable
fun DemoPanel(modifier: Modifier = Modifier, content: @Composable BoxScope.() -> Unit) {
    Box(
        modifier
            .background(DemoInk.Paper)
            .clipToBounds()
            .border(DemoInk.PanelStroke, DemoInk.Ink),
        content = content,
    )
}

/**
 * Lays out panels from unit-square frames inside the page margin, each inset by
 * half a gutter so neighbours sit a full gutter apart.
 */
@Composable
fun DemoPanelGrid(frames: List<Rect>, panel: @Composable (Int) -> Unit) {
    BoxWithConstraints(Modifier.fillMaxSize().padding(DemoInk.Margin)) {
        val area = this.maxWidth to this.maxHeight
        val half = DemoInk.Gutter / 2
        frames.forEachIndexed { index, unit ->
            Box(
                Modifier
                    .offset(x = area.first * unit.left + half, y = area.second * unit.top + half)
                    .size(
                        width = area.first * unit.width - DemoInk.Gutter,
                        height = area.second * unit.height - DemoInk.Gutter,
                    ),
            ) {
                panel(index)
            }
        }
    }
}
