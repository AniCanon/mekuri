package studio.anicanon.mekuri.demo

import androidx.compose.runtime.Composable
import androidx.compose.ui.geometry.Rect

/** The panelled pages: each is a list of panel specs on the unit square. */
enum class DemoPageLayout {
    FourGrid,
    ThreePanel,
    Ending,

    ;

    val panels: List<DemoPanelSpec>
        get() = when (this) {
            FourGrid -> listOf(
                DemoPanelSpec(
                    frame = Rect(0f, 0f, 0.5f, 0.5f),
                    art = DemoPanelArt.Figure(DemoPose.Standing, tone = true),
                    bubble = DemoBubbleSpec("A page is a leaf.", anchorY = 0.24f),
                ),
                DemoPanelSpec(frame = Rect(0.5f, 0f, 1f, 0.5f), art = DemoPanelArt.Broadcast),
                DemoPanelSpec(
                    frame = Rect(0f, 0.5f, 0.5f, 1f),
                    art = DemoPanelArt.Speed(DemoPose.Running),
                    sound = DemoSoundSpec("FWIP", anchorY = 0.2f),
                ),
                DemoPanelSpec(
                    frame = Rect(0.5f, 0.5f, 1f, 1f),
                    art = DemoPanelArt.Figure(DemoPose.Pointing, tone = false),
                    bubble = DemoBubbleSpec("Corner first.", anchorY = 0.24f),
                ),
            )
            ThreePanel -> listOf(
                DemoPanelSpec(
                    frame = Rect(0f, 0f, 1f, 0.42f),
                    art = DemoPanelArt.Skyline,
                    caption = "The city, later.",
                ),
                DemoPanelSpec(
                    frame = Rect(0f, 0.42f, 0.5f, 1f),
                    art = DemoPanelArt.Figure(DemoPose.Reading, tone = true),
                    bubble = DemoBubbleSpec(
                        "It bends around a cylinder.",
                        tail = DemoBubbleTail.BottomTrailing,
                        anchorY = 0.2f,
                    ),
                ),
                DemoPanelSpec(frame = Rect(0.5f, 0.42f, 1f, 1f), art = DemoPanelArt.Broadcast),
            )
            Ending -> listOf(
                DemoPanelSpec(frame = Rect(0f, 0f, 0.5f, 1 / 3f), art = DemoPanelArt.Moon),
                DemoPanelSpec(
                    frame = Rect(0.5f, 0f, 1f, 1 / 3f),
                    art = DemoPanelArt.Figure(DemoPose.Standing, tone = false),
                    bubble = DemoBubbleSpec("Both faces, one sheet.", anchorY = 0.26f),
                ),
                DemoPanelSpec(frame = Rect(0f, 1 / 3f, 0.5f, 2 / 3f), art = DemoPanelArt.Broadcast),
                DemoPanelSpec(
                    frame = Rect(0.5f, 1 / 3f, 1f, 2 / 3f),
                    art = DemoPanelArt.Speed(null),
                    sound = DemoSoundSpec("FLIP", burst = true),
                ),
                DemoPanelSpec(
                    frame = Rect(0f, 2 / 3f, 0.5f, 1f),
                    art = DemoPanelArt.Figure(DemoPose.Pointing, tone = true),
                    caption = "Last page.",
                ),
                DemoPanelSpec(frame = Rect(0.5f, 2 / 3f, 1f, 1f), art = DemoPanelArt.Ending),
            )
        }
}

@Composable
fun DemoGridPage(layout: DemoPageLayout, scale: Float) {
    val panels = layout.panels
    DemoPanelGrid(frames = panels.map { it.frame }) { index ->
        DemoPanelView(panels[index], scale)
    }
}
