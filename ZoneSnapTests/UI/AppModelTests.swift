//
//  AppModelTests.swift
//  ZoneSnapTests
//
//  UI — tests del estado de app (monitores + persistencia).
//

import Testing
import Foundation
import CoreGraphics
@testable import ZoneSnap

@Suite("AppModel")
@MainActor
struct AppModelTests {
    private func monitor(_ name: String, _ width: CGFloat, _ height: CGFloat) -> Monitor {
        Monitor(name: name, resolution: CGSize(width: width, height: height))
    }

    private func makeApp(
        monitors: [Monitor],
        repository: any ZoneConfigRepository = InMemoryZoneConfigRepository()
    ) -> AppModel {
        AppModel(repository: repository, monitorProvider: StaticMonitorProvider(monitors: monitors))
    }

    @Test("refreshMonitors carga los monitores y selecciona el primero")
    func refreshSelectsFirst() async {
        let m = [monitor("A", 1920, 1080), monitor("B", 3440, 1440)]
        let app = makeApp(monitors: m)
        await app.refreshMonitors()
        #expect(app.monitors.count == 2)
        #expect(app.selectedMonitorID == m.first?.id)
    }

    @Test("save y luego savedZones devuelven las zonas guardadas")
    func saveAndRead() async throws {
        let mon = monitor("A", 1920, 1080)
        let app = makeApp(monitors: [mon])
        let zones = [
            Zone(rect: CGRect(x: 0, y: 0, width: 960, height: 1080)),
            Zone(rect: CGRect(x: 960, y: 0, width: 960, height: 1080))
        ]
        try await app.save(zones: zones, for: mon)
        #expect(app.savedZones(for: mon.id).count == 2)
    }

    @Test("save persiste: otra instancia con el mismo repo lee las zonas")
    func savePersists() async throws {
        let repo = InMemoryZoneConfigRepository()
        let mon = monitor("A", 1920, 1080)
        let app1 = makeApp(monitors: [mon], repository: repo)
        try await app1.save(zones: [Zone(rect: CGRect(x: 0, y: 0, width: 100, height: 100))], for: mon)

        let app2 = makeApp(monitors: [mon], repository: repo)
        try await app2.loadConfig()
        #expect(app2.savedZones(for: mon.id).count == 1)
    }

    @Test("setLayout actualiza en memoria sin persistir a disco")
    func setLayoutInMemoryOnly() async throws {
        let repo = InMemoryZoneConfigRepository()
        let mon = monitor("A", 1920, 1080)
        let app1 = makeApp(monitors: [mon], repository: repo)
        app1.setLayout(zones: [Zone(rect: CGRect(x: 0, y: 0, width: 100, height: 100))], for: mon)

        #expect(app1.savedZones(for: mon.id).count == 1) // en memoria sí

        let app2 = makeApp(monitors: [mon], repository: repo)
        try await app2.loadConfig()
        #expect(app2.savedZones(for: mon.id).isEmpty) // en disco no
    }

    @Test("guardar sobre un monitor existente reemplaza (no duplica)")
    func saveUpserts() async throws {
        let mon = monitor("A", 1920, 1080)
        let app = makeApp(monitors: [mon])
        try await app.save(zones: [Zone(rect: .zero)], for: mon)
        try await app.save(zones: [Zone(rect: .zero), Zone(rect: .zero)], for: mon)
        #expect(app.config.monitors.count == 1)
        #expect(app.savedZones(for: mon.id).count == 2)
    }

    @Test("savedZones de un monitor sin layout es vacío")
    func savedZonesEmptyWhenNoLayout() async {
        let mon = monitor("A", 1920, 1080)
        let app = makeApp(monitors: [mon])
        #expect(app.savedZones(for: mon.id).isEmpty)
    }
}
