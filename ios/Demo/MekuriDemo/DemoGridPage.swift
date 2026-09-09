import SwiftUI

/// The panelled pages: each is a list of panel specs on the unit square.
enum DemoPageLayout {
    case fourGrid
    case threePanel
    case ending

    var panels: [DemoPanelSpec] {
        switch self {
        case .fourGrid:
            [
                DemoPanelSpec(frame: CGRect(x: 0, y: 0, width: 0.5, height: 0.5), art: .figure(.standing, tone: true), bubble: DemoBubbleSpec(text: "A page is a leaf.", tail: .bottomLeading, anchor: UnitPoint(x: 0.5, y: 0.24))),
                DemoPanelSpec(frame: CGRect(x: 0.5, y: 0, width: 0.5, height: 0.5), art: .broadcast),
                DemoPanelSpec(frame: CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5), art: .speed(.running), sound: DemoSoundSpec(text: "FWIP", anchor: UnitPoint(x: 0.5, y: 0.2))),
                DemoPanelSpec(frame: CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5), art: .figure(.pointing, tone: false), bubble: DemoBubbleSpec(text: "Corner first.", tail: .bottomLeading, anchor: UnitPoint(x: 0.5, y: 0.24))),
            ]
        case .threePanel:
            [
                DemoPanelSpec(frame: CGRect(x: 0, y: 0, width: 1, height: 0.42), art: .skyline, caption: "The city, later."),
                DemoPanelSpec(frame: CGRect(x: 0, y: 0.42, width: 0.5, height: 0.58), art: .figure(.reading, tone: true), bubble: DemoBubbleSpec(text: "It bends around a cylinder.", tail: .bottomTrailing, anchor: UnitPoint(x: 0.5, y: 0.2))),
                DemoPanelSpec(frame: CGRect(x: 0.5, y: 0.42, width: 0.5, height: 0.58), art: .broadcast),
            ]
        case .ending:
            [
                DemoPanelSpec(frame: CGRect(x: 0, y: 0, width: 0.5, height: 1 / 3), art: .moon),
                DemoPanelSpec(frame: CGRect(x: 0.5, y: 0, width: 0.5, height: 1 / 3), art: .figure(.standing, tone: false), bubble: DemoBubbleSpec(text: "Both faces, one sheet.", tail: .bottomLeading, anchor: UnitPoint(x: 0.5, y: 0.26))),
                DemoPanelSpec(frame: CGRect(x: 0, y: 1 / 3, width: 0.5, height: 1 / 3), art: .broadcast),
                DemoPanelSpec(frame: CGRect(x: 0.5, y: 1 / 3, width: 0.5, height: 1 / 3), art: .speed(nil), sound: DemoSoundSpec(text: "FLIP", burst: true)),
                DemoPanelSpec(frame: CGRect(x: 0, y: 2 / 3, width: 0.5, height: 1 / 3), art: .figure(.pointing, tone: true), caption: "Last page."),
                DemoPanelSpec(frame: CGRect(x: 0.5, y: 2 / 3, width: 0.5, height: 1 / 3), art: .ending),
            ]
        }
    }
}

struct DemoGridPage: View {
    let layout: DemoPageLayout
    let scale: CGFloat

    var body: some View {
        let panels = self.layout.panels
        DemoPanelGrid(frames: panels.map(\.frame)) { index in
            DemoPanelView(spec: panels[index], scale: self.scale)
        }
    }
}
