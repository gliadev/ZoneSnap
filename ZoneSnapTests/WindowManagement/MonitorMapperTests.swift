//
//  MonitorMapperTests.swift
//  ZoneSnapTests
//
//  WindowManagement — tests del mapeo de pantallas a Monitor.
//

import Testing
import Foundation
import CoreGraphics
@testable import ZoneSnap

@Suite("MonitorMapper")
struct MonitorMapperTests {
    @Test("mapea cada pantalla a un Monitor conservando id, nombre y tamaño")
    func mapsScreensToMonitors() {
        let uuid = UUID()
        let raw = RawScreen(displayUUID: uuid, name: "LG UltraWide", size: CGSize(width: 3440, height: 1440))
        let monitors = MonitorMapper.monitors(from: [raw])

        #expect(monitors.count == 1)
        #expect(monitors.first?.id == uuid)
        #expect(monitors.first?.name == "LG UltraWide")
        #expect(monitors.first?.resolution == CGSize(width: 3440, height: 1440))
    }

    @Test("la identidad del Monitor proviene del display (estable)")
    func monitorIdentityComesFromDisplay() {
        let uuid = UUID()
        let raw = RawScreen(displayUUID: uuid, name: nil, size: CGSize(width: 1920, height: 1080))
        // Mapear dos veces el mismo display produce el mismo id.
        let first = MonitorMapper.monitors(from: [raw]).first
        let second = MonitorMapper.monitors(from: [raw]).first
        #expect(first?.id == uuid)
        #expect(first?.id == second?.id)
    }

    @Test("sin pantallas devuelve una lista vacía")
    func emptyScreensYieldNoMonitors() {
        #expect(MonitorMapper.monitors(from: []).isEmpty)
    }

    @Test("preserva el orden de las pantallas")
    func preservesOrder() {
        let a = RawScreen(displayUUID: UUID(), name: "A", size: CGSize(width: 100, height: 100))
        let b = RawScreen(displayUUID: UUID(), name: "B", size: CGSize(width: 200, height: 200))
        let monitors = MonitorMapper.monitors(from: [a, b])
        #expect(monitors.map(\.name) == ["A", "B"])
    }
}
