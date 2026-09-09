/// Pairs pages into spreads. With `coverStandsAlone`, spread 0 holds only
/// page 0 in its trailing slot; otherwise pages pair from page 0. Page and
/// spread indices are in reading order.
struct MekuriSpreadLayout: Equatable, Sendable {
    let pageCount: Int
    let coverStandsAlone: Bool

    init(pageCount: Int, coverStandsAlone: Bool) {
        self.pageCount = pageCount
        self.coverStandsAlone = coverStandsAlone
    }

    private var slotOffset: Int { self.coverStandsAlone ? 1 : 0 }

    var spreadCount: Int {
        (self.pageCount + self.slotOffset + 1) / 2
    }

    func spreadIndex(containing page: Int) -> Int {
        (page + self.slotOffset) / 2
    }

    /// Either slot is nil when no page falls in it.
    func pages(inSpread spreadIndex: Int) -> (leading: Int?, trailing: Int?) {
        let leading = 2 * spreadIndex - self.slotOffset
        return (self.page(at: leading), self.page(at: leading + 1))
    }

    /// Nil when the turn would leave `0..<spreadCount` or the departing slot
    /// is absent.
    func leaf(turn: MekuriTurn, spreadIndex: Int) -> MekuriLeaf? {
        guard let target = self.targetSpread(afterTurn: turn, spreadIndex: spreadIndex) else { return nil }
        let current = self.pages(inSpread: spreadIndex)
        let next = self.pages(inSpread: target)
        switch turn {
        case .forward:
            guard let front = current.trailing else { return nil }
            return MekuriLeaf(front: front, back: next.leading, revealed: next.trailing, landsIn: .leading)
        case .backward:
            guard let front = current.leading else { return nil }
            return MekuriLeaf(front: front, back: next.trailing, revealed: next.leading, landsIn: .trailing)
        }
    }

    /// Page to select once the turn lands: the leading page of the new
    /// spread, or its trailing page when the leading slot is absent.
    func selection(afterTurn turn: MekuriTurn, spreadIndex: Int) -> Int? {
        guard self.leaf(turn: turn, spreadIndex: spreadIndex) != nil,
              let target = self.targetSpread(afterTurn: turn, spreadIndex: spreadIndex)
        else { return nil }
        let pages = self.pages(inSpread: target)
        return pages.leading ?? pages.trailing
    }

    private func targetSpread(afterTurn turn: MekuriTurn, spreadIndex: Int) -> Int? {
        let target = switch turn {
        case .forward: spreadIndex + 1
        case .backward: spreadIndex - 1
        }
        return (0..<self.spreadCount).contains(target) ? target : nil
    }

    private func page(at index: Int) -> Int? {
        (0..<self.pageCount).contains(index) ? index : nil
    }
}
