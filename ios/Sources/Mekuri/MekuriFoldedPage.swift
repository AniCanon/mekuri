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
    case shadow = 3
}

enum MekuriFoldShader {
    /// `progress` is the shader's own, never negative. `hinge` is the
    /// distance from the layer's leading edge to the spine a leaf turns on,
    /// nil for a page folded across the whole layer. A hinged leaf's page is
    /// the layer past the hinge; its sweep stops at the hinge, and its roll
    /// and corner shear flatten as it lands so the crease meets the hinge.
    /// Unhinged arguments reach the shader untouched.
    static func make(
        size: CGSize,
        progress: CGFloat,
        configuration: MekuriConfiguration,
        face: MekuriFace,
        hinge: CGFloat? = nil
    ) -> Shader {
        let sweep = hinge.map {
            MekuriHingedSweep(progress: progress, creaseBow: configuration.creaseBow, spine: $0, layerWidth: size.width)
        }
        let geometry = MekuriFoldGeometry(pageWidth: size.width - (hinge ?? 0), configuration: configuration)
        let shadow = geometry.creaseShadowRect(progress: progress, pageSize: size)
        let landing = hinge == nil ? 1 : geometry.landingRadiusScale(progress: progress)
        return ShaderLibrary.bundle(.module).mekuriFold(
            .float2(size),
            .float(sweep?.shaderProgress ?? progress),
            .float(geometry.heldRadius * landing),
            .float(geometry.radiusSlope * landing),
            .float(configuration.cornerShear * landing),
            .float(sweep?.creaseBow ?? configuration.creaseBow),
            .float(configuration.backFaceDim),
            .float(shadow.width),
            .float(configuration.creaseShadowOpacity),
            .float(CGFloat(face.rawValue))
        )
    }

    /// A leaf spans a two-slot spread and hinges at its centre.
    static func hinge(in size: CGSize) -> CGFloat {
        size.width / 2
    }
}

/// The shader sweeps its axis across the whole layer. A leaf hinged `spine`
/// points from the leading edge sweeps only the page past the hinge, so its
/// progress is scaled by that share of the layer and its bow rescaled so the
/// crease is straight again at the end of the turn. Progress clamps to
/// 0...1; `spine` must be positive.
struct MekuriHingedSweep: Equatable {
    let shaderProgress: CGFloat
    let creaseBow: CGFloat

    init(progress: CGFloat, creaseBow: CGFloat, spine: CGFloat, layerWidth: CGFloat) {
        let progress = min(max(progress, 0), 1)
        let shaderProgress = progress * (layerWidth - spine) / layerWidth
        self.shaderProgress = shaderProgress
        self.creaseBow = creaseBow * (1 - progress) / (1 - shaderProgress)
    }
}
