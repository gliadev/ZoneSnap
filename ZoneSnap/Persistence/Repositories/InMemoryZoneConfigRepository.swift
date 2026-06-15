//
//  InMemoryZoneConfigRepository.swift
//  ZoneSnap
//
//  Persistence — repositorio en memoria para previews y tests.
//

import Foundation

/// Implementación en memoria de `ZoneConfigRepository`. No toca el disco; útil
/// para previews de SwiftUI y para tests rápidos.
actor InMemoryZoneConfigRepository: ZoneConfigRepository {
    private var stored: ZoneConfig?

    init(initial: ZoneConfig? = nil) {
        stored = initial
    }

    func load() async throws -> ZoneConfig {
        stored ?? ZoneConfig()
    }

    func save(_ config: ZoneConfig) async throws {
        stored = config
    }
}
