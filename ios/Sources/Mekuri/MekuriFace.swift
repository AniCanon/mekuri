/// Which face of the leaf one `mekuriFold` pass draws. The raw value is the
/// shader's `face` argument.
enum MekuriFace: Float {
    case whole = 0
    case front = 1
    case back = 2
    case shadow = 3
}
