import SwiftUI

/// Look of one demo page. Each page has a distinct hue and glyph.
struct DemoPageStyle {
    let name: String
    let paper: Color
    let ink: Color
    let glyph: String

    static let all: [DemoPageStyle] = [
        DemoPageStyle(name: "Sakura", paper: Color(hue: 0.95, saturation: 0.30, brightness: 1.00), ink: Color(hue: 0.95, saturation: 0.75, brightness: 0.55), glyph: "circle.fill"),
        DemoPageStyle(name: "Mikan", paper: Color(hue: 0.08, saturation: 0.35, brightness: 1.00), ink: Color(hue: 0.08, saturation: 0.90, brightness: 0.60), glyph: "triangle.fill"),
        DemoPageStyle(name: "Wakaba", paper: Color(hue: 0.30, saturation: 0.30, brightness: 0.95), ink: Color(hue: 0.33, saturation: 0.80, brightness: 0.40), glyph: "square.fill"),
        DemoPageStyle(name: "Sora", paper: Color(hue: 0.58, saturation: 0.30, brightness: 1.00), ink: Color(hue: 0.60, saturation: 0.85, brightness: 0.55), glyph: "diamond.fill"),
        DemoPageStyle(name: "Fuji", paper: Color(hue: 0.75, saturation: 0.25, brightness: 1.00), ink: Color(hue: 0.75, saturation: 0.70, brightness: 0.50), glyph: "hexagon.fill"),
        DemoPageStyle(name: "Sumi", paper: Color(white: 0.92), ink: Color(white: 0.15), glyph: "star.fill"),
    ]

    static var count: Int { self.all.count }

    static func style(for index: Int) -> DemoPageStyle {
        self.all[index % self.all.count]
    }
}
