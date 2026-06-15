//
//  ZoneTests.swift
//  ZoneSnapTests
//
//  Domain — tests de la zona individual.
//

import Testing
import Foundation
import CoreGraphics
@testable import ZoneSnap

@Suite("Zone")
struct ZoneTests {
    @Test("La identidad es estable aunque cambie el rect")
    func stableIdentity() {
        let id = UUID()
        var zone = Zone(id: id, rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        zone.rect = CGRect(x: 50, y: 50, width: 100, height: 100)
        #expect(zone.id == id)
    }

    @Test("center calcula el punto medio del rect")
    func center() {
        let zone = Zone(rect: CGRect(x: 0, y: 0, width: 100, height: 200))
        #expect(zone.center == CGPoint(x: 50, y: 100))
    }

    @Test("contains distingue puntos dentro y fuera")
    func contains() {
        let zone = Zone(rect: CGRect(x: 0, y: 0, width: 100, height: 100))
        #expect(zone.contains(CGPoint(x: 50, y: 50)))
        #expect(!zone.contains(CGPoint(x: 150, y: 50)))
    }

    @Test("round-trip Codable preserva todos los valores")
    func codableRoundTrip() throws {
        let zone = Zone(rect: CGRect(x: 10, y: 20, width: 30, height: 40), name: "Editor")
        let data = try JSONEncoder().encode(zone)
        let decoded = try JSONDecoder().decode(Zone.self, from: data)
        #expect(decoded == zone)
    }
}
