package studio.anicanon.mekuri.demo

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.runtime.saveable.Saver
import androidx.compose.runtime.saveable.listSaver
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import studio.anicanon.mekuri.MekuriDirection
import studio.anicanon.mekuri.MekuriSpread

/** State the controls read and write. */
data class DemoControls(
    val direction: MekuriDirection,
    val pagingEnabled: Boolean,
    val slowTurns: Boolean,
    val spread: MekuriSpread,
    val coverStandsAlone: Boolean,
    val presentation: Boolean,
)

/** Carries the controls across the activity recreation a rotation causes. */
val DemoControlsSaver: Saver<DemoControls, Any> = listSaver(
    save = {
        listOf(
            it.direction.name,
            it.pagingEnabled,
            it.slowTurns,
            it.spread.name,
            it.coverStandsAlone,
            it.presentation,
        )
    },
    restore = {
        DemoControls(
            direction = MekuriDirection.valueOf(it[0] as String),
            pagingEnabled = it[1] as Boolean,
            slowTurns = it[2] as Boolean,
            spread = MekuriSpread.valueOf(it[3] as String),
            coverStandsAlone = it[4] as Boolean,
            presentation = it[5] as Boolean,
        )
    },
)

/** Floating control card the centre tap shows and hides. */
@Composable
fun DemoControlPanel(
    controls: DemoControls,
    currentPage: Int,
    pageCount: Int,
    onControls: (DemoControls) -> Unit,
    onPage: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        // Never a fixed width: the card plus its outer padding must fit a
        // 360 dp phone.
        modifier
            .widthIn(max = 340.dp)
            .fillMaxWidth()
            .clip(RoundedCornerShape(24.dp))
            .background(Color(0.16f, 0.16f, 0.16f, 0.94f))
            .border(1.dp, Color.White.copy(alpha = 0.18f), RoundedCornerShape(24.dp))
            // Must scroll: the full card does not fit a phone's landscape height.
            .verticalScroll(rememberScrollState())
            .padding(18.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            BasicText("Mekuri", style = panelTitle)
            Box(Modifier.weight(1f))
            if (!controls.presentation) {
                BasicText("Page ${currentPage + 1} of $pageCount", style = panelText)
            }
        }
        DemoStepperRow(
            label = "Page ${currentPage + 1}",
            onBack = { onPage((currentPage - 1).coerceAtLeast(0)) },
            onForward = { onPage((currentPage + 1).coerceAtMost(pageCount - 1)) },
        )
        DemoPillRow("Right to left", controls.direction == MekuriDirection.RightToLeft) {
            onControls(
                controls.copy(
                    direction = if (controls.direction == MekuriDirection.RightToLeft) {
                        MekuriDirection.LeftToRight
                    } else {
                        MekuriDirection.RightToLeft
                    },
                ),
            )
        }
        DemoPillRow("Paging enabled", controls.pagingEnabled) {
            onControls(controls.copy(pagingEnabled = !controls.pagingEnabled))
        }
        DemoPillRow("Slow turns", controls.slowTurns) {
            onControls(controls.copy(slowTurns = !controls.slowTurns))
        }
        DemoPillRow(
            title = "Spread",
            on = controls.spread != MekuriSpread.Single,
            label = controls.spread.name.uppercase(),
        ) {
            onControls(controls.copy(spread = controls.spread.next()))
        }
        DemoPillRow("Cover stands alone", controls.coverStandsAlone) {
            onControls(controls.copy(coverStandsAlone = !controls.coverStandsAlone))
        }
        DemoPillRow("Presentation", controls.presentation) {
            onControls(controls.copy(presentation = !controls.presentation))
        }
    }
}

@Composable
private fun DemoStepperRow(label: String, onBack: () -> Unit, onForward: () -> Unit) {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        BasicText(label, style = panelText)
        Box(Modifier.weight(1f))
        DemoStepperButton("−", onBack)
        Box(Modifier.width(8.dp))
        DemoStepperButton("+", onForward)
    }
}

@Composable
private fun DemoStepperButton(glyph: String, onClick: () -> Unit) {
    Box(
        Modifier
            .clip(RoundedCornerShape(8.dp))
            .background(Color.White.copy(alpha = 0.18f))
            .clickable(onClick = onClick)
            .defaultMinSize(minWidth = 54.dp, minHeight = 34.dp),
        contentAlignment = Alignment.Center,
    ) {
        BasicText(glyph, style = pillOff)
    }
}

@Composable
private fun DemoPillRow(
    title: String,
    on: Boolean,
    label: String = if (on) "ON" else "OFF",
    onClick: () -> Unit,
) {
    Row(
        Modifier.fillMaxWidth().clickable(onClick = onClick),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        BasicText(title, style = panelText)
        Box(Modifier.weight(1f))
        Box(
            Modifier
                .clip(RoundedCornerShape(percent = 50))
                .background(if (on) Color(0.20f, 0.72f, 0.35f) else Color(0.45f, 0.45f, 0.45f))
                .defaultMinSize(minWidth = 64.dp, minHeight = 30.dp)
                .padding(horizontal = 8.dp),
            contentAlignment = Alignment.Center,
        ) {
            BasicText(
                label,
                style = if (on) pillOn else pillOff,
            )
        }
    }
}

private fun MekuriSpread.next(): MekuriSpread = when (this) {
    MekuriSpread.Automatic -> MekuriSpread.Single
    MekuriSpread.Single -> MekuriSpread.Double
    MekuriSpread.Double -> MekuriSpread.Automatic
}

private val panelTitle = DemoInk.title(20f).copy(color = Color.White)
private val panelText = DemoInk.label(16f).copy(color = Color.White)
private val pillOn = DemoInk.sfx(13f).copy(color = Color.Black, textAlign = TextAlign.Center)
private val pillOff = DemoInk.sfx(13f).copy(color = Color.White, textAlign = TextAlign.Center)
