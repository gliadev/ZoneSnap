//
//  AppModelProfileTests.swift
//  ZoneSnapTests
//
//  UI — tests de los perfiles de distribución.
//

import Testing
import Foundation
import CoreGraphics
@testable import ZoneSnap

@Suite("AppModel — perfiles")
@MainActor
struct AppModelProfileTests {
    private let bounds = CGRect(x: 0, y: 0, width: 1000, height: 800)

    private func makeApp(repository: any ZoneConfigRepository) -> AppModel {
        AppModel(repository: repository, monitorProvider: StaticMonitorProvider(monitors: []))
    }

    @Test("saveProfile guarda (normalizado) y persiste")
    func saveProfilePersists() async throws {
        let repo = InMemoryZoneConfigRepository()
        let app1 = makeApp(repository: repo)
        try await app1.saveProfile(name: "dev", lines: [GridLine(orientation: .vertical, position: 700)], bounds: bounds)
        #expect(app1.profiles.count == 1)
        #expect(app1.profiles.first?.name == "dev")

        let app2 = makeApp(repository: repo)
        try await app2.loadConfig()
        #expect(app2.profiles.first?.name == "dev")
        #expect(app2.profiles.first?.lines.first?.position == 0.7) // 700/1000
    }

    @Test("guardar con el mismo nombre actualiza, no duplica")
    func saveProfileUpserts() async throws {
        let app = makeApp(repository: InMemoryZoneConfigRepository())
        try await app.saveProfile(name: "dev", lines: [GridLine(orientation: .vertical, position: 500)], bounds: bounds)
        try await app.saveProfile(name: "dev", lines: [GridLine(orientation: .vertical, position: 250)], bounds: bounds)
        #expect(app.profiles.count == 1)
        #expect(app.profiles.first?.lines.first?.position == 0.25)
    }

    @Test("deleteProfile elimina el perfil")
    func deleteProfile() async throws {
        let app = makeApp(repository: InMemoryZoneConfigRepository())
        try await app.saveProfile(name: "dev", lines: [], bounds: bounds)
        let id = try #require(app.profiles.first?.id)
        try await app.deleteProfile(id)
        #expect(app.profiles.isEmpty)
    }
}

@Suite("EditorViewModel — aplicar perfil")
@MainActor
struct EditorViewModelApplyTests {
    @Test("applyLines sustituye las líneas y recalcula la preview")
    func applyLinesReplaces() {
        let vm = EditorViewModel(bounds: CGRect(x: 0, y: 0, width: 1000, height: 800))
        vm.applyLines([
            GridLine(orientation: .vertical, position: 500),
            GridLine(orientation: .horizontal, position: 400)
        ])
        #expect(vm.lines.count == 2)
        #expect(vm.previewZones.count == 4)
    }
}
