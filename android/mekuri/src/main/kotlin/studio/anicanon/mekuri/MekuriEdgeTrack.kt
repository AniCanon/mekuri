package studio.anicanon.mekuri

/**
 * Maps a drag's travel onto turn progress so the sheet's free edge stays under
 * the finger along the grabbed row. [row] is in the shader's frame, free corner
 * at 0; [reach] is the finger's full range, against which a release is judged.
 */
internal data class MekuriEdgeTrack(
    val turn: MekuriTurn,
    val geometry: MekuriFoldGeometry,
    val pageHeight: Float,
    val row: Float,
    val reach: Float,
) {
    /** Distance the free edge has moved from where the turn starts. */
    fun travel(progress: Float): Float {
        val clamped = progress.coerceIn(0f, 1f)
        return when (this.turn) {
            MekuriTurn.Forward -> this.edge(0f) - this.edge(clamped)
            MekuriTurn.Backward -> this.edge(1f - clamped) - this.edge(1f)
        }
    }

    /** Progress at which the free edge has moved [distance]; clamps to 0..1. */
    fun progress(distance: Float): Float {
        if (distance <= 0f) return 0f
        if (distance >= this.travel(1f)) return 1f
        return when (this.turn) {
            MekuriTurn.Forward ->
                this.geometry.progressForFreeEdge(this.edge(0f) - distance, this.row, this.pageHeight)
            MekuriTurn.Backward ->
                1f - this.geometry.progressForFreeEdge(this.edge(1f) + distance, this.row, this.pageHeight)
        }
    }

    /** Progress as a release is judged: the share of [reach] the edge has moved. */
    fun releaseProgress(progress: Float): Float =
        if (this.reach > 0f) this.travel(progress) / this.reach else 0f

    private fun edge(progress: Float): Float = this.geometry.freeEdge(progress, this.row, this.pageHeight)
}
