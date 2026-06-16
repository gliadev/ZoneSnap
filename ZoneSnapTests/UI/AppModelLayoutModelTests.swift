//
//  AppModelLayoutModelTests.swift
//  ZoneSnapTests
//
//  UI — tests de la persistencia del modelo del editor (árbol de subdivisión).
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

    @Test("save/load conserva el árbol del editor")
    func persistsTree() async throws {
        let repo = InMemoryZoneConfigRepository()
        let mon = monitor()
        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let root = ZoneNode.leaf(id: UUID())
        let tree = BSPCalculator.subdivide(root, leaf: root.id, columns: 2, rows: 1)
        let zones = BSPCalculator.zones(of: tree, in: bounds)

        let app1 = AppModel(repository: repo, monitorProvider: StaticMonitorProvider(monitors: [mon]))
        app1.setLayout(zones: zones, tree: tree, for: mon)
        try await app1.persist()

        let app2 = AppModel(repository: repo, monitorProvider: StaticMonitorProvider(monitors: [mon]))
        try await app2.loadConfig()
        let layout = try #require(app2.savedLayout(for: mon.id))
        #expect(layout.tree == tree)
    }
}
