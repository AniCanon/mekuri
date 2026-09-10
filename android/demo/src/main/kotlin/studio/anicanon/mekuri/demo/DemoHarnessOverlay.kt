package studio.anicanon.mekuri.demo

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import studio.anicanon.mekuri.LocalMekuriPageMode
import studio.anicanon.mekuri.MekuriPageMode

/**
 * Letters along each edge naming which edge is lifting, and a button in the
 * centre zone that must win over the centre tap. Hidden in presentation mode.
 */
@Composable
fun DemoHarnessOverlay(tapCount: Int, onButtonTap: () -> Unit) {
    val turning = LocalMekuriPageMode.current == MekuriPageMode.Turning
    Box(Modifier.fillMaxSize()) {
        Row(Modifier.fillMaxSize(), horizontalArrangement = Arrangement.SpaceBetween) {
            DemoEdgeMarker("L")
            DemoEdgeMarker("R")
        }
        Box(
            Modifier
                .align(Alignment.Center)
                .clip(RoundedCornerShape(percent = 50))
                .background(DemoInk.Ink)
                .clickable(enabled = !turning, onClick = onButtonTap)
                .padding(horizontal = 28.dp, vertical = 14.dp),
        ) {
            BasicText(
                "Tap me · $tapCount",
                style = DemoInk.label(20f).copy(color = DemoInk.Paper),
            )
        }
    }
}

@Composable
private fun DemoEdgeMarker(letter: String) {
    Column(
        Modifier
            .width(44.dp)
            .fillMaxHeight()
            .background(DemoInk.Ink.copy(alpha = 0.10f)),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.SpaceEvenly,
    ) {
        repeat(7) {
            BasicText(letter, style = markerStyle)
        }
    }
}

private val markerStyle = TextStyle(
    fontSize = 26.sp,
    fontWeight = FontWeight.Black,
    fontFamily = FontFamily.Monospace,
    color = DemoInk.Ink.copy(alpha = 0.5f),
)
