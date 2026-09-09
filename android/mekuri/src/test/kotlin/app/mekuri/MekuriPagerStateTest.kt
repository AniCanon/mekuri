package app.mekuri

import kotlinx.coroutines.async
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.yield
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class MekuriPagerStateTest {
    @Test
    fun `the initial page is coerced into the book`() {
        assertEquals(3, MekuriPagerState(pageCount = 6, initialPage = 3).currentPage)
        assertEquals(5, MekuriPagerState(pageCount = 6, initialPage = 99).currentPage)
        assertEquals(0, MekuriPagerState(pageCount = 6, initialPage = -1).currentPage)
        assertEquals(0, MekuriPagerState(pageCount = 0, initialPage = 4).currentPage)
    }

    @Test
    fun `shrinking the book clamps the current page`() {
        val state = MekuriPagerState(pageCount = 6, initialPage = 5)
        state.pageCount = 2
        assertEquals(1, state.currentPage)
        state.pageCount = 0
        assertEquals(0, state.currentPage)
    }

    @Test
    fun `a scroll cuts to the page without a driver`() = runBlocking {
        val state = MekuriPagerState(pageCount = 6, initialPage = 0)
        state.scrollToPage(4)
        assertEquals(4, state.currentPage)
        state.scrollToPage(40)
        assertEquals(5, state.currentPage)
    }

    @Test
    fun `a scroll drops a turn in flight`() = runBlocking {
        val driver = RecordingDriver(settlesOn = 1)
        val state = MekuriPagerState(pageCount = 6, initialPage = 0)
        state.attach(driver)
        state.scrollToPage(3)
        assertEquals(1, driver.drops)
        assertEquals(3, state.currentPage)
    }

    @Test
    fun `an animated turn settles on the page the driver reports`() = runBlocking {
        val driver = RecordingDriver(settlesOn = 2)
        val state = MekuriPagerState(pageCount = 6, initialPage = 1)
        state.attach(driver)
        state.animateToPage(2)
        assertEquals(listOf(2), driver.requests)
        assertEquals(2, state.currentPage)
    }

    @Test
    fun `a reverted turn returns normally and leaves the settled page on screen`() = runBlocking {
        val driver = RecordingDriver(settlesOn = 1)
        val state = MekuriPagerState(pageCount = 6, initialPage = 1)
        state.attach(driver)
        state.animateToPage(2)
        assertEquals(1, state.currentPage)
    }

    @Test
    fun `an animated turn coerces its target before the driver sees it`() = runBlocking {
        val driver = RecordingDriver(settlesOn = 5)
        val state = MekuriPagerState(pageCount = 6, initialPage = 0)
        state.attach(driver)
        state.animateToPage(99)
        assertEquals(listOf(5), driver.requests)
    }

    @Test
    fun `a detached pager leaves no driver behind`() = runBlocking {
        val driver = RecordingDriver(settlesOn = 3)
        val state = MekuriPagerState(pageCount = 6, initialPage = 0)
        state.attach(driver)
        state.detach(driver)
        state.scrollToPage(2)
        assertEquals(0, driver.drops)
        assertEquals(2, state.currentPage)
    }

    @Test
    fun `an animation requested before the pager attaches waits for it`() = runBlocking {
        val state = MekuriPagerState(pageCount = 6, initialPage = 0)
        val driver = RecordingDriver(settlesOn = 1)
        val turn = async { state.animateToPage(1) }
        yield()
        assertTrue(turn.isActive)
        assertEquals(0, state.currentPage)
        state.attach(driver)
        turn.await()
        assertEquals(1, state.currentPage)
    }

    private class RecordingDriver(private val settlesOn: Int) : MekuriTurnDriver {
        val requests = mutableListOf<Int>()
        var drops = 0

        override suspend fun turnTo(page: Int): Int {
            this.requests += page
            return this.settlesOn
        }

        override fun dropTurn() {
            this.drops += 1
        }
    }
}
