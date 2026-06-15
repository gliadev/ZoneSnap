//
//  LayoutProfileMapperTests.swift
//  ZoneSnapTests
//
//  Domain — tests de la normalización de perfiles.
//

import Testing
import CoreGraphics
@testable import ZoneSnap

@Suite("LayoutProfileMapper")
struct LayoutProfileMapperTests {
    private let bounds = CGRect(x: 0, y: 0, width: 1000, height: 800)

    @Test("normaliza una línea a fracción del lado")
    func normalizesToFraction() {
        let lines = [
            GridLine(orientation: .vertical, position: 250),   // 25% de 1000
            GridLine(orientation: .horizontal, position: 600)  // 75% de 800
        ]
        let normalized = LayoutProfileMapper.normalize(lines, in: bounds)
        #expect(normalized[0].position == 0.25)
        #expect(normalized[1].position == 0.75)
    }

    @Test("round-trip normalize → denormalize conserva las posiciones")
    func roundTrip() {
        let lines = [
            GridLine(orientation: .vertical, position: 300),
            GridLine(orientation: .horizontal, position: 200)
        ]
        let back = LayoutProfileMapper.denormalize(
            LayoutProfileMapper.normalize(lines, in: bounds),
            in: bounds
        )
        #expect(back.map(\.position) == [300, 200])
        #expect(back.map(\.orientation) == [.vertical, .horizontal])
    }

    @Test("el mismo perfil se adapta a un monitor de distinta resolución")
    func portableAcrossResolutions() {
        let lines = [GridLine(orientation: .vertical, position: 500)] // 50% de 1000
        let normalized = LayoutProfileMapper.normalize(lines, in: bounds)

        let bigMonitor = CGRect(x: 0, y: 0, width: 3440, height: 1440)
        let applied = LayoutProfileMapper.denormalize(normalized, in: bigMonitor)
        #expect(applied[0].position == 1720) // 50% de 3440
    }

    @Test("respeta el origen del monitor (no solo el tamaño)")
    func respectsOrigin() {
        let lines = [GridLine(orientation: .vertical, position: 100)] // 50% de un bounds 100..300
        let offset = CGRect(x: 100, y: 0, width: 200, height: 200)
        // 100 está en el borde izquierdo → fracción 0
        let normalized = LayoutProfileMapper.normalize(lines, in: offset)
        #expect(normalized[0].position == 0)
    }
}
