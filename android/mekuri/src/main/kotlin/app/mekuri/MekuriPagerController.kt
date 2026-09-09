package app.mekuri

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.AnimationVector1D
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch

/**
 * The turn in flight and everything that moves it. Every length here is in dp,
 * matching the tuning constants; the pager converts once, at the pointer and at
 * the placement.
 *
 * [progress] is the presented progress of the turn, 0 (nothing turned) to 1, in
 * the turn's own direction. It is written every frame, so it must be read inside
 * a layer or draw block and never in composition.
 */
internal class MekuriPagerController(
    val state: MekuriPagerState,
    private val scope: CoroutineScope,
) : MekuriTurnDriver {
    /** Written by the pager each composition; never read from composition. */
    var arrangement: MekuriArrangement = MekuriArrangement.Single(pageCount = 0)

    var containerSize: Size = Size.Zero

    var configuration: MekuriConfiguration = MekuriConfiguration.Default

    var reducesMotion: Boolean = false

    /** Presented progress of the turn in flight. */
    var progress: Float by mutableFloatStateOf(0f)

    var turn: MekuriTurnState? by mutableStateOf(null)
        private set

    /** Page fading out over the new one; null unless a crossfade is running. */
    var crossfadeFrom: Int? by mutableStateOf(null)
        private set

    val crossfadeAlpha: Animatable<Float, AnimationVector1D> = Animatable(0f)

    private val settleProgress = Animatable(0f)

    private var settleJob: Job? = null

    private var pending: CompletableDeferred<Int>? = null

    private var nextTurnId = 0

    private var ignoresCurrentDrag = false

    val direction: MekuriDirection get() = this.state.direction

    val settledPage: Int get() = this.state.currentPage

    /** Distance a drag travels to complete a turn, in dp. */
    val turnWidth: Float get() = this.arrangement.turnWidth(this.containerSize.width)

    fun foldProgress(): Float = this.turn?.turn?.fold(this.progress) ?: 0f

    // Taps and programmatic turns

    fun tapped(x: Float, onCenterTap: (() -> Unit)?, pagingEnabled: Boolean) {
        val zone = MekuriZone.resolve(x, this.containerSize.width, this.configuration)
        val turn = MekuriTurn.from(zone, this.direction)
        if (turn == null) {
            onCenterTap?.invoke()
            return
        }
        if (!pagingEnabled) return
        this.perform(turn)
    }

    /** Does nothing at the ends or while another turn is in flight. */
    fun perform(turn: MekuriTurn) {
        if (this.turn != null) return
        val begun = this.begin(turn)
        val target = begun.targetIndex ?: return
        if (this.reducesMotion) {
            this.state.currentPage = target
        } else {
            this.arm(begun, MekuriTurnDecision.Commit)
        }
    }

    // The driver the pager state calls

    /**
     * A curl driven from outside lands on the page the caller asked for, not on
     * the landing spread's leading page.
     */
    override suspend fun turnTo(page: Int): Int {
        val from = this.settledPage
        if (page == from) return page
        return when (val transition = this.arrangement.transition(from, page)) {
            MekuriTransition.None -> page
            MekuriTransition.Crossfade -> {
                this.crossfadeTo(page)
                page
            }
            is MekuriTransition.Curl -> this.curlTo(page, transition.turn)
        }
    }

    override fun dropTurn() {
        this.settleJob?.cancel()
        this.settleJob = null
        if (this.turn?.phase == MekuriTurnPhase.Dragging) this.ignoresCurrentDrag = true
        this.turn = null
        this.progress = 0f
        this.pending?.cancel()
        this.pending = null
    }

    private suspend fun curlTo(page: Int, turn: MekuriTurn): Int {
        this.dropTurn()
        val begun = this.begin(turn).copy(targetIndex = page)
        if (this.reducesMotion || begun.isBlocked || !begun.hasLeaf) return page
        val landing = CompletableDeferred<Int>()
        this.pending = landing
        this.arm(begun, MekuriTurnDecision.Commit)
        return landing.await()
    }

    private suspend fun crossfadeTo(page: Int) {
        if (this.reducesMotion) return
        this.crossfadeFrom = this.settledPage
        this.crossfadeAlpha.snapTo(1f)
        this.state.currentPage = page
        try {
            this.crossfadeAlpha.animateTo(0f, this.configuration.settleAnimation)
        } finally {
            this.crossfadeFrom = null
        }
    }

    // Drags

    /**
     * A drag that is not horizontally dominant neither locks nor takes over a
     * turn; a locked turn follows every later sample. `translation` is in dp.
     */
    fun dragChanged(translation: Offset) {
        if (this.ignoresCurrentDrag || this.reducesMotion) return
        val width = this.turnWidth
        val current = this.turn
        if (current != null) {
            var moving = current
            if (current.isSettling) {
                if (MekuriDrag.turn(translation, this.direction) == null) return
                moving = this.takeOver(current)
            }
            this.progress = MekuriDrag.progress(
                start = moving.startProgress,
                translation = translation.x,
                width = width,
                axis = MekuriDrag.axis(moving.turn, this.direction),
                isBlocked = moving.isBlocked,
            )
            return
        }
        val turn = MekuriDrag.turn(translation, this.direction) ?: return
        val begun = this.begin(turn)
        if (!begun.hasLeaf) return
        this.turn = begun
        this.progress = MekuriDrag.progress(
            start = 0f,
            translation = translation.x,
            width = width,
            axis = MekuriDrag.axis(turn, this.direction),
            isBlocked = begun.isBlocked,
        )
    }

    /** `velocity` is the horizontal drag velocity in dp per second. */
    fun dragEnded(translation: Offset, velocity: Float) {
        val ignored = this.ignoresCurrentDrag
        this.ignoresCurrentDrag = false
        if (ignored) return
        if (this.reducesMotion) {
            this.commitReducedMotionDrag(translation, velocity)
            return
        }
        val current = this.turn ?: return
        if (current.phase != MekuriTurnPhase.Dragging) return
        if (current.isBlocked) {
            this.settle(MekuriTurnDecision.Revert)
            return
        }
        val axis = MekuriDrag.axis(current.turn, this.direction)
        this.settle(
            MekuriTurnDecision.resolve(
                progress = this.progress,
                velocity = MekuriDrag.projectedVelocity(velocity, axis),
                configuration = this.configuration,
            ),
        )
    }

    fun dragCancelled() {
        this.ignoresCurrentDrag = false
        if (this.turn?.phase == MekuriTurnPhase.Dragging) this.settle(MekuriTurnDecision.Revert)
    }

    private fun commitReducedMotionDrag(translation: Offset, velocity: Float) {
        val turn = MekuriDrag.turn(translation, this.direction) ?: return
        val target = this.arrangement.turnState(0, turn, this.settledPage).targetIndex ?: return
        val axis = MekuriDrag.axis(turn, this.direction)
        val decision = MekuriTurnDecision.resolve(
            progress = MekuriDrag.progress(0f, translation.x, this.turnWidth, axis, isBlocked = false),
            velocity = MekuriDrag.projectedVelocity(velocity, axis),
            configuration = this.configuration,
        )
        if (decision == MekuriTurnDecision.Commit) this.state.currentPage = target
    }

    /** Cancels the running settle and continues from the presented progress. */
    private fun takeOver(turn: MekuriTurnState): MekuriTurnState {
        this.settleJob?.cancel()
        this.settleJob = null
        val taken = turn.copy(startProgress = this.progress, phase = MekuriTurnPhase.Dragging)
        this.turn = taken
        return taken
    }

    // The settle

    private fun begin(turn: MekuriTurn): MekuriTurnState {
        this.nextTurnId += 1
        this.progress = 0f
        return this.arrangement.turnState(this.nextTurnId, turn, this.settledPage)
    }

    /** Inserts the fold at rest, never animated, and settles from there. */
    private fun arm(turn: MekuriTurnState, decision: MekuriTurnDecision) {
        this.settleJob?.cancel()
        this.turn = turn.copy(phase = MekuriTurnPhase.Armed(decision))
        this.settleJob = this.scope.launch { runSettle(turn.id, decision) }
    }

    private fun settle(decision: MekuriTurnDecision) {
        val current = this.turn ?: return
        this.settleJob?.cancel()
        this.settleJob = this.scope.launch { runSettle(current.id, decision) }
    }

    private suspend fun runSettle(id: Int, decision: MekuriTurnDecision) {
        val current = this.turn ?: return
        if (current.id != id) return
        this.turn = current.copy(phase = MekuriTurnPhase.Settling(decision))
        this.settleProgress.snapTo(this.progress)
        val target = if (decision == MekuriTurnDecision.Commit) 1f else 0f
        this.settleProgress.animateTo(target, this.configuration.settleAnimation) {
            this@MekuriPagerController.progress = this.value
        }
        this.finish(id, decision)
    }

    private fun finish(id: Int, decision: MekuriTurnDecision) {
        val current = this.turn ?: return
        if (current.id != id || current.phase != MekuriTurnPhase.Settling(decision)) return
        this.turn = null
        this.progress = 0f
        val landed = when (decision) {
            MekuriTurnDecision.Commit -> current.targetIndex ?: current.fromIndex
            MekuriTurnDecision.Revert -> current.fromIndex
        }
        this.state.currentPage = landed
        this.pending?.complete(landed)
        this.pending = null
    }
}
