package studio.anicanon.mekuri.demo

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Pages are full-bleed on every supported release, not only on the
        // ones that enforce it; chrome pads itself off the system bars.
        this.enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        setContent { DemoReaderScreen() }
    }
}
