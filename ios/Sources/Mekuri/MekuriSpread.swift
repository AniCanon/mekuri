import CoreGraphics

/// Whether one or two pages share the container. `automatic` shows two when
/// the pair, laid out to fit, stays readable and fills the container.
public enum MekuriSpread: Equatable, Sendable {
    /// Two pages when the fitted page is at least `minimumDoublePageWidth`
    /// wide and the pair covers at least `minimumDoubleFillFraction` of the
    /// container's height; otherwise one.
    case automatic
    /// One page across the container, whatever its size.
    case single
    /// Two pages side by side, scaled to fit the container.
    case double

    /// Narrowest fitted page, in points, at which two pages stay readable.
    static let minimumDoublePageWidth: CGFloat = 270

    /// Smallest share of the container's height a fitted pair may cover.
    static let minimumDoubleFillFraction: CGFloat = 0.6

    /// `pageAspectRatio` is width over height. Under `.automatic`, the pages
    /// are fitted by `pageSize(fitting:pageAspectRatio:)` and the fitted page
    /// must be at least `minimumDoublePageWidth` wide and at least
    /// `minimumDoubleFillFraction` of the container's height tall.
    func isDouble(containerSize: CGSize, pageAspectRatio: CGFloat) -> Bool {
        switch self {
        case .single: return false
        case .double: return true
        case .automatic:
            let page = Self.pageSize(fitting: containerSize, pageAspectRatio: pageAspectRatio)
            return page.width >= Self.minimumDoublePageWidth
                && page.height >= containerSize.height * Self.minimumDoubleFillFraction
        }
    }

    /// Largest page at `pageAspectRatio` such that two of them, side by
    /// side, fit the container. `pageAspectRatio` must be positive.
    static func pageSize(fitting containerSize: CGSize, pageAspectRatio: CGFloat) -> CGSize {
        let height = min(containerSize.height, containerSize.width / (2 * pageAspectRatio))
        return CGSize(width: height * pageAspectRatio, height: height)
    }
}
