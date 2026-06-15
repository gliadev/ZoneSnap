//
//  LocalZoneConfigRepositoryTests.swift
//  ZoneSnapTests
//
//  Persistence — tests del repositorio local de configuración.
//

import Testing
import Foundation
import CoreGraphics
@testable import ZoneSnap

@Suite("LocalZoneConfigRepository")
struct LocalZoneConfigRepositoryTests {
    /// Directorio temporal único para aislar cada test.
    private func makeTempDirectory() -> URL {
        URL.temporaryDirectory.appending(
            path: "ZoneSnapTests-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
    }

    private func sampleConfig() -> ZoneConfig {
        let zones = [
            Zone(rect: CGRect(x: 0, y: 0, width: 960, height: 1080), name: "L"),
            Zone(rect: CGRect(x: 960, y: 0, width: 960, height: 1080), name: "R")
        ]
        let layout = Layout(name: "Mitades", grid: ZoneGrid(zones: zones))
        let monitor = Monitor(name: "Built-in", resolution: CGSize(width: 1920, height: 1080))
        return ZoneConfig(monitors: [MonitorLayout(monitor: monitor, layout: layout)])
    }

    @Test("save y load hacen round-trip de la configuración")
    func saveLoadRoundTrip() async throws {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let repo = LocalZoneConfigRepository(directory: dir)

        let config = sampleConfig()
        try await repo.save(config)
        let loaded = try await repo.load()
        #expect(loaded == config)
    }

    @Test("load sin fichero devuelve la configuración por defecto")
    func loadMissingReturnsDefault() async throws {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let repo = LocalZoneConfigRepository(directory: dir)

        let loaded = try await repo.load()
        #expect(loaded == ZoneConfig())
        #expect(loaded.monitors.isEmpty)
    }

    @Test("save crea el directorio si no existe")
    func saveCreatesDirectory() async throws {
        let base = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: base) }
        let dir = base.appending(path: "nested/config", directoryHint: .isDirectory)
        let repo = LocalZoneConfigRepository(directory: dir)

        try await repo.save(sampleConfig())

        let file = dir.appending(path: "zones.json", directoryHint: .notDirectory)
        #expect(FileManager.default.fileExists(atPath: file.path(percentEncoded: false)))
    }

    @Test("load lanza unsupportedVersion si el formato en disco es más nuevo")
    func loadRejectsNewerVersion() async throws {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let future = ZoneConfig.currentVersion + 1
        let json = #"{"version": \#(future), "monitors": []}"#
        let file = dir.appending(path: "zones.json", directoryHint: .notDirectory)
        try Data(json.utf8).write(to: file)

        let repo = LocalZoneConfigRepository(directory: dir)
        await #expect(throws: ZoneConfigRepositoryError.unsupportedVersion(
            found: future,
            supported: ZoneConfig.currentVersion
        )) {
            try await repo.load()
        }
    }

    @Test("save sobrescribe la configuración anterior")
    func saveOverwrites() async throws {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let repo = LocalZoneConfigRepository(directory: dir)

        try await repo.save(sampleConfig())
        let empty = ZoneConfig()
        try await repo.save(empty)

        let loaded = try await repo.load()
        #expect(loaded == empty)
        #expect(loaded.monitors.isEmpty)
    }
}
