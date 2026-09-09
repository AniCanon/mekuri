package app.mekuri

import org.junit.Assert.assertEquals
import org.junit.Test

class MekuriDirectionTest {
    @Test
    fun `direction sweeps a signed progress`() {
        assertEquals(0.25f, MekuriDirection.LeftToRight.sweep(0.25f), 0f)
        assertEquals(-0.25f, MekuriDirection.RightToLeft.sweep(0.25f), 0f)
    }
}
