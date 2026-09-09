import SwiftUI

/// Builds the `mekuriFold` shader for one pass from the fold geometry.
enum MekuriFoldShader {
    /// Resolved once; a `Shader` value is built per call because progress is
    /// one of its arguments.
    private static let mekuriFold = ShaderLibrary.bundle(.module).mekuriFold

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
        return Self.mekuriFold(
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
