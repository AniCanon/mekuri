package app.mekuri.demo

import androidx.compose.foundation.Canvas
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.drawscope.DrawScope
import kotlin.math.cos
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

/** Screen tone: a dot grid whose dots grow toward the bottom of the area. */
fun DrawScope.drawHalftone(spacing: Float, opacity: Float) {
    val columns = (this.size.width / spacing).toInt() + 1
    val rows = (this.size.height / spacing).toInt() + 1
    for (row in 0 until rows) {
        val growth = row.toFloat() / max(rows - 1, 1).toFloat()
        val radius = 0.6f + growth * (spacing * 0.42f)
        val stagger = if (row % 2 == 0) 0f else spacing / 2
        for (column in 0 until columns) {
            drawCircle(
                color = DemoInk.Ink.copy(alpha = opacity),
                radius = radius,
                center = Offset(column * spacing + stagger, row * spacing),
            )
        }
    }
}

/** Speed lines radiating from a focus point, leaving a clear disc around it. */
fun DrawScope.drawSpeedLines(
    focusX: Float,
    focusY: Float,
    count: Int,
    clearRadius: Float,
) {
    val center = Offset(focusX * this.size.width, focusY * this.size.height)
    val reach = hypot(this.size.width, this.size.height)
    val clear = clearRadius * min(this.size.width, this.size.height)
    for (index in 0 until count) {
        val angle = index.toFloat() / count.toFloat() * Math.PI.toFloat() * 2f
        val jitter = ((index * 37) % 11).toFloat() / 11f
        val start = clear * (1f + jitter * 0.6f)
        val width = 0.8f + jitter * 2.2f
        drawLine(
            color = DemoInk.Ink,
            start = Offset(center.x + cos(angle) * start, center.y + sin(angle) * start),
            end = Offset(center.x + cos(angle) * reach, center.y + sin(angle) * reach),
            strokeWidth = width,
        )
    }
}

/** Horizontal scanlines for a panel that reads as a screen. */
fun DrawScope.drawScanlines(spacing: Float) {
    var y = 0f
    while (y < this.size.height) {
        drawRect(
            color = DemoInk.Ink.copy(alpha = 0.10f),
            topLeft = Offset(0f, y),
            size = Size(this.size.width, 1f),
        )
        y += spacing
    }
}

@Composable
fun DemoHalftone(modifier: Modifier = Modifier, spacing: Float = 9f, opacity: Float = 0.55f) {
    Canvas(modifier) { drawHalftone(spacing, opacity) }
}

@Composable
fun DemoSpeedLines(
    modifier: Modifier = Modifier,
    focusX: Float = 0.5f,
    focusY: Float = 0.5f,
    count: Int = 72,
    clearRadius: Float = 0.22f,
) {
    Canvas(modifier) { drawSpeedLines(focusX, focusY, count, clearRadius) }
}

@Composable
fun DemoScanlines(modifier: Modifier = Modifier, spacing: Float = 4f) {
    Canvas(modifier) { drawScanlines(spacing) }
}
