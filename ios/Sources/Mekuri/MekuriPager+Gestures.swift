import SwiftUI

extension MekuriPager {
    /// `width` is the distance a drag travels to complete a turn.
    func dragGesture(width: CGFloat, arrangement: MekuriArrangement) -> some Gesture {
        DragGesture(minimumDistance: MekuriDrag.minimumDistance, coordinateSpace: .local)
            .onChanged { value in
                self.dragChanged(translation: value.translation, width: width, in: arrangement)
            }
            .onEnded { value in
                self.dragEnded(
                    translation: value.translation,
                    velocity: value.velocity.width,
                    width: width,
                    in: arrangement
                )
            }
    }

    func tapGesture(width: CGFloat, arrangement: MekuriArrangement) -> some Gesture {
        SpatialTapGesture(coordinateSpace: .local)
            .onEnded { value in
                self.tapped(x: value.location.x, width: width, in: arrangement)
            }
    }

    func tapped(x: CGFloat, width: CGFloat, in arrangement: MekuriArrangement) {
        let zone = MekuriZone.resolve(x: x, width: width, configuration: self.configuration)
        guard let turn = MekuriTurn.from(zone: zone, direction: self.direction) else {
            self.onCenterTap?()
            return
        }
        guard self.pagingEnabled else { return }
        self.perform(turn, in: arrangement)
    }

    /// Turns one page or spread with a full animated curl. Does nothing at
    /// the ends or while another turn is in flight.
    func perform(_ turn: MekuriTurn, in arrangement: MekuriArrangement) {
        guard self.turn == nil else { return }
        let state = self.beginTurn(turn, in: arrangement)
        guard let target = state.targetIndex else { return }
        if self.reducesMotion {
            self.commit(to: target)
        } else {
            self.arm(state, decision: .commit)
        }
    }

    /// A drag that is not horizontally dominant neither locks nor takes over
    /// a turn; a locked turn follows every later sample.
    func dragChanged(translation: CGSize, width: CGFloat, in arrangement: MekuriArrangement) {
        guard !self.ignoresCurrentDrag, !self.reducesMotion else { return }
        if var turn = self.turn {
            if turn.isSettling {
                guard MekuriDrag.turn(translation: translation, direction: self.direction) != nil else { return }
                self.takeOver(&turn)
            }
            turn.progress = MekuriDrag.progress(
                start: turn.startProgress,
                translation: translation.width,
                width: width,
                axis: MekuriDrag.axis(turn: turn.turn, direction: self.direction),
                isBlocked: turn.isBlocked
            )
            self.presented.value = turn.progress
            self.turn = turn
            return
        }
        guard let direction = MekuriDrag.turn(translation: translation, direction: self.direction) else { return }
        var turn = self.beginTurn(direction, in: arrangement)
        guard turn.hasLeaf else { return }
        turn.progress = MekuriDrag.progress(
            start: 0,
            translation: translation.width,
            width: width,
            axis: MekuriDrag.axis(turn: direction, direction: self.direction),
            isBlocked: turn.isBlocked
        )
        self.presented.value = turn.progress
        self.turn = turn
    }

    func dragEnded(translation: CGSize, velocity: CGFloat, width: CGFloat, in arrangement: MekuriArrangement) {
        defer { self.ignoresCurrentDrag = false }
        guard !self.ignoresCurrentDrag else { return }
        if self.reducesMotion {
            self.commitReducedMotionDrag(translation: translation, velocity: velocity, width: width, in: arrangement)
            return
        }
        guard let turn = self.turn, turn.phase == .dragging else { return }
        if turn.isBlocked {
            self.settle(decision: .revert)
            return
        }
        let axis = MekuriDrag.axis(turn: turn.turn, direction: self.direction)
        let decision = MekuriTurnDecision.resolve(
            progress: turn.progress,
            velocity: MekuriDrag.projectedVelocity(velocity, axis: axis),
            configuration: self.configuration
        )
        self.settle(decision: decision)
    }

    private func commitReducedMotionDrag(translation: CGSize, velocity: CGFloat, width: CGFloat, in arrangement: MekuriArrangement) {
        guard let direction = MekuriDrag.turn(translation: translation, direction: self.direction),
              let target = arrangement.turnState(id: 0, turn: direction, from: self.settledPage).targetIndex
        else { return }
        let axis = MekuriDrag.axis(turn: direction, direction: self.direction)
        let progress = MekuriDrag.progress(start: 0, translation: translation.width, width: width, axis: axis, isBlocked: false)
        let decision = MekuriTurnDecision.resolve(
            progress: progress,
            velocity: MekuriDrag.projectedVelocity(velocity, axis: axis),
            configuration: self.configuration
        )
        if decision == .commit {
            self.commit(to: target)
        }
    }

    func beginTurn(_ turn: MekuriTurn, in arrangement: MekuriArrangement) -> MekuriTurnState {
        self.nextTurnID += 1
        self.presented.value = 0
        return arrangement.turnState(id: self.nextTurnID, turn: turn, from: self.settledPage)
    }

    /// Inserts the fold at rest, never animated; the layer's appearance
    /// starts the settle.
    func arm(_ turn: MekuriTurnState, decision: MekuriTurnDecision) {
        var state = turn
        state.phase = .armed(decision)
        self.withoutAnimation {
            self.turn = state
        }
    }

    func withoutAnimation(_ body: () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, body)
    }

    func startArmedSettle(id: Int) {
        guard let turn = self.turn, turn.id == id, case .armed(let decision) = turn.phase else { return }
        self.settle(decision: decision)
    }

    /// Cancels the running settle and continues from the presented progress.
    private func takeOver(_ turn: inout MekuriTurnState) {
        turn.startProgress = self.presented.value
        turn.progress = turn.startProgress
        turn.phase = .dragging
        self.withoutAnimation {
            self.turn = turn
        }
    }

    func settle(decision: MekuriTurnDecision) {
        guard var turn = self.turn else { return }
        self.settleCount += 1
        let token = self.settleCount
        turn.phase = .settling(decision)
        self.turn = turn
        withAnimation(self.configuration.settleAnimation) {
            self.turn?.progress = decision == .commit ? 1 : 0
        } completion: {
            self.finishSettle(token: token, decision: decision)
        }
    }

    private func finishSettle(token: Int, decision: MekuriTurnDecision) {
        guard token == self.settleCount, let turn = self.turn, turn.phase == .settling(decision) else { return }
        self.turn = nil
        switch decision {
        case .commit:
            if let target = turn.targetIndex {
                self.commit(to: target)
            }
        case .revert:
            if self.currentPage != self.settledPage {
                self.currentPage = self.settledPage
            }
        }
    }

    /// Moves the shown page and the binding together; the binding's change
    /// is never animated a second time.
    func commit(to index: Int) {
        self.settledPage = index
        if self.currentPage != index {
            self.currentPage = index
        }
    }

    /// Removes the turn, never animated; the rest of a drag in progress is
    /// ignored.
    func dropTurn() {
        guard let turn = self.turn else { return }
        if turn.phase == .dragging {
            self.ignoresCurrentDrag = true
        }
        self.withoutAnimation {
            self.turn = nil
        }
    }
}
