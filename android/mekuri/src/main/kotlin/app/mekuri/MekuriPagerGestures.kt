package app.mekuri

import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.pointer.PointerInputChange
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.util.VelocityTracker

/**
 * One detector for both gestures: a pointer that lifts before the platform's
 * touch slop is a tap, and one that passes it is a drag. Taps and drags are one
 * detector; a second `pointerInput` on this node is not permitted.
 *
 * The down is taken only when no descendant has consumed it, so a control inside
 * a page keeps its touches, and a drag stops the moment a descendant consumes a
 * move. Paging disabled drives no turn and consumes no movement; a centre tap
 * still reports.
 */
internal fun Modifier.mekuriGestures(
    controller: MekuriPagerController,
    pagingEnabled: Boolean,
    onCenterTap: (() -> Unit)?,
): Modifier = this.pointerInput(controller, pagingEnabled, onCenterTap) {
    val slop = this.viewConfiguration.touchSlop
    awaitEachGesture {
        val down = awaitFirstDown(requireUnconsumed = true)
        val tracker = VelocityTracker()
        tracker.addPosition(down.uptimeMillis, down.position)
        var last: PointerInputChange = down
        var dragging = false
        var cancelled = false
        while (true) {
            val change = awaitPointerEvent().changes.firstOrNull { it.id == down.id }
            if (change == null || change.isConsumed) {
                cancelled = true
                break
            }
            last = change
            if (!change.pressed) break
            tracker.addPosition(change.uptimeMillis, change.position)
            val translation = change.position - down.position
            if (!dragging && translation.getDistance() > slop) dragging = true
            if (dragging && pagingEnabled) {
                controller.dragChanged(translation / this.density)
                if (controller.turn != null) change.consume()
            }
        }
        when {
            cancelled -> controller.dragCancelled()
            dragging -> if (pagingEnabled) {
                controller.dragEnded(
                    translation = (last.position - down.position) / this.density,
                    velocity = tracker.calculateVelocity().x / this.density,
                )
            }
            else -> {
                last.consume()
                controller.tapped(down.position.x / this.density, onCenterTap, pagingEnabled)
            }
        }
    }
}
