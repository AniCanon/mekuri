import CoreGraphics

/// Whether one or two pages share the container. `automatic` shows two when
/// they fit the container at the page aspect and each stays readable.
public enum MekuriSpread: Equatable, Sendable {
    case automatic
    case single
    case double

    /// Narrowest single page, in points, at which two pages stay readable.
    static let minimumDoublePageWidth: CGFloat = 320

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

/// One half of a spread, named in reading order.
enum MekuriSlot: Equatable, Sendable {
    case leading
    case trailing
}

/// The two-sided page a turn moves. `revealed` is the page uncovered in the
/// slot the leaf departs from; nil when that slot ends up absent.
struct MekuriLeaf: Equatable, Sendable {
    let front: Int
    let back: Int?
    let revealed: Int?
    let landsIn: MekuriSlot
}
