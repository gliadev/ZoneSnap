//
//  ZoneConfigTests.swift
//  ZoneSnapTests
//
//  Domain — tests del documento de configuración.
//

import Testing
import Foundation
import CoreGraphics
@testable import ZoneSnap

@Suite("ZoneConfig")
struct ZoneConfigTests {
    private func makeConfig() -> ZoneConfig {
        let zones = [
            Zone(rect: CGRect(x: 0, y: 0, width: 960, height: 1080), name: "L"),
            Zone(rect: CGRect(x: 960, y: 0, width: 960, height: 1080), name: "R")
        ]
        let layout = Layout(name: "Mitades", grid: ZoneGrid(zones: zones))
        let monitor = Monitor(name: "Built-in", resolution: CGSize(width: 1920, height: 1080))
        return ZoneConfig(monitors: [MonitorLayout(monitor: monitor, layout: layout)])
    }

    @Test("round-trip Codable del documento completo")
    func codableRoundTrip() throws {
        let config = makeConfig()
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(ZoneConfig.self, from: data)
        #expect(decoded == config)
    }

    @Test("la versión por defecto es la actual")
    func defaultVersion() {
        #expect(ZoneConfig().version == ZoneConfig.currentVersion)
    }

    @Test("la identidad de MonitorLayout es la del monitor")
    func monitorLayoutIdentity() {
        let monitor = Monitor(resolution: CGSize(width: 100, height: 100))
        let pairing = MonitorLayout(monitor: monitor, layout: Layout(name: "x", grid: ZoneGrid()))
        #expect(pairing.id == monitor.id)
    }
}
