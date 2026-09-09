import SwiftUI

extension MekuriPager {
    func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: MekuriDrag.minimumDistance, coordinateSpace: .local)
            .onChanged { value in
                self.dragChanged(translation: value.translation, width: width)
            }
            .onEnded { value in
                self.dragEnded(
                    translation: value.translation,
                    velocity: value.velocity.width,
                    width: width
                )
            }
    }

    func tapGesture(width: CGFloat) -> some Gesture {
        SpatialTapGesture(coordinateSpace: .local)
            .onEnded { value in
                self.tapped(x: value.location.x, width: width)
            }
    }

    func tapped(x: CGFloat, width: CGFloat) {
        let zone = MekuriZone.resolve(x: x, width: width, configuration: self.configuration)
        guard let turn = MekuriTurn.from(zone: zone, direction: self.direction) else {
            self.onCenterTap?()
            return
        }
        guard self.pagingEnabled else { return }
        self.perform(turn)
    }

    /// Turns one page with a full animated curl. Does nothing at the ends or
    /// while another turn is in flight.
    func perform(_ turn: MekuriTurn) {
        guard self.turn == nil,
              let target = turn.targetIndex(from: self.settledPage, pageCount: self.pageCount)
        else { return }
        if self.reducesMotion {
            self.commit(to: target)
        } else {
            self.arm(turn, decision: .commit)
        }
    }

    /// A drag that is not horizontally dominant neither locks nor takes over
    /// a turn; a locked turn follows every later sample.
    func dragChanged(translation: CGSize, width: CGFloat) {
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
        var turn = self.beginTurn(direction)
        guard turn.turningIndex != nil else { return }
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

    func dragEnded(translation: CGSize, velocity: CGFloat, width: CGFloat) {
        defer { self.ignoresCurrentDrag = false }
        guard !self.ignoresCurrentDrag else { return }
        if self.reducesMotion {
            self.commitReducedMotionDrag(translation: translation, velocity: velocity, width: width)
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

    private func commitReducedMotionDrag(translation: CGSize, velocity: CGFloat, width: CGFloat) {
        guard let direction = MekuriDrag.turn(translation: translation, direction: self.direction),
              let target = direction.targetIndex(from: self.settledPage, pageCount: self.pageCount)
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

    private func beginTurn(_ turn: MekuriTurn) -> MekuriTurnState {
        self.nextTurnID += 1
        self.presented.value = 0
        return MekuriTurnState.begin(id: self.nextTurnID, turn: turn, from: self.settledPage, pageCount: self.pageCount)
    }

    /// Inserts the fold at rest, never animated; the layer's appearance
    /// starts the settle.
    func arm(_ turn: MekuriTurn, decision: MekuriTurnDecision) {
        var state = self.beginTurn(turn)
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
