import SwiftUI

private struct MekuriPagingEnabledKey: EnvironmentKey {
    static var defaultValue: Bool { true }
}

private struct MekuriOnCenterTapKey: EnvironmentKey {
    static var defaultValue: (() -> Void)? { nil }
}

extension EnvironmentValues {
    var mekuriPagingEnabled: Bool {
        get { self[MekuriPagingEnabledKey.self] }
        set { self[MekuriPagingEnabledKey.self] = newValue }
    }

    var mekuriOnCenterTap: (() -> Void)? {
        get { self[MekuriOnCenterTapKey.self] }
        set { self[MekuriOnCenterTapKey.self] = newValue }
    }
}

extension View {
    /// With paging off, drags and edge taps are ignored; centre taps still
    /// report.
    public func mekuriPagingEnabled(_ enabled: Bool) -> some View {
        self.environment(\.mekuriPagingEnabled, enabled)
    }

    /// Called for a tap in the centre zone. Mekuri does nothing else with it.
    public func mekuriOnCenterTap(_ action: @escaping () -> Void) -> some View {
        self.environment(\.mekuriOnCenterTap, action)
    }
}
