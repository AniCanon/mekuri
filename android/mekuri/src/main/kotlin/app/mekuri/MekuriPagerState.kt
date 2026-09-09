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

    /** Drops any turn in flight without animating it. */
    fun dropTurn()
}

/**
 * Selection and turn control for a [MekuriPager]. Create one with
 * [rememberMekuriPagerState] and read [currentPage] to follow the page on
 * screen; [animateToPage] and [scrollToPage] are the only ways to move it from
 * outside.
 *
 * [animateToPage] suspends until a pager is composed with this state, and
 * cancelling the calling coroutine releases it.
 *
 * @param pageCount number of pages in the book.
 * @param direction spine placement and sweep direction.
 * @param initialPage page shown first; coerced into `0 until pageCount`.
 */
public class MekuriPagerState(
    pageCount: Int,
    direction: MekuriDirection = MekuriDirection.LeftToRight,
    initialPage: Int = 0,
) {
    private val driver = MutableStateFlow<MekuriTurnDriver?>(null)

    private var pageCountState by mutableIntStateOf(pageCount.coerceAtLeast(0))

    private var currentPageState by mutableIntStateOf(coerce(initialPage, pageCount))

    /** Number of pages in the book. Shrinking it clamps [currentPage]. */
    public var pageCount: Int
        get() = this.pageCountState
        internal set(value) {
            this.pageCountState = value.coerceAtLeast(0)
            this.currentPageState = coerce(this.currentPageState, this.pageCountState)
        }

    /** Spine placement and sweep direction. */
    public var direction: MekuriDirection = direction
        internal set

    /** Page settled on screen. In a spread this is the leading page of the pair. */
    public var currentPage: Int
        get() = this.currentPageState
        internal set(value) {
            this.currentPageState = coerce(value, this.pageCountState)
        }

    /** Turns to [page] with a fold and returns once the turn has settled. */
    public suspend fun animateToPage(page: Int) {
        val target = coerce(page, this.pageCountState)
        val settled = this.driver.filterNotNull().first().turnTo(target)
        this.currentPageState = coerce(settled, this.pageCountState)
    }

    /** Shows [page] with no fold, dropping any turn in flight. */
    public suspend fun scrollToPage(page: Int) {
        val target = coerce(page, this.pageCountState)
        this.driver.value?.dropTurn()
        this.currentPageState = target
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
         * The restored count is the smallest that keeps the saved page; the
         * composable writes the real one before the state is used.
         */
        internal val Saver: Saver<MekuriPagerState, Int> = Saver(
            save = { it.currentPage },
            restore = { MekuriPagerState(pageCount = it + 1, initialPage = it) },
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
