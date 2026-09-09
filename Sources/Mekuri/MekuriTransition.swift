/// How a selection change is animated. Only a change of exactly one page
/// curls; any larger jump crossfades.
enum MekuriTransition: Equatable {
    case none
    case curl(MekuriTurn)
    case crossfade

    static func between(from: Int, to: Int) -> MekuriTransition {
        switch to - from {
        case 0: .none
        case 1: .curl(.forward)
        case -1: .curl(.backward)
        default: .crossfade
        }
    }
}
