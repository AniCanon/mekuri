import SwiftUI

extension MekuriPager {
    /// `size` is the container's; the grab's height picks the lifting corner
    /// and the row whose free edge follows the finger.
    func dragGesture(size: CGSize, arrangement: MekuriArrangement) -> some Gesture {
        DragGesture(minimumDistance: MekuriDrag.minimumDistance, coordinateSpace: .local)
            .onChanged { value in
                self.dragChanged(translation: value.translation, grabY: value.startLocation.y, size: size, in: arrangement)
            }
            .onEnded { value in
                self.dragEnded(
                    translation: value.translation,
                    velocity: value.velocity.width,
                    grabY: value.startLocation.y,
                    size: size,
                    in: arrangement
                )
            }
    }

    func tapGesture(width: CGFloat, height: CGFloat, arrangement: MekuriArrangement) -> some Gesture {
        SpatialTapGesture(coordinateSpace: .local)
            .onEnded { value in
                self.tapped(
                    x: value.location.x,
                    y: value.location.y,
                    liftsFromBottom: MekuriDrag.liftsFromBottom(y: value.location.y, height: height),
                    width: width,
                    in: arrangement
                )
            }
    }

    func tapped(x: CGFloat, y: CGFloat, liftsFromBottom: Bool, width: CGFloat, in arrangement: MekuriArrangement) {
        let zone = MekuriZone.resolve(x: x, width: width, configuration: self.configuration)
        guard let turn = MekuriTurn.from(zone: zone, direction: self.direction) else {
            self.onCenterTap?()
            return
        }
        guard self.pagingEnabled else { return }
        self.perform(turn, liftsFromBottom: liftsFromBottom, grabY: y, in: arrangement)
    }

    /// Turns one page or spread with a full animated curl. Does nothing at
    /// the ends or while another turn is in flight.
    func perform(_ turn: MekuriTurn, liftsFromBottom: Bool = false, grabY: CGFloat? = nil, in arrangement: MekuriArrangement) {
        guard self.turn == nil else { return }
        var state = self.beginTurn(turn, in: arrangement)
        state.liftsFromBottom = liftsFromBottom
        state.grabY = grabY
        state.playsHaptics = true
        guard let target = state.targetIndex else { return }
        if self.reducesMotion {
            self.commit(to: target)
            self.play(.land)
        } else {
            self.arm(state, decision: .commit)
            self.play(.lift)
        }
    }

    /// A drag that is not horizontally dominant neither locks nor takes over
    /// a turn; a locked turn follows every later sample.
    func dragChanged(translation: CGSize, grabY: CGFloat, size: CGSize, in arrangement: MekuriArrangement) {
        guard !self.ignoresCurrentDrag, !self.reducesMotion else { return }
        if var turn = self.turn {
            if turn.isSettling {
                guard MekuriDrag.turn(translation: translation, direction: self.direction) != nil else { return }
                self.takeOver(&turn)
            }
            let track = self.edgeTrack(for: turn, size: size, in: arrangement)
            let before = turn.progress
            turn.progress = MekuriDrag.progress(
                start: turn.startProgress,
                translation: translation.width,
                axis: MekuriDrag.axis(turn: turn.turn, direction: self.direction),
                isBlocked: turn.isBlocked,
                track: track
            )
            self.presented.value = turn.progress
            self.turn = turn
            let crossed = MekuriHaptic.crossesThreshold(
                from: track.releaseProgress(before),
                to: track.releaseProgress(turn.progress),
                threshold: self.configuration.snapThreshold
            )
            if !turn.isBlocked, crossed {
                self.play(.detent)
            }
            return
        }
        guard let direction = MekuriDrag.turn(translation: translation, direction: self.direction) else { return }
        var turn = self.beginTurn(direction, in: arrangement)
        guard turn.hasLeaf else { return }
        turn.liftsFromBottom = MekuriDrag.liftsFromBottom(y: grabY, height: size.height)
        turn.grabY = grabY
        turn.playsHaptics = true
        turn.progress = MekuriDrag.progress(
            start: 0,
            translation: translation.width,
            axis: MekuriDrag.axis(turn: direction, direction: self.direction),
            isBlocked: turn.isBlocked,
            track: self.edgeTrack(for: turn, size: size, in: arrangement)
        )
        self.presented.value = turn.progress
        self.turn = turn
        self.play(.lift)
    }

    func dragEnded(translation: CGSize, velocity: CGFloat, grabY: CGFloat, size: CGSize, in arrangement: MekuriArrangement) {
        defer { self.ignoresCurrentDrag = false }
        guard !self.ignoresCurrentDrag else { return }
        if self.reducesMotion {
            self.commitReducedMotionDrag(translation: translation, velocity: velocity, grabY: grabY, size: size, in: arrangement)
            return
        }
        guard let turn = self.turn, turn.phase == .dragging else { return }
        if turn.isBlocked {
            self.settle(decision: .revert)
            return
        }
        let axis = MekuriDrag.axis(turn: turn.turn, direction: self.direction)
        let decision = MekuriTurnDecision.resolve(
            progress: self.edgeTrack(for: turn, size: size, in: arrangement).releaseProgress(turn.progress),
            velocity: MekuriDrag.projectedVelocity(velocity, axis: axis),
            configuration: self.configuration
        )
        self.settle(decision: decision)
    }

    private func commitReducedMotionDrag(
        translation: CGSize,
        velocity: CGFloat,
        grabY: CGFloat,
        size: CGSize,
        in arrangement: MekuriArrangement
    ) {
        guard let direction = MekuriDrag.turn(translation: translation, direction: self.direction),
              let target = arrangement.turnState(id: 0, turn: direction, from: self.settledPage).targetIndex
        else { return }
        let axis = MekuriDrag.axis(turn: direction, direction: self.direction)
        let track = arrangement.edgeTrack(
            turn: direction,
            containerSize: size,
            grabY: grabY,
            liftsFromBottom: MekuriDrag.liftsFromBottom(y: grabY, height: size.height),
            configuration: self.configuration
        )
        let progress = MekuriDrag.progress(start: 0, translation: translation.width, axis: axis, isBlocked: false, track: track)
        let decision = MekuriTurnDecision.resolve(
            progress: track.releaseProgress(progress),
            velocity: MekuriDrag.projectedVelocity(velocity, axis: axis),
            configuration: self.configuration
        )
        if decision == .commit {
            self.commit(to: target)
            self.play(.land)
        }
    }

    /// A turn no finger started tracks the page's midline.
    private func edgeTrack(for turn: MekuriTurnState, size: CGSize, in arrangement: MekuriArrangement) -> MekuriEdgeTrack {
        let span = arrangement.shiftSpan(showing: self.settledPage, turn: turn, direction: self.direction)
        return arrangement.edgeTrack(
            turn: turn.turn,
            containerSize: size,
            grabY: turn.grabY ?? size.height / 2,
            liftsFromBottom: turn.liftsFromBottom,
            configuration: self.configuration,
            stackTravel: MekuriDrag.axis(turn: turn.turn, direction: self.direction) * (span.end - span.start)
        )
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
        turn.playsHaptics = true
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
                if turn.playsHaptics {
                    self.play(.land)
                }
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

    func play(_ haptic: MekuriHaptic) {
        guard self.hapticsEnabled else { return }
        self.haptic = MekuriHapticEvent(id: (self.haptic?.id ?? 0) + 1, haptic: haptic)
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
