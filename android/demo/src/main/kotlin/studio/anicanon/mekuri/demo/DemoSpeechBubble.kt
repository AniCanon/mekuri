package studio.anicanon.mekuri.demo

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import kotlin.math.cos
import kotlin.math.sin

/** Where a bubble's tail points, as a fraction of the bubble's own width. */
enum class DemoBubbleTail {
    BottomLeading,
    BottomTrailing,
    TopLeading,
    None,
}

/** Speech text in a bubble. [size] scales the type with the page. */
@Composable
fun DemoSpeechBubble(
    text: String,
    modifier: Modifier = Modifier,
    tail: DemoBubbleTail = DemoBubbleTail.BottomLeading,
    size: Float = 15f,
) {
    Box(
        modifier
            .drawBehind {
                val path = bubblePath(Rect(Offset.Zero, this.size), tail)
                drawPath(path, DemoInk.Paper)
                drawPath(path, DemoInk.Ink, style = Stroke(width = 2.5f))
            }
            .padding(horizontal = (size * 1.4f).dp, vertical = (size * 1.5f).dp),
    ) {
        BasicText(text = text, style = DemoInk.speech(size).copy(textAlign = TextAlign.Center))
    }
}

/** Sound-effect lettering, optionally inside a burst. */
@Composable
fun DemoSoundEffect(
    text: String,
    modifier: Modifier = Modifier,
    size: Float = 40f,
    burst: Boolean = false,
) {
    val padded = if (burst) {
        modifier
            .drawBehind {
                val path = burstPath(Rect(Offset.Zero, this.size))
                drawPath(path, DemoInk.Paper)
                drawPath(path, DemoInk.Ink, style = Stroke(width = 3f))
            }
            .padding(horizontal = (size * 0.9f).dp, vertical = (size * 0.7f).dp)
    } else {
        modifier
    }
    BasicText(text = text, modifier = padded, style = DemoInk.sfx(size))
}

/**
 * An ellipse with a tail. The tail is part of the same path; the stroke runs
 * around the outside only.
 */
private fun bubblePath(rect: Rect, tail: DemoBubbleTail): Path {
    val inset = 12f
    val body = Rect(rect.left, rect.top + inset, rect.right, rect.bottom - inset)
    val path = Path().apply { addOval(body) }
    when (tail) {
        DemoBubbleTail.None -> Unit
        DemoBubbleTail.BottomLeading -> path.addTail(
            from = Offset(body.left + body.width * 0.30f, body.bottom - 6f),
            tip = Offset(body.left + body.width * 0.12f, rect.bottom),
            toward = Offset(body.left + body.width * 0.45f, body.bottom - 4f),
        )
        DemoBubbleTail.BottomTrailing -> path.addTail(
            from = Offset(body.right - body.width * 0.30f, body.bottom - 6f),
            tip = Offset(body.right - body.width * 0.12f, rect.bottom),
            toward = Offset(body.right - body.width * 0.45f, body.bottom - 4f),
        )
        DemoBubbleTail.TopLeading -> path.addTail(
            from = Offset(body.left + body.width * 0.30f, body.top + 6f),
            tip = Offset(body.left + body.width * 0.12f, rect.top),
            toward = Offset(body.left + body.width * 0.45f, body.top + 4f),
        )
    }
    return path
}

private fun Path.addTail(from: Offset, tip: Offset, toward: Offset) {
    moveTo(from.x, from.y)
    lineTo(tip.x, tip.y)
    lineTo(toward.x, toward.y)
    close()
}

/** A jagged burst for a sound effect. */
private fun burstPath(rect: Rect, points: Int = 14, depth: Float = 0.22f): Path {
    val path = Path()
    val centerX = rect.center.x
    val centerY = rect.center.y
    val outerX = rect.width / 2
    val outerY = rect.height / 2
    for (index in 0 until points * 2) {
        val angle = index.toFloat() / (points * 2).toFloat() * Math.PI.toFloat() * 2f - Math.PI.toFloat() / 2f
        val scale = if (index % 2 == 0) 1f else 1f - depth
        val x = centerX + cos(angle) * outerX * scale
        val y = centerY + sin(angle) * outerY * scale
        if (index == 0) path.moveTo(x, y) else path.lineTo(x, y)
    }
    path.close()
    return path
}
