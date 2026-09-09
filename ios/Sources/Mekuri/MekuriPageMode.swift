/// How a page is being drawn, read from `\.mekuriPageMode`. A `.turning`
/// page is rasterized and must not depend on live playback or interaction.
public enum MekuriPageMode: Equatable, Sendable {
    /// The page is settled on screen; interaction and playback run.
    case live
    /// The page is a face of the leaf being turned and is drawn through the
    /// fold shader from a flattened copy.
    case turning
}
