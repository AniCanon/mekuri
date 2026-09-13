import CoreGraphics

/// Maps a drag's travel onto turn progress so the sheet's free edge stays
/// under the finger along the grabbed row. `row` is in the shader's frame,
/// free corner at 0; `reach` is the finger's full range, against which a
/// release is judged.
struct MekuriEdgeTrack: Equatable {
    let turn: MekuriTurn
    let geometry: MekuriFoldGeometry
    let pageHeight: CGFloat
    let row: CGFloat
    let reach: CGFloat

    /// Distance the free edge has moved from where the turn starts.
    func travel(progress: CGFloat) -> CGFloat {
        let progress = min(max(progress, 0), 1)
        switch self.turn {
        case .forward: return self.edge(0) - self.edge(progress)
        case .backward: return self.edge(1 - progress) - self.edge(1)
        }
    }

    /// Progress at which the free edge has moved `travel`; clamps to 0...1.
    func progress(travel: CGFloat) -> CGFloat {
        if travel <= 0 { return 0 }
        if travel >= self.travel(progress: 1) { return 1 }
        switch self.turn {
        case .forward:
            return self.geometry.progress(forFreeEdge: self.edge(0) - travel, y: self.row, pageHeight: self.pageHeight)
        case .backward:
            return 1 - self.geometry.progress(forFreeEdge: self.edge(1) + travel, y: self.row, pageHeight: self.pageHeight)
        }
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
