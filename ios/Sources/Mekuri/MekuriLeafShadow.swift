import SwiftUI

/// The shadows a two-sided leaf casts: the contact shadow past the rim and
/// the crease ramp short of the crease. Drawn in a layer of the leaf's own
/// size beneath the leaf and over the revealed page, with the leaf's
/// progress, direction and configuration. Nothing is drawn at rest.
struct MekuriLeafShadow: View {
    private let progress: CGFloat
    private let direction: MekuriDirection
    private let configuration: MekuriConfiguration

    init(progress: CGFloat, direction: MekuriDirection, configuration: MekuriConfiguration) {
        self.progress = progress
        self.direction = direction
        self.configuration = configuration
    }

    var isFolded: Bool { self.progress > 0 }

    var foldPass: MekuriFoldPass {
        MekuriFoldPass(direction: self.direction, progress: self.progress)
    }

    var body: some View {
        GeometryReader { proxy in
            if self.isFolded {
                self.shadowLayer(size: proxy.size)
            }
        }
    }

    /// The layer is opaque so it is never culled; the shader replaces every
    /// pixel of it and samples none.
    private func shadowLayer(size: CGSize) -> some View {
        let pass = self.foldPass
        return Color.black
            .compositingGroup()
            .layerEffect(self.shadow(size: size, pass: pass), maxSampleOffset: .zero)
            .scaleEffect(x: pass.mirrorScale, y: 1)
    }

    private func shadow(size: CGSize, pass: MekuriFoldPass) -> Shader {
        MekuriFoldShader.make(
            size: size,
            progress: pass.shaderProgress,
            configuration: self.configuration,
            face: .shadow,
            hinge: MekuriFoldShader.hinge(in: size)
        )
    }
}
