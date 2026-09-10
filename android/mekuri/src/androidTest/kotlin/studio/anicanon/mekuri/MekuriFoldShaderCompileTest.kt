package studio.anicanon.mekuri

import android.graphics.RuntimeShader
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class MekuriFoldShaderCompileTest {

    @Test
    fun foldShaderSourceCompiles() {
        RuntimeShader(MEKURI_FOLD_AGSL)
    }
}
