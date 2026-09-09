import SwiftUI

extension MekuriPager {
    @ViewBuilder
    func layers(size: CGSize, arrangement: MekuriArrangement) -> some View {
        switch arrangement {
        case .single:
            self.singleLayers(size: size)
        case .spread(_, let pageSize):
            self.spreadLayers(size: size, pageSize: pageSize, arrangement: arrangement)
        }
    }

    /// Single-page mode: the base page fills the container and the leaf folds
    /// across the whole of it, its reverse the front mirrored.
    private func singleLayers(size: CGSize) -> some View {
        let baseIndex = self.turn.map(\.baseIndex) ?? self.settledPage
        return ZStack {
            if let baseIndex, (0..<self.pageCount).contains(baseIndex) {
                self.content(baseIndex)
                    .environment(\.mekuriPageMode, .live)
                    .frame(width: size.width, height: size.height)
                    .id(baseIndex)
                    .transition(.opacity)
            }
            if let turn = self.turn, let turningIndex = turn.turningIndex {
                self.content(turningIndex)
                    .environment(\.mekuriPageMode, .turning)
                    .frame(width: size.width, height: size.height)
                    .modifier(self.foldModifier(for: turn))
                    .id(turn.id)
                    .onAppear { self.startArmedSettle(id: turn.id) }
            }
        }
        .frame(width: size.width, height: size.height)
    }

    /// Spread mode, drawn in order: the two live slots, then the leaf's
    /// shadow and the leaf, all at the full two-slot width. An absent slot
    /// draws nothing. The whole stack is shifted as one piece so a lone page
    /// sits centred at rest and slides to its slot with the turn.
    private func spreadLayers(size: CGSize, pageSize: CGSize, arrangement: MekuriArrangement) -> some View {
        let slots = self.turn.map { ($0.leading, $0.trailing) } ?? arrangement.slots(showing: self.settledPage)
        let spreadSize = CGSize(width: pageSize.width * 2, height: pageSize.height)
        let shift = arrangement.shiftSpan(showing: self.settledPage, turn: self.turn, direction: self.direction)
        return ZStack {
            if let leading = slots.0 {
                self.slot(leading, in: .leading, pageSize: pageSize)
            }
            if let trailing = slots.1 {
                self.slot(trailing, in: .trailing, pageSize: pageSize)
            }
            if let turn = self.turn {
                self.face(turn.leafFront)
                    .modifier(self.leafModifier(for: turn, back: turn.leafBack))
                    .frame(width: spreadSize.width, height: spreadSize.height)
                    .id(turn.id)
                    .onAppear { self.startArmedSettle(id: turn.id) }
            }
        }
        .frame(width: spreadSize.width, height: spreadSize.height)
        .modifier(MekuriSpreadShiftModifier(progress: self.turn?.progress ?? 0, span: shift))
        .frame(width: size.width, height: size.height)
    }

    /// Geometry offsets, not layout alignment: the layout direction must not
    /// move a slot.
    private func slot(_ page: Int, in slot: MekuriSlot, pageSize: CGSize) -> some View {
        let side: CGFloat = slot == .leading ? -1 : 1
        let reading: CGFloat = self.direction == .leftToRight ? 1 : -1
        return self.content(page)
            .environment(\.mekuriPageMode, .live)
            .frame(width: pageSize.width, height: pageSize.height)
            .offset(x: side * reading * pageSize.width / 2)
            .id(page)
            .transition(.opacity)
    }

    /// A face with no page is clear, so whatever lies beneath shows.
    @ViewBuilder
    private func face(_ page: Int?) -> some View {
        if let page {
            self.content(page)
                .environment(\.mekuriPageMode, .turning)
        } else {
            Color.clear
        }
    }

    private func foldModifier(for turn: MekuriTurnState) -> MekuriFoldModifier {
        MekuriFoldModifier(
            turn: turn,
            direction: self.direction,
            configuration: self.configuration,
            presented: self.presented
        )
    }

    private func leafModifier(for turn: MekuriTurnState, back: Int?) -> MekuriLeafModifier<some View> {
        MekuriLeafModifier(
            turn: turn,
            direction: self.direction,
            configuration: self.configuration,
            presented: self.presented
        ) {
            self.face(back)
        }
    }
}
