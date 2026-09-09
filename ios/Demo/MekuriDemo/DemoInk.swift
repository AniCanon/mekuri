import SwiftUI

/// Palette, strokes and type shared by every drawn page: ink on off-white
/// paper, one accent for what is live.
enum DemoInk {
    static let paper = Color(red: 0.97, green: 0.95, blue: 0.90)
    static let ink = Color(red: 0.12, green: 0.11, blue: 0.10)
    static let accent = Color(red: 0.80, green: 0.22, blue: 0.16)

    static let panelStroke: CGFloat = 3
    static let bubbleStroke: CGFloat = 2.5
    static let gutter: CGFloat = 12
    static let margin: CGFloat = 18

    static func sfx(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    static func narration(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }

    static func speech(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func title(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .serif)
    }
}
