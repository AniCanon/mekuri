import SwiftUI

/// A turning leaf with a different page printed on each side. `front` is the
/// page being read and `back` the page on its reverse, given in reading
/// orientation; the leaf mirrors it. Without a `back`, the reverse is the
/// front mirrored, exactly as ``MekuriFoldedPage`` draws it, over one page.
/// With one, the leaf spans a two-slot spread: its front fills the trailing
/// slot, hinges at the centre and lands in the leading slot. The leaf draws
/// no shadow; ``MekuriLeafShadow`` draws them beneath it.
struct MekuriFoldedLeaf<Front: View, Back: View>: View {
    private let progress: CGFloat
    private let direction: MekuriDirection
    private let configuration: MekuriConfiguration
    private let front: () -> Front
    private let back: (() -> Back)?

    init(
        progress: CGFloat,
        direction: MekuriDirection,
        configuration: MekuriConfiguration,
        @ViewBuilder front: @escaping () -> Front,
        @ViewBuilder back: @escaping () -> Back
    ) {
        self.progress = progress
        self.direction = direction
        self.configuration = configuration
        self.front = front
        self.back = back
    }

    init(
        progress: CGFloat,
        direction: MekuriDirection,
        configuration: MekuriConfiguration,
        @ViewBuilder front: @escaping () -> Front
    ) where Back == EmptyView {
        self.progress = progress
        self.direction = direction
        self.configuration = configuration
        self.front = front
        self.back = nil
    }

    var hasDistinctBackFace: Bool { self.back != nil }

    var isFolded: Bool { self.progress > 0 }

    var foldPass: MekuriFoldPass {
        MekuriFoldPass(direction: self.direction, progress: self.progress)
    }

    var body: some View {
        if let back = self.back {
            GeometryReader { proxy in
                if self.isFolded {
                    self.twoPassLeaf(size: proxy.size, back: back)
                } else {
                    self.inTrailingSlot(self.front(), size: proxy.size)
                }
            }
        } else {
            MekuriFoldedPage(progress: self.progress, direction: self.direction, configuration: self.configuration) {
                self.front()
            }
        }
    }

    /// The faces never overlap on screen, so the stacking order carries no
    /// meaning. Each pass is flattened before its shader runs so its
    /// translucent output composites exactly once. The back is mirrored
    /// within its slot so both faces sample the trailing slot.
    @ViewBuilder
    private func twoPassLeaf(size: CGSize, back: @escaping () -> Back) -> some View {
        let pass = self.foldPass
        ZStack {
            self.facePass(self.inTrailingSlot(self.front(), size: size), size: size, pass: pass, face: .front)
            self.facePass(self.inTrailingSlot(self.mirrored(back(), size: size), size: size), size: size, pass: pass, face: .back)
        }
        .frame(width: size.width, height: size.height)
    }

    private func facePass(_ layer: some View, size: CGSize, pass: MekuriFoldPass, face: MekuriFace) -> some View {
        layer
            .scaleEffect(x: pass.mirrorScale, y: 1)
            .compositingGroup()
            .layerEffect(self.fold(size: size, pass: pass, face: face), maxSampleOffset: size)
            .scaleEffect(x: pass.mirrorScale, y: 1)
    }

    /// Geometry effects only: layout alignment would follow the layout
    /// direction rather than the reading direction.
    private func inTrailingSlot(_ page: some View, size: CGSize) -> some View {
        let slotWidth = MekuriFoldShader.hinge(in: size)
        return page
            .frame(width: slotWidth, height: size.height)
            .offset(x: self.foldPass.mirrorScale * slotWidth / 2)
            .frame(width: size.width, height: size.height)
    }

    private func mirrored(_ page: some View, size: CGSize) -> some View {
        page
            .frame(width: MekuriFoldShader.hinge(in: size), height: size.height)
            .scaleEffect(x: -1, y: 1)
    }

    private func fold(size: CGSize, pass: MekuriFoldPass, face: MekuriFace) -> Shader {
        MekuriFoldShader.make(
            size: size,
            progress: pass.shaderProgress,
            configuration: self.configuration,
            face: face,
            hinge: MekuriFoldShader.hinge(in: size)
        )
    }
}
