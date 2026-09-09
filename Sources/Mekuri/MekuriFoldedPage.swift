import SwiftUI

/// Renders `content` folded by `progress`, 0 (flat) to 1 (turned). The crease
/// and contact shadows are drawn by the shader; no further shadow may be
/// layered on top. The content is flattened into one layer before the shader
/// runs; the shader's translucent output composites exactly once.
struct MekuriFoldedPage<Content: View>: View {
    private let progress: CGFloat
    private let direction: MekuriDirection
    private let configuration: MekuriConfiguration
    private let content: () -> Content

    init(
        progress: CGFloat,
        direction: MekuriDirection,
        configuration: MekuriConfiguration,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.progress = progress
        self.direction = direction
        self.configuration = configuration
        self.content = content
    }

    var isFolded: Bool { self.progress > 0 }

    var foldPass: MekuriFoldPass {
        MekuriFoldPass(direction: self.direction, progress: self.progress)
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
            .scaleEffect(x: pass.mirrorScale, y: 1)
            .compositingGroup()
            .layerEffect(self.fold(size: size, progress: pass.shaderProgress), maxSampleOffset: size)
            .scaleEffect(x: pass.mirrorScale, y: 1)
    }

    private func fold(size: CGSize, progress: CGFloat) -> Shader {
        MekuriFoldShader.make(size: size, progress: progress, configuration: self.configuration, face: .whole)
    }
}

/// Which face of the leaf one `mekuriFold` pass draws. The raw value is the
/// shader's `face` argument.
enum MekuriFace: Float {
    case whole = 0
    case front = 1
    case back = 2
}

enum MekuriFoldShader {
    /// `progress` is the shader's own, never negative; `size` is the layer
    /// size and the page width.
    static func make(
        size: CGSize,
        progress: CGFloat,
        configuration: MekuriConfiguration,
        face: MekuriFace
    ) -> Shader {
        let geometry = MekuriFoldGeometry(pageWidth: size.width, configuration: configuration)
        let shadow = geometry.creaseShadowRect(progress: progress, pageSize: size)
        return ShaderLibrary.bundle(.module).mekuriFold(
            .float2(size),
            .float(progress),
            .float(geometry.heldRadius),
            .float(geometry.radiusSlope),
            .float(configuration.cornerShear),
            .float(configuration.creaseBow),
            .float(configuration.backFaceDim),
            .float(shadow.width),
            .float(configuration.creaseShadowOpacity),
            .float(CGFloat(face.rawValue))
        )
    }
}
