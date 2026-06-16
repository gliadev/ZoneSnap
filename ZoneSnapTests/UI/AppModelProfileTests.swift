//
//  AppModelProfileTests.swift
//  ZoneSnapTests
//
//  UI — tests de los perfiles de distribución (sobre el árbol BSP).
//

import Testing
import Foundation
import CoreGraphics
@testable import ZoneSnap

@Suite("AppModel — perfiles")
@MainActor
struct AppModelProfileTests {
    private func makeApp(repository: any ZoneConfigRepository) -> AppModel {
        AppModel(repository: repository, monitorProvider: StaticMonitorProvider(monitors: []))
    }

    private func sampleTree() -> ZoneNode {
        .split(id: UUID(), axis: .vertical, ratios: [1, 1],
               children: [.leaf(id: UUID()), .leaf(id: UUID())])
    }

    @Test("saveProfile guarda el árbol y persiste")
    func saveProfilePersists() async throws {
        let repo = InMemoryZoneConfigRepository()
        let app1 = makeApp(repository: repo)
        try await app1.saveProfile(name: "dev", tree: sampleTree())
        #expect(app1.profiles.count == 1)
        #expect(app1.profiles.first?.name == "dev")

        let app2 = makeApp(repository: repo)
        try await app2.loadConfig()
        #expect(app2.profiles.first?.name == "dev")
        #expect(app2.profiles.first?.tree.isLeaf == false) // es un split, se conservó
    }

    @Test("guardar con el mismo nombre actualiza, no duplica")
    func saveProfileUpserts() async throws {
        let app = makeApp(repository: InMemoryZoneConfigRepository())
        try await app.saveProfile(name: "dev", tree: sampleTree())
        let newTree = ZoneNode.leaf(id: UUID())
        try await app.saveProfile(name: "dev", tree: newTree)
        #expect(app.profiles.count == 1)
        #expect(app.profiles.first?.tree == newTree)
    }

    @Test("deleteProfile elimina el perfil")
    func deleteProfile() async throws {
        let app = makeApp(repository: InMemoryZoneConfigRepository())
        try await app.saveProfile(name: "dev", tree: .leaf(id: UUID()))
        let id = try #require(app.profiles.first?.id)
        try await app.deleteProfile(id)
        #expect(app.profiles.isEmpty)
    }

    @Test("un perfil se aplica igual a monitores de distinta resolución (ratios portables)")
    func portableAcrossResolutions() {
        let tree = sampleTree()
        let small = BSPCalculator.zones(of: tree, in: CGRect(x: 0, y: 0, width: 1000, height: 800))
        let large = BSPCalculator.zones(of: tree, in: CGRect(x: 0, y: 0, width: 3440, height: 1440))
        // Mismo nº de zonas y mismo reparto proporcional (mitad y mitad).
        #expect(small.count == 2)
        #expect(large.count == 2)
        #expect(abs(large[0].rect.width - 1720) < 0.001) // 3440 / 2
    }
}
