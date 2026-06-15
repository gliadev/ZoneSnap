//
//  StaticMonitorProvider.swift
//  ZoneSnap
//
//  WindowManagement — proveedor de monitores fijo (previews y tests).
//

import Foundation

/// Implementación de `MonitorProviding` con una lista fija de monitores. Útil
/// para previews de SwiftUI y para tests, sin depender de `NSScreen`.
struct StaticMonitorProvider: MonitorProviding {
    let monitors: [Monitor]

    init(monitors: [Monitor]) {
        self.monitors = monitors
    }

    func currentMonitors() async -> [Monitor] {
        monitors
    }
}
