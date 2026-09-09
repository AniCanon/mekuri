package app.mekuri

/**
 * How a page is being drawn. A [Turning] page is drawn through the fold shader
 * and must not depend on live playback or interaction.
 */
public enum class MekuriPageMode {
    /** The page is settled on screen; interaction and playback run. */
    Live,

    /** The page is a face of the leaf being turned. */
    Turning,
}
