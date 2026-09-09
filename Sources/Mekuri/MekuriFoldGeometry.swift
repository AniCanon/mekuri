import CoreGraphics

/// Pure fold arithmetic in page space. Progress runs 0 (flat) to 1 (turned);
/// the fold axis travels from the trailing edge to the leading edge.
struct MekuriFoldGeometry: Equatable, Sendable {
    let pageWidth: CGFloat
    let configuration: MekuriConfiguration

    init(pageWidth: CGFloat, configuration: MekuriConfiguration) {
        self.pageWidth = pageWidth
        self.configuration = configuration
    }

    /// Horizontal position of the fold axis. Out-of-range progress clamps to 0...1.
    func foldAxisOffset(progress: CGFloat) -> CGFloat {
        self.pageWidth * (1 - min(max(progress, 0), 1))
    }

    func isFlat(progress: CGFloat) -> Bool {
        progress <= 0
    }

    /// Full-height band centred on the fold axis.
    func creaseShadowRect(progress: CGFloat, pageSize: CGSize) -> CGRect {
        let width = self.pageWidth * self.configuration.creaseShadowWidthRatio
        let axis = self.foldAxisOffset(progress: progress)
        return CGRect(x: axis - width / 2, y: 0, width: width, height: pageSize.height)
    }
}
