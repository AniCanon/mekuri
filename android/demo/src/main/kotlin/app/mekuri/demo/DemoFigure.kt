package app.mekuri.demo

import androidx.compose.foundation.Canvas
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.scale

enum class DemoPose {
    Standing,
    Pointing,
    Running,
    Reading,
}

/**
 * A silhouette drawn from a head, a torso and stroked limbs, scaled to the
 * height it is given. [mirrored] flips it about its own centre.
 */
@Composable
fun DemoFigure(pose: DemoPose, modifier: Modifier = Modifier, mirrored: Boolean = false) {
    Canvas(modifier) {
        if (mirrored) {
            scale(scaleX = -1f, scaleY = 1f) { drawFigure(pose) }
        } else {
            drawFigure(pose)
        }
    }
}

private fun DrawScope.drawFigure(pose: DemoPose) {
    val unit = this.size.height
    fun at(x: Float, y: Float) = Offset(this.size.width / 2 + x * unit, y * unit)

    val lean = if (pose == DemoPose.Running) 0.06f else 0f
    val headRadius = unit * 0.10f
    drawCircle(DemoInk.Ink, radius = headRadius, center = at(lean, 0.13f))

    val torso = Path().apply {
        val a = at(-0.10f + lean, 0.26f)
        val b = at(0.10f + lean, 0.26f)
        val c = at(0.08f, 0.58f)
        val d = at(-0.08f, 0.58f)
        moveTo(a.x, a.y)
        lineTo(b.x, b.y)
        lineTo(c.x, c.y)
        lineTo(d.x, d.y)
        close()
    }
    drawPath(torso, DemoInk.Ink)

    val limbs = Path()
    fun segment(x1: Float, y1: Float, x2: Float, y2: Float) {
        val from = at(x1, y1)
        val to = at(x2, y2)
        limbs.moveTo(from.x, from.y)
        limbs.lineTo(to.x, to.y)
    }
    when (pose) {
        DemoPose.Standing -> {
            segment(-0.09f, 0.30f, -0.16f, 0.55f)
            segment(0.09f, 0.30f, 0.16f, 0.55f)
            segment(-0.06f, 0.58f, -0.08f, 0.95f)
            segment(0.06f, 0.58f, 0.08f, 0.95f)
        }
        DemoPose.Pointing -> {
            segment(-0.09f, 0.30f, -0.15f, 0.55f)
            segment(0.09f, 0.30f, 0.36f, 0.30f)
            segment(-0.06f, 0.58f, -0.08f, 0.95f)
            segment(0.06f, 0.58f, 0.10f, 0.95f)
        }
        DemoPose.Running -> {
            segment(-0.04f, 0.30f, -0.24f, 0.42f)
            segment(0.14f, 0.30f, 0.30f, 0.18f)
            segment(-0.06f, 0.58f, -0.30f, 0.82f)
            segment(0.06f, 0.58f, 0.26f, 0.92f)
        }
        DemoPose.Reading -> {
            segment(-0.09f, 0.30f, -0.12f, 0.46f)
            segment(0.09f, 0.30f, 0.12f, 0.46f)
            segment(-0.06f, 0.58f, -0.08f, 0.95f)
            segment(0.06f, 0.58f, 0.08f, 0.95f)
        }
    }
    drawPath(
        limbs,
        DemoInk.Ink,
        style = Stroke(width = unit * 0.075f, cap = StrokeCap.Round, join = StrokeJoin.Round),
    )

    if (pose == DemoPose.Reading) {
        val origin = at(-0.20f, 0.42f)
        val book = Rect(origin, Size(unit * 0.40f, unit * 0.14f))
        drawRect(DemoInk.Paper, topLeft = book.topLeft, size = book.size)
        drawRect(DemoInk.Ink, topLeft = book.topLeft, size = book.size, style = Stroke(unit * 0.025f))
        drawLine(
            DemoInk.Ink,
            start = Offset(book.center.x, book.top),
            end = Offset(book.center.x, book.bottom),
            strokeWidth = unit * 0.02f,
        )
    }
}
