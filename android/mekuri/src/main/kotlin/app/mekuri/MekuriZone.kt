package app.mekuri

/**
 * Horizontal region of the container a touch lands in. Each edge zone spans
 * `tapZoneRatio` of the width; points on a boundary fall in [Center].
 */
internal enum class MekuriZone {
    Leading,
    Center,
    Trailing,

    ;

    internal companion object {
        internal fun resolve(x: Float, width: Float, configuration: MekuriConfiguration): MekuriZone {
            val edge = width * configuration.tapZoneRatio
            return when {
                x < edge -> Leading
                x > width - edge -> Trailing
                else -> Center
            }
        }
    }
}
