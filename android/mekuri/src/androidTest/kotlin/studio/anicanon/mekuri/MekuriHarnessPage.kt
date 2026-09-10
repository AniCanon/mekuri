package studio.anicanon.mekuri

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.sp

/** A page with a legible identity: a ground colour, ruled bars and a label. */
@Composable
fun MekuriHarnessPage(
    label: String,
    ground: Color,
    ink: Color,
    barCount: Int = 9,
) {
    Box(Modifier.fillMaxSize().drawBehind {
        drawRect(ground)
        val pitch = size.height / (barCount * 2f + 1f)
        for (bar in 0 until barCount) {
            drawRect(
                color = ink.copy(alpha = 0.28f),
                topLeft = Offset(size.width * 0.08f, pitch * (bar * 2f + 1f)),
                size = Size(size.width * 0.84f, pitch),
            )
        }
        drawRect(color = ink, size = Size(size.width, size.height * 0.012f))
    }, contentAlignment = Alignment.Center) {
        BasicText(
            text = label,
            style = TextStyle(color = ink, fontSize = 34.sp, textAlign = TextAlign.Center),
        )
    }
}

/** A page made of [count] stacked opaque draw nodes of one colour. */
@Composable
fun MekuriStackedPage(count: Int, ground: Color) {
    Box(Modifier.fillMaxSize()) {
        repeat(count) {
            Box(Modifier.fillMaxSize().drawBehind { drawRect(ground) })
        }
    }
}

/**
 * The same page with each child on its own offscreen, clipped graphics layer.
 * The children must stay opaque and one colour: the drawn pixels are invariant
 * in [count], the render node count is not.
 */
@Composable
fun MekuriLayeredStackedPage(count: Int, ground: Color) {
    Box(Modifier.fillMaxSize()) {
        repeat(count) {
            Box(
                Modifier
                    .fillMaxSize()
                    .graphicsLayer {
                        compositingStrategy = CompositingStrategy.Offscreen
                        clip = true
                    }
                    .drawBehind { drawRect(ground) },
            )
        }
    }
}
