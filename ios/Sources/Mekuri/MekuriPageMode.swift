/// How a page is being drawn, read from `\.mekuriPageMode`. A `.turning`
/// page is rasterized and must not depend on live playback or interaction.
public enum MekuriPageMode: Equatable, Sendable {
    case live
    case turning
}
