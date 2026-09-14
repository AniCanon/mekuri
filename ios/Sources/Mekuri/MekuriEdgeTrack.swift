import CoreGraphics

/// Maps a drag's travel onto turn progress so the sheet's free edge stays
/// under the finger along the grabbed row. `row` is in the shader's frame,
/// free corner at 0; `reach` is the finger's full range, against which a
/// release is judged; `stackTravel` is how far the spread stack's own slide
/// carries the edge along the drag across the whole turn.
struct MekuriEdgeTrack: Equatable {
    /// Bisection steps when inverting `travel`; fixed so every platform lands
    /// on the same value.
    static let searchSteps = 32

    let turn: MekuriTurn
    let geometry: MekuriFoldGeometry
    let pageHeight: CGFloat
    let row: CGFloat
    let reach: CGFloat
    var stackTravel: CGFloat = 0

    /// Distance the free edge has moved along the drag from where the turn
    /// starts.
    func travel(progress: CGFloat) -> CGFloat {
        let progress = min(max(progress, 0), 1)
        let sheet = switch self.turn {
        case .forward: self.edge(0) - self.edge(progress)
        case .backward: self.edge(1 - progress) - self.edge(1)
        }
        return sheet + self.stackTravel * progress
    }

    /// Progress at which the free edge has moved `travel`; clamps to 0...1.
    /// A stack sliding against the drag can only pull early travel below
    /// zero, so travel rises through every positive value exactly once.
    func progress(travel: CGFloat) -> CGFloat {
        if travel <= 0 { return 0 }
        if travel >= self.travel(progress: 1) { return 1 }
        var low: CGFloat = 0
        var high: CGFloat = 1
        for _ in 0..<Self.searchSteps {
            let mid = (low + high) / 2
            if self.travel(progress: mid) < travel {
                low = mid
            } else {
                high = mid
            }
        }
        return (low + high) / 2
    }

    /// Progress as a release is judged: the share of `reach` the edge has
    /// moved.
    func releaseProgress(_ progress: CGFloat) -> CGFloat {
        guard self.reach > 0 else { return 0 }
        return self.travel(progress: progress) / self.reach
    }

    private func edge(_ progress: CGFloat) -> CGFloat {
        self.geometry.freeEdge(progress: progress, y: self.row, pageHeight: self.pageHeight)
    }
}
