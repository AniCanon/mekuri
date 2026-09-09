import SwiftUI

/// Renders `content` folded by `progress`, 0 (flat) to 1 (turned). The crease
/// shadow is drawn by the shader; no further shadow may be layered on top.
public struct MekuriFoldedPage<Content: View>: View {
    private let progress: CGFloat
    private let direction: MekuriDirection
    private let configuration: MekuriConfiguration
    private let content: () -> Content

    public init(
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

    public var body: some View {
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
        let sweep = self.direction.sweep(progress: self.progress)
        let mirrored = sweep < 0
        let mirror: CGFloat = mirrored ? -1 : 1
        self.content()
            .scaleEffect(x: mirror, y: 1)
            .layerEffect(self.fold(size: size, progress: abs(sweep)), maxSampleOffset: size)
            .scaleEffect(x: mirror, y: 1)
    }

    private func fold(size: CGSize, progress: CGFloat) -> Shader {
        let geometry = MekuriFoldGeometry(pageWidth: size.width, configuration: self.configuration)
        let shadow = geometry.creaseShadowRect(progress: progress, pageSize: size)
        return ShaderLibrary.bundle(.module).mekuriFold(
            .float2(size),
            .float(progress),
            .float(size.width * self.configuration.cylinderRadiusRatio),
            .float(self.configuration.cornerShear),
            .float(self.configuration.backFaceDim),
            .float(shadow.width),
            .float(self.configuration.creaseShadowOpacity)
        )
    }
}
