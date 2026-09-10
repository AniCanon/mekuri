package studio.anicanon.mekuri.demo

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/** Palette, strokes and type shared by every drawn page. */
object DemoInk {
    val Paper = Color(0.97f, 0.95f, 0.90f)
    val Ink = Color(0.12f, 0.11f, 0.10f)
    val Accent = Color(0.80f, 0.22f, 0.16f)
    val Backdrop = Color(0.12f, 0.12f, 0.12f)

    val PanelStroke = 3.dp
    val BubbleStroke = 2.5.dp
    val Gutter = 12.dp
    val Margin = 18.dp

    /** Page type scales against this reference page width in dp. */
    const val ReferencePage = 400f

    fun sfx(size: Float) = TextStyle(
        fontSize = size.sp,
        fontWeight = FontWeight.Black,
        fontFamily = FontFamily.Default,
        color = Ink,
    )

    fun narration(size: Float) = TextStyle(
        fontSize = size.sp,
        fontWeight = FontWeight.Normal,
        fontFamily = FontFamily.Serif,
        color = Ink,
    )

    fun speech(size: Float) = TextStyle(
        fontSize = size.sp,
        fontWeight = FontWeight.SemiBold,
        fontFamily = FontFamily.Default,
        color = Ink,
    )

    fun title(size: Float) = TextStyle(
        fontSize = size.sp,
        fontWeight = FontWeight.Black,
        fontFamily = FontFamily.Serif,
        color = Ink,
    )

    fun label(size: Float) = TextStyle(
        fontSize = size.sp,
        fontWeight = FontWeight.SemiBold,
        fontFamily = FontFamily.Default,
        color = Ink,
    )
}
