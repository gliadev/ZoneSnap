//
//  AppModelLayoutModelTests.swift
//  ZoneSnapTests
//
//  UI — tests de la persistencia del modelo del editor (líneas + fusiones).
//

import Testing
import Foundation
import CoreGraphics
@testable import ZoneSnap

@Suite("AppModel — modelo del editor")
@MainActor
struct AppModelLayoutModelTests {
    private func monitor() -> Monitor {
        Monitor(name: "A", resolution: CGSize(width: 1000, height: 800))
    }

    @Test("save/load conserva líneas y fusiones del editor")
    func persistsLinesAndMerges() async throws {
        let repo = InMemoryZoneConfigRepository()
        let mon = monitor()
        let lines = [GridLine(orientation: .vertical, position: 500)]
        let merges = [[GridCell(row: 0, col: 0), GridCell(row: 0, col: 1)]]
        let zones = ZoneCalculator.zones(
            in: CGRect(x: 0, y: 0, width: 1000, height: 800),
            lines: lines,
            merges: merges
        )

        let app1 = AppModel(repository: repo, monitorProvider: StaticMonitorProvider(monitors: [mon]))
        app1.setLayout(zones: zones, lines: lines, merges: merges, for: mon)
        try await app1.persist()

        let app2 = AppModel(repository: repo, monitorProvider: StaticMonitorProvider(monitors: [mon]))
        try await app2.loadConfig()
        let layout = try #require(app2.savedLayout(for: mon.id))
        #expect(layout.lines == lines)
        #expect(layout.merges == merges)
    }
}
