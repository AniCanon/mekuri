package studio.anicanon.mekuri

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class MekuriHapticTest {
    @Test
    fun `a drag ticks only when it crosses the commit point`() {
        assertTrue(MekuriHaptic.crossesThreshold(0.3f, 0.35f, 0.35f))
        assertTrue(MekuriHaptic.crossesThreshold(0.4f, 0.34f, 0.35f))
        assertFalse(MekuriHaptic.crossesThreshold(0.1f, 0.34f, 0.35f))
        assertFalse(MekuriHaptic.crossesThreshold(0.35f, 0.9f, 0.35f))
    }
}
