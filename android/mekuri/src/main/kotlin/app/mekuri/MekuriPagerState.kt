package app.mekuri

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.saveable.Saver
import androidx.compose.runtime.saveable.rememberSaveable
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.first

/**
 * The pager a [MekuriPagerState] drives. Installed by the pager while it is
 * composed; the state holder owns no animation of its own.
 */
internal interface MekuriTurnDriver {
    /**
     * Turns to [page] and returns the page settled on. A turn the user grabbed
     * and pushed back returns the page it started from rather than failing.
     */
    suspend fun turnTo(page: Int): Int

    /**
     * Drops any turn in flight without animating it. A [turnTo] call in flight
     * must be cancelled, not allowed to return.
     */
    fun dropTurn()
}

/**
 * Selection and turn control for a Mekuri pager. Create one with
 * [rememberMekuriPagerState] and read [currentPage] to follow the page on
 * screen; [animateToPage] and [scrollToPage] are the only ways to move it from
 * outside.
 *
 * [animateToPage] suspends until a pager is composed with this state, and
 * cancelling the calling coroutine releases it.
 *
 * Two departures from Compose's own `PagerState`, both deliberate:
 * a turn the user grabs and pushes back returns from [animateToPage] normally
 * with the settled page, where `PagerState` throws a cancellation; and a
 * [scrollToPage] arriving mid-turn cancels the pending [animateToPage].
 *
 * @param pageCount number of pages in the book.
 * @param direction spine placement and sweep direction.
 * @param initialPage page shown first; clamped on read into `0 until pageCount`.
 */
public class MekuriPagerState(
    pageCount: Int,
    direction: MekuriDirection = MekuriDirection.LeftToRight,
    initialPage: Int = 0,
) {
    private val driver = MutableStateFlow<MekuriTurnDriver?>(null)

    private var pageCountState by mutableIntStateOf(pageCount.coerceAtLeast(0))

    private var currentPageState by mutableIntStateOf(initialPage)

    /** Number of pages in the book. Shrinking it clamps [currentPage]. */
    public var pageCount: Int
        get() = this.pageCountState
        internal set(value) {
            this.pageCountState = value.coerceAtLeast(0)
        }

    /** Spine placement and sweep direction. */
    public var direction: MekuriDirection = direction
        internal set

    /**
     * Page settled on screen. In a spread this is the leading page of the pair.
     * The page is stored as given and clamped only on read; a page count that
     * momentarily drops to zero must not discard it.
     */
    public var currentPage: Int
        get() = coerce(this.currentPageState, this.pageCountState)
        internal set(value) {
            this.currentPageState = value
        }

    /**
     * Turns to [page] with a fold and returns once the turn has settled. The
     * target is clamped against the page count only once a pager has attached.
     */
    public suspend fun animateToPage(page: Int) {
        val driver = this.driver.filterNotNull().first()
        val settled = driver.turnTo(coerce(page, this.pageCountState))
        this.currentPageState = settled
    }

    /** Shows [page] with no fold, dropping any turn in flight. */
    public suspend fun scrollToPage(page: Int) {
        this.driver.value?.dropTurn()
        this.currentPageState = page
    }

    internal fun attach(driver: MekuriTurnDriver) {
        this.driver.value = driver
    }

    internal fun detach(driver: MekuriTurnDriver) {
        this.driver.compareAndSet(driver, null)
    }

    internal companion object {
        private fun coerce(page: Int, pageCount: Int): Int =
            if (pageCount <= 0) 0 else page.coerceIn(0, pageCount - 1)

        /**
         * Saves the stored page rather than the clamped read; the composable
         * writes the real page count after the state is restored.
         */
        internal val Saver: Saver<MekuriPagerState, Int> = Saver(
            save = { it.currentPageState },
            restore = { MekuriPagerState(pageCount = 0, initialPage = it) },
        )
    }
}

/**
 * Remembers a [MekuriPagerState] across recompositions and configuration
 * changes. [pageCount] and [direction] are written into the remembered state on
 * every composition; [initialPage] is read once.
 */
@Composable
public fun rememberMekuriPagerState(
    pageCount: Int,
    direction: MekuriDirection = MekuriDirection.LeftToRight,
    initialPage: Int = 0,
): MekuriPagerState {
    val state = rememberSaveable(saver = MekuriPagerState.Saver) {
        MekuriPagerState(pageCount = pageCount, direction = direction, initialPage = initialPage)
    }
    state.pageCount = pageCount
    state.direction = direction
    return state
}
