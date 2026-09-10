package studio.anicanon.mekuri.demo

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import studio.anicanon.mekuri.MekuriConfiguration
import studio.anicanon.mekuri.MekuriDirection
import studio.anicanon.mekuri.MekuriPager
import studio.anicanon.mekuri.MekuriSpread
import studio.anicanon.mekuri.rememberMekuriPagerState
import kotlinx.coroutines.launch

private const val PageCount = 6

/** Linear settle duration under the slow-turns control. */
private const val SlowSettleMillis = 4000

@Composable
fun DemoReaderScreen() {
    var controls by rememberSaveable(stateSaver = DemoControlsSaver) {
        mutableStateOf(
            DemoControls(
                direction = MekuriDirection.LeftToRight,
                pagingEnabled = true,
                slowTurns = false,
                spread = MekuriSpread.Automatic,
                coverStandsAlone = true,
                presentation = false,
            ),
        )
    }
    var chromeVisible by rememberSaveable { mutableStateOf(true) }
    val tapCounts = remember { mutableStateMapOf<Int, Int>() }
    val scope = rememberCoroutineScope()
    val state = rememberMekuriPagerState(pageCount = PageCount, direction = controls.direction)
    val configuration = remember(controls.slowTurns) {
        if (controls.slowTurns) {
            MekuriConfiguration(
                settleAnimation = tween(durationMillis = SlowSettleMillis, easing = LinearEasing),
            )
        } else {
            MekuriConfiguration()
        }
    }
    val spreadPairStart = if (controls.coverStandsAlone) 3 else 2

    Box(Modifier.fillMaxSize().background(DemoInk.Backdrop)) {
        MekuriPager(
            state = state,
            modifier = Modifier.fillMaxSize(),
            configuration = configuration,
            pagingEnabled = controls.pagingEnabled,
            onCenterTap = { chromeVisible = !chromeVisible },
            spread = controls.spread,
            coverStandsAlone = controls.coverStandsAlone,
            pageAspectRatio = 2f / 3f,
        ) { index ->
            DemoPage(
                index = index,
                pageCount = PageCount,
                direction = controls.direction,
                spreadPairStart = spreadPairStart,
                presentation = controls.presentation,
                tapCount = tapCounts[index] ?: 0,
                onButtonTap = { tapCounts[index] = (tapCounts[index] ?: 0) + 1 },
            )
        }
        if (chromeVisible) {
            DemoControlPanel(
                controls = controls,
                currentPage = state.currentPage,
                pageCount = PageCount,
                onControls = { next ->
                    if (next.presentation && !controls.presentation) chromeVisible = false
                    controls = next
                },
                onPage = { page -> scope.launch { state.animateToPage(page) } },
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .safeDrawingPadding()
                    .padding(20.dp),
            )
        }
    }
}
