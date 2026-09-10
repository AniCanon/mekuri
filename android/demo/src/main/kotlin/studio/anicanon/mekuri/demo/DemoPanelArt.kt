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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.BiasAlignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp

/** What is drawn inside a panel, behind its bubble and sound effect. */
sealed interface DemoPanelArt {
    data object Blank : DemoPanelArt
    data object Broadcast : DemoPanelArt
    data class Figure(val pose: DemoPose, val tone: Boolean) : DemoPanelArt
    data object Skyline : DemoPanelArt
    data object Moon : DemoPanelArt
    data class Speed(val pose: DemoPose?) : DemoPanelArt
    data object Ending : DemoPanelArt
}

data class DemoBubbleSpec(
    val text: String,
    val tail: DemoBubbleTail = DemoBubbleTail.BottomLeading,
    val anchorY: Float = 0.25f,
)

data class DemoSoundSpec(
    val text: String,
    val anchorY: Float = 0.5f,
    val burst: Boolean = false,
)

data class DemoPanelSpec(
    val frame: Rect,
    val art: DemoPanelArt = DemoPanelArt.Blank,
    val caption: String? = null,
    val bubble: DemoBubbleSpec? = null,
    val sound: DemoSoundSpec? = null,
)

/** Renders one panel spec. [scale] is the page's type scale. */
@Composable
fun DemoPanelView(spec: DemoPanelSpec, scale: Float) {
    DemoPanel(Modifier.fillMaxSize()) {
        BoxWithConstraints(Modifier.fillMaxSize()) {
            val width = this.maxWidth
            DemoPanelArtView(spec.art, scale)
            spec.bubble?.let { bubble ->
                DemoSpeechBubble(
                    text = bubble.text,
                    modifier = Modifier
                        .width(width * 0.82f)
                        .align(verticalBias(bubble.anchorY)),
                    tail = bubble.tail,
                    size = 14 * scale,
                )
            }
            spec.sound?.let { sound ->
                DemoSoundEffect(
                    text = sound.text,
                    modifier = Modifier.align(verticalBias(sound.anchorY)),
                    size = 34 * scale,
                    burst = sound.burst,
                )
            }
            spec.caption?.let { caption ->
                DemoCaption(caption, size = 12 * scale, modifier = Modifier.align(Alignment.TopStart))
            }
        }
    }
}

@Composable
private fun DemoPanelArtView(art: DemoPanelArt, scale: Float) {
    BoxWithConstraints(Modifier.fillMaxSize()) {
        val height = this.maxHeight
        val width = this.maxWidth
        when (art) {
            DemoPanelArt.Blank -> Unit
            DemoPanelArt.Broadcast -> DemoBroadcastPanel(
                size = 15 * scale,
                modifier = Modifier.align(Alignment.Center),
            )
            is DemoPanelArt.Figure -> {
                if (art.tone) {
                    DemoHalftone(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(height * 0.45f)
                            .align(Alignment.BottomStart),
                        spacing = 8 * scale,
                        opacity = 0.30f,
                    )
                }
                DemoFigure(
                    pose = art.pose,
                    modifier = Modifier
                        .size(width = height * 0.5f, height = height * 0.62f)
                        .align(Alignment.BottomCenter)
                        .padding(bottom = height * 0.05f),
                )
            }
            DemoPanelArt.Skyline -> DemoSkyline(Modifier.fillMaxSize())
            DemoPanelArt.Moon -> DemoMoon(Modifier.fillMaxSize().padding(width * 0.12f))
            is DemoPanelArt.Speed -> {
                DemoSpeedLines(
                    modifier = Modifier.fillMaxSize(),
                    focusY = 0.55f,
                    clearRadius = 0.3f,
                )
                art.pose?.let { pose ->
                    DemoFigure(
                        pose = pose,
                        modifier = Modifier
                            .size(width = height * 0.5f, height = height * 0.55f)
                            .align(Alignment.Center),
                    )
                }
            }
            DemoPanelArt.Ending -> Column(
                Modifier.fillMaxSize().wrapContentSize(Alignment.Center),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy((8 * scale).dp),
            ) {
                BasicText("THE END", style = DemoInk.title(26 * scale))
                BasicText("turn back to begin again", style = DemoInk.narration(11 * scale))
            }
        }
    }
}

/** Boxed narration in a panel's corner. */
@Composable
fun DemoCaption(text: String, size: Float, modifier: Modifier = Modifier) {
    Box(
        modifier
            .background(DemoInk.Paper)
            .border(DemoInk.BubbleStroke, DemoInk.Ink)
            .padding(horizontal = (size * 0.8f).dp, vertical = (size * 0.5f).dp),
    ) {
        BasicText(text, style = DemoInk.narration(size).copy(textAlign = TextAlign.Start))
    }
}

/** Centres the child horizontally and at [fraction] of the parent's height. */
fun verticalBias(fraction: Float): Alignment =
    BiasAlignment(horizontalBias = 0f, verticalBias = fraction * 2f - 1f)
