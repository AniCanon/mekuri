package studio.anicanon.mekuri.demo

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameMillis
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.dp
import studio.anicanon.mekuri.LocalMekuriPageMode
import studio.anicanon.mekuri.MekuriPageMode
import java.util.Calendar
import kotlin.math.abs
import kotlin.math.sin

/**
 * Pulsing dot and running clock. The tick is owned here; nothing above this
 * composable may recompose with it.
 */
@Composable
fun DemoLiveIndicator(size: Float) {
    var now by remember { mutableLongStateOf(System.currentTimeMillis()) }
    LaunchedEffect(Unit) {
        while (true) {
            withFrameMillis { now = System.currentTimeMillis() }
        }
    }
    val phase = (now % 1000L).toFloat() / 1000f
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy((size * 0.5f).dp),
    ) {
        Canvas(Modifier.size((size * 0.7f).dp)) {
            val pulse = 0.6f + 0.4f * abs(sin(phase * Math.PI.toFloat()))
            drawCircle(DemoInk.Accent, radius = this.size.minDimension / 2 * pulse)
        }
        BasicText("LIVE", style = DemoInk.sfx(size))
        BasicText(clockText(now), style = DemoInk.label(size))
    }
}

/** Static replacement for the live indicator while the page is turning. */
@Composable
fun DemoFrozenIndicator(size: Float) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy((size * 0.5f).dp),
    ) {
        Canvas(Modifier.size((size * 0.7f).dp)) {
            drawCircle(DemoInk.Ink, radius = this.size.minDimension / 2 - 1f, style = Stroke(2f))
        }
        BasicText("TURNING", style = DemoInk.sfx(size))
        BasicText("--:--:--", style = DemoInk.label(size))
    }
}

/**
 * A television drawn into a panel. Its screen shows the live indicator on a
 * settled page and the frozen one on a turning face.
 */
@Composable
fun DemoBroadcastPanel(size: Float, modifier: Modifier = Modifier) {
    val mode = LocalMekuriPageMode.current
    Column(modifier, horizontalAlignment = Alignment.CenterHorizontally) {
        Canvas(
            Modifier
                .size(width = (size * 3).dp, height = (size * 1.4f).dp),
        ) {
            val stroke = Stroke(width = 2.5f, cap = StrokeCap.Round)
            drawLine(
                DemoInk.Ink,
                Offset(this.size.width / 2, this.size.height),
                Offset(this.size.width * 0.1f, 0f),
                strokeWidth = stroke.width,
                cap = stroke.cap,
            )
            drawLine(
                DemoInk.Ink,
                Offset(this.size.width / 2, this.size.height),
                Offset(this.size.width * 0.9f, 0f),
                strokeWidth = stroke.width,
                cap = stroke.cap,
            )
        }
        Box(
            Modifier
                .background(DemoInk.Paper)
                .border(DemoInk.PanelStroke, DemoInk.Ink),
        ) {
            DemoScanlines(
                modifier = Modifier.matchParentSize(),
                spacing = maxOf(3f, size * 0.22f),
            )
            Column(
                Modifier.padding(horizontal = size.dp, vertical = (size * 0.9f).dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy((size * 0.5f).dp),
            ) {
                BasicText(
                    "ON AIR",
                    style = DemoInk.sfx(size * 0.6f).copy(
                        color = if (mode == MekuriPageMode.Live) DemoInk.Accent else DemoInk.Ink,
                    ),
                )
                when (mode) {
                    MekuriPageMode.Live -> DemoLiveIndicator(size)
                    MekuriPageMode.Turning -> DemoFrozenIndicator(size)
                }
            }
        }
    }
}

private fun clockText(millis: Long): String {
    val calendar = Calendar.getInstance().apply { timeInMillis = millis }
    val hour = calendar.get(Calendar.HOUR_OF_DAY)
    val minute = calendar.get(Calendar.MINUTE)
    val second = calendar.get(Calendar.SECOND)
    return "%02d:%02d:%02d".format(hour, minute, second)
}
