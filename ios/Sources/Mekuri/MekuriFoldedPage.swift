import SwiftUI

/// Renders `content` folded by `progress`, 0 (flat) to 1 (turned). The crease
/// and contact shadows are drawn by the shader; no further shadow may be
/// layered on top. The content is flattened into one layer before the shader
/// runs; the shader's translucent output composites exactly once.
struct MekuriFoldedPage<Content: View>: View {
    private let progress: CGFloat
    private let direction: MekuriDirection
    private let configuration: MekuriConfiguration
    private let liftsFromBottom: Bool
    private let content: () -> Content

    init(
        progress: CGFloat,
        direction: MekuriDirection,
        configuration: MekuriConfiguration,
        liftsFromBottom: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.progress = progress
        self.direction = direction
        self.configuration = configuration
        self.liftsFromBottom = liftsFromBottom
        self.content = content
    }

    var isFolded: Bool { self.progress > 0 }

    var foldPass: MekuriFoldPass {
        MekuriFoldPass(direction: self.direction, progress: self.progress, liftsFromBottom: self.liftsFromBottom)
    }

    var body: some View {
        GeometryReader { proxy in
            if self.isFolded {
                self.foldedContent(size: proxy.size)
            } else {
                self.content()
            }
        }
    }

    @ViewBuilder
    private func foldedContent(size: CGSize) -> some View {
        let pass = self.foldPass
        self.content()
            .scaleEffect(x: pass.mirrorScale, y: pass.verticalScale)
            .compositingGroup()
            .layerEffect(self.fold(size: size, progress: pass.shaderProgress), maxSampleOffset: size)
            .scaleEffect(x: pass.mirrorScale, y: pass.verticalScale)
    }

    private func fold(size: CGSize, progress: CGFloat) -> Shader {
        MekuriFoldShader.make(size: size, progress: progress, configuration: self.configuration, face: .whole)
    }
}
