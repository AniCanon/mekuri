package app.mekuri

import android.graphics.Bitmap
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.test.platform.app.InstrumentationRegistry
import java.io.File

const val SCENE_TAG: String = "mekuri-scene"

/** Writes a capture where `adb pull` can reach it, and returns the file. */
fun ImageBitmap.saveScene(name: String): File {
    val directory = File(
        InstrumentationRegistry.getInstrumentation().targetContext.getExternalFilesDir(null),
        "mekuri",
    )
    directory.mkdirs()
    val file = File(directory, "$name.png")
    file.outputStream().use { asAndroidBitmap().compress(Bitmap.CompressFormat.PNG, 100, it) }
    return file
}

fun ImageBitmap.pixels(): IntArray {
    val bitmap = asAndroidBitmap()
    val pixels = IntArray(bitmap.width * bitmap.height)
    bitmap.getPixels(pixels, 0, bitmap.width, 0, 0, bitmap.width, bitmap.height)
    return pixels
}

/** Number of pixels differing by more than [tolerance] in any channel. */
fun countDifferences(left: IntArray, right: IntArray, tolerance: Int = 0): Int {
    require(left.size == right.size)
    var differing = 0
    for (index in left.indices) {
        val a = left[index]
        val b = right[index]
        if (a == b) continue
        val delta = maxOf(
            Math.abs((a ushr 24 and 0xFF) - (b ushr 24 and 0xFF)),
            Math.abs((a ushr 16 and 0xFF) - (b ushr 16 and 0xFF)),
            Math.abs((a ushr 8 and 0xFF) - (b ushr 8 and 0xFF)),
            Math.abs((a and 0xFF) - (b and 0xFF)),
        )
        if (delta > tolerance) differing++
    }
    return differing
}
