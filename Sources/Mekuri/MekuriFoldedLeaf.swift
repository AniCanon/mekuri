import SwiftUI

/// A turning leaf with a different page printed on each side. `front` is the
/// page being read and `back` the page on its reverse, given in reading
/// orientation; the leaf mirrors it. Without a `back`, the reverse is the
/// front mirrored, exactly as ``MekuriFoldedPage`` draws it. With one, the
/// leaf is two stacked shader passes over two layers, and the crease shadow
/// falls on whatever is beneath the leaf rather than on the leaf.
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
                    self.front()
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
    /// translucent output composites exactly once.
    @ViewBuilder
    private func twoPassLeaf(size: CGSize, back: @escaping () -> Back) -> some View {
        let pass = self.foldPass
        ZStack {
            self.front()
                .scaleEffect(x: pass.mirrorScale, y: 1)
                .compositingGroup()
                .layerEffect(self.fold(size: size, pass: pass, face: .front), maxSampleOffset: size)
                .scaleEffect(x: pass.mirrorScale, y: 1)
            back()
                .scaleEffect(x: -pass.mirrorScale, y: 1)
                .compositingGroup()
                .layerEffect(self.fold(size: size, pass: pass, face: .back), maxSampleOffset: size)
                .scaleEffect(x: pass.mirrorScale, y: 1)
        }
    }

    private func fold(size: CGSize, pass: MekuriFoldPass, face: MekuriFace) -> Shader {
        MekuriFoldShader.make(size: size, progress: pass.shaderProgress, configuration: self.configuration, face: face)
    }
}
