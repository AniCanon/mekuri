package app.mekuri

import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.awaitTouchSlopOrCancellation
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.pointer.PointerInputChange
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.util.VelocityTracker

/**
 * A tap in an outer zone turns a page, a centre tap reports. Both detectors
 * yield to events a descendant has already consumed, so a control inside a page
 * keeps its touches. Paging disabled installs no drag detector at all; centre
 * taps still report.
 *
 * The drag reports after the platform's touch slop rather than after a fixed
 * distance. Once past it, every sample is re-checked for horizontal dominance
 * until a turn locks.
 */
internal fun Modifier.mekuriGestures(
    controller: MekuriPagerController,
    pagingEnabled: Boolean,
    onCenterTap: (() -> Unit)?,
): Modifier = this
    .pointerInput(controller, pagingEnabled, onCenterTap) {
        detectTapGestures { offset ->
            controller.tapped(offset.x / density, onCenterTap, pagingEnabled)
        }
    }
    .pointerInput(controller, pagingEnabled) {
        if (!pagingEnabled) return@pointerInput
        awaitEachGesture {
            val down = awaitFirstDown(requireUnconsumed = true)
            val tracker = VelocityTracker()
            tracker.addPosition(down.uptimeMillis, down.position)
            val slop = awaitTouchSlopOrCancellation(down.id) { change, _ ->
                tracker.addPosition(change.uptimeMillis, change.position)
            } ?: return@awaitEachGesture
            var last: PointerInputChange = slop
            controller.dragChanged((slop.position - down.position) / density)
            while (true) {
                val event = awaitPointerEvent()
                val change = event.changes.firstOrNull { it.id == down.id }
                if (change == null || change.isConsumed) {
                    controller.dragCancelled()
                    return@awaitEachGesture
                }
                if (!change.pressed) {
                    last = change
                    break
                }
                tracker.addPosition(change.uptimeMillis, change.position)
                last = change
                controller.dragChanged((change.position - down.position) / density)
                if (controller.turn != null) change.consume()
            }
            controller.dragEnded(
                translation = (last.position - down.position) / density,
                velocity = tracker.calculateVelocity().x / density,
            )
        }
    }
