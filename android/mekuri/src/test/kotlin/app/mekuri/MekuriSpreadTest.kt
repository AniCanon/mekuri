package app.mekuri

import androidx.compose.ui.geometry.Size
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class MekuriSpreadTest {
    private val aspect = 2f / 3f

    @Test
    fun `automatic shows two pages when both fit and stay readable`() {
        assertTrue(MekuriSpread.Automatic.isDouble(Size(1200f, 800f), aspect))
    }

    @Test
    fun `automatic shows one page when two would not fit the width`() {
        assertFalse(MekuriSpread.Automatic.isDouble(Size(700f, 800f), aspect))
    }

    @Test
    fun `automatic shows one page when each would be narrower than the floor`() {
        assertFalse(MekuriSpread.Automatic.isDouble(Size(4000f, 400f), aspect))
    }

    @Test
    fun `forced modes ignore the container`() {
        assertFalse(MekuriSpread.Single.isDouble(Size(4000f, 800f), aspect))
        assertTrue(MekuriSpread.Double.isDouble(Size(100f, 800f), aspect))
    }

    @Test
    fun `page size is the largest at the aspect such that two fit`() {
        val heightLimited = MekuriSpread.pageSize(Size(1200f, 600f), aspect)
        assertEquals(400f, heightLimited.width, TOLERANCE)
        assertEquals(600f, heightLimited.height, TOLERANCE)

        val widthLimited = MekuriSpread.pageSize(Size(900f, 800f), aspect)
        assertEquals(450f, widthLimited.width, TOLERANCE)
        assertEquals(675f, widthLimited.height, TOLERANCE)
    }

    @Test
    fun `direction sweeps a signed progress`() {
        assertEquals(0.25f, MekuriDirection.LeftToRight.sweep(0.25f), 0f)
        assertEquals(-0.25f, MekuriDirection.RightToLeft.sweep(0.25f), 0f)
    }

    private companion object {
        const val TOLERANCE = 1e-3f
    }
}
