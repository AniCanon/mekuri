package app.mekuri.demo

import androidx.compose.foundation.Canvas
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipPath
import kotlin.math.max
import kotlin.math.min

/** A row of buildings along the bottom of its area, with lit windows. */
@Composable
fun DemoSkyline(modifier: Modifier = Modifier) {
    Canvas(modifier) {
        var x = 0f
        var seed = 7L
        while (x < size.width) {
            seed = (seed * 1103515245 + 12345) % 2147483648L
            val width = size.width * (0.06f + (seed % 9).toFloat() / 100f)
            val height = size.height * (0.25f + ((seed / 9) % 45).toFloat() / 100f)
            val top = size.height - height
            drawRect(DemoInk.Ink, topLeft = Offset(x, top), size = Size(width, height))
            val pane = max(3f, width * 0.16f)
            var windowY = top + pane
            while (windowY + pane < size.height) {
                var windowX = x + pane
                while (windowX + pane < x + width) {
                    seed = (seed * 1103515245 + 12345) % 2147483648L
                    if (seed % 3 != 0L) {
                        drawRect(
                            DemoInk.Paper,
                            topLeft = Offset(windowX, windowY),
                            size = Size(pane * 0.7f, pane * 0.9f),
                        )
                    }
                    windowX += pane * 1.6f
                }
                windowY += pane * 1.8f
            }
            x += width + max(2f, width * 0.12f)
        }
        drawRect(DemoInk.Ink, topLeft = Offset(0f, size.height - 3f), size = Size(size.width, 3f))
    }
}

/** A moon: an ink ring with a toned crescent. */
@Composable
fun DemoMoon(modifier: Modifier = Modifier) {
    Canvas(modifier) {
        val side = min(size.width, size.height)
        val center = Offset(size.width / 2, size.height / 2)
        val radius = side / 2
        drawCircle(DemoInk.Paper, radius = radius, center = center)
        clipPath(circlePath(center, radius)) {
            drawHalftone(max(6f, side * 0.045f), 0.45f)
        }
        drawCircle(
            color = DemoInk.Paper,
            radius = radius,
            center = Offset(center.x - side * 0.28f, center.y - side * 0.1f),
        )
        drawCircle(
            color = DemoInk.Ink,
            radius = radius,
            center = center,
            style = Stroke(width = 3f),
        )
    }
}

/** A mountain range along the bottom of its area, filled with tone. */
@Composable
fun DemoMountains(modifier: Modifier = Modifier) {
    Canvas(modifier) {
        val peaks = listOf(
            0.00f to 0.70f, 0.08f to 0.45f, 0.16f to 0.62f,
            0.27f to 0.28f, 0.36f to 0.55f, 0.44f to 0.40f,
            0.53f to 0.66f, 0.62f to 0.33f, 0.71f to 0.58f,
            0.80f to 0.22f, 0.90f to 0.50f, 1.00f to 0.64f,
        )
        val range = Path().apply {
            moveTo(0f, size.height)
            peaks.forEach { (x, y) -> lineTo(x * size.width, y * size.height) }
            lineTo(size.width, size.height)
            close()
        }
        drawPath(range, DemoInk.Ink.copy(alpha = 0.85f))
        drawPath(range, DemoInk.Ink, style = Stroke(width = 3f))
    }
}

private fun circlePath(center: Offset, radius: Float) = Path().apply {
    addOval(
        Rect(
            left = center.x - radius,
            top = center.y - radius,
            right = center.x + radius,
            bottom = center.y + radius,
        ),
    )
}
