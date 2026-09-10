import CoreGraphics

/// Whether one or two pages share the container. `automatic` shows two when
/// they fit the container at the page aspect and each stays readable.
public enum MekuriSpread: Equatable, Sendable {
    /// Two pages when they fit the container at the page aspect and each is at
    /// least `minimumDoublePageWidth` wide; otherwise one.
    case automatic
    /// One page across the container, whatever its size.
    case single
    /// Two pages side by side, scaled to fit the container.
    case double

    /// Narrowest single page, in points, at which two pages stay readable.
    static let minimumDoublePageWidth: CGFloat = 275

    /// `pageAspectRatio` is width over height. Under `.automatic`, two pages
    /// laid out to the container's height must fit its width and each must
    /// be at least `minimumDoublePageWidth` wide.
    func isDouble(containerSize: CGSize, pageAspectRatio: CGFloat) -> Bool {
        switch self {
        case .single: return false
        case .double: return true
        case .automatic:
            let pageWidth = containerSize.height * pageAspectRatio
            return containerSize.width >= 2 * pageWidth && pageWidth >= Self.minimumDoublePageWidth
        }
    }

    /// Largest page at `pageAspectRatio` such that two of them, side by
    /// side, fit the container. `pageAspectRatio` must be positive.
    static func pageSize(fitting containerSize: CGSize, pageAspectRatio: CGFloat) -> CGSize {
        let height = min(containerSize.height, containerSize.width / (2 * pageAspectRatio))
        return CGSize(width: height * pageAspectRatio, height: height)
    }
}
