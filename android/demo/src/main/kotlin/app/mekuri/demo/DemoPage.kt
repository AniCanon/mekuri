package app.mekuri.demo

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import app.mekuri.MekuriDirection

/**
 * One page: a drawn composition chosen by index, a folio, and the harness
 * affordances when presentation mode is off. [spreadPairStart] is the first of
 * the two pages that share the spanning composition.
 */
@Composable
fun DemoPage(
    index: Int,
    pageCount: Int,
    direction: MekuriDirection,
    spreadPairStart: Int,
    presentation: Boolean,
    tapCount: Int,
    onButtonTap: () -> Unit,
) {
    BoxWithConstraints(Modifier.fillMaxSize().background(DemoInk.Paper)) {
        val scale = minOf(this.maxWidth.value, this.maxHeight.value) / DemoInk.ReferencePage
        when (val kind = pageKind(index, pageCount, direction, spreadPairStart)) {
            DemoPageKind.Title -> DemoTitlePage(scale)
            is DemoPageKind.Spread -> DemoSpreadPage(kind.half, scale)
            is DemoPageKind.Grid -> DemoGridPage(kind.layout, scale)
        }
        Box(Modifier.align(Alignment.BottomCenter).padding(bottom = 2.dp)) {
            BasicText("— ${index + 1} —", style = DemoInk.narration(11 * scale))
        }
        if (!presentation) {
            DemoHarnessOverlay(tapCount = tapCount, onButtonTap = onButtonTap)
        }
    }
}

private sealed interface DemoPageKind {
    data object Title : DemoPageKind
    data class Spread(val half: DemoSpreadHalf) : DemoPageKind
    data class Grid(val layout: DemoPageLayout) : DemoPageKind
}

private fun pageKind(
    index: Int,
    pageCount: Int,
    direction: MekuriDirection,
    spreadPairStart: Int,
): DemoPageKind {
    val leadingHalf =
        if (direction == MekuriDirection.LeftToRight) DemoSpreadHalf.Left else DemoSpreadHalf.Right
    val trailingHalf =
        if (direction == MekuriDirection.LeftToRight) DemoSpreadHalf.Right else DemoSpreadHalf.Left
    return when {
        index == 0 -> DemoPageKind.Title
        index == spreadPairStart -> DemoPageKind.Spread(leadingHalf)
        index == spreadPairStart + 1 -> DemoPageKind.Spread(trailingHalf)
        index == pageCount - 1 -> DemoPageKind.Grid(DemoPageLayout.Ending)
        index % 2 == 0 -> DemoPageKind.Grid(DemoPageLayout.ThreePanel)
        else -> DemoPageKind.Grid(DemoPageLayout.FourGrid)
    }
}
