/// The two-sided page a turn moves. `revealed` is the page uncovered in the
/// slot the leaf departs from; nil when that slot ends up absent.
struct MekuriLeaf: Equatable, Sendable {
    let front: Int
    let back: Int?
    let revealed: Int?
    let landsIn: MekuriSlot
}
