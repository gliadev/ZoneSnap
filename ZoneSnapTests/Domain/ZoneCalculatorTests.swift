//
//  ZoneCalculatorTests.swift
//  ZoneSnapTests
//
//  Domain — tests del cálculo de zonas a partir de líneas.
//

import Testing
import CoreGraphics
@testable import ZoneSnap

@Suite("ZoneCalculator")
struct ZoneCalculatorTests {
    private let bounds = CGRect(x: 0, y: 0, width: 1000, height: 800)

    @Test("sin líneas produce una única zona igual al área")
    func noLines() {
        let zones = ZoneCalculator.zones(in: bounds, lines: [])
        #expect(zones.count == 1)
        #expect(zones.first?.rect == bounds)
    }

    @Test("una línea vertical parte en dos columnas")
    func oneVertical() {
        let zones = ZoneCalculator.zones(in: bounds, lines: [GridLine(orientation: .vertical, position: 400)])
        #expect(zones.count == 2)
        #expect(zones[0].rect == CGRect(x: 0, y: 0, width: 400, height: 800))
        #expect(zones[1].rect == CGRect(x: 400, y: 0, width: 600, height: 800))
    }

    @Test("una línea horizontal parte en dos filas")
    func oneHorizontal() {
        let zones = ZoneCalculator.zones(in: bounds, lines: [GridLine(orientation: .horizontal, position: 200)])
        #expect(zones.count == 2)
        #expect(zones[0].rect == CGRect(x: 0, y: 0, width: 1000, height: 200))
        #expect(zones[1].rect == CGRect(x: 0, y: 200, width: 1000, height: 600))
    }

    @Test("una vertical y una horizontal producen 4 cuadrantes en orden de lectura")
    func grid2x2() {
        let lines = [
            GridLine(orientation: .vertical, position: 500),
            GridLine(orientation: .horizontal, position: 400)
        ]
        let zones = ZoneCalculator.zones(in: bounds, lines: lines)
        #expect(zones.count == 4)
        #expect(zones[0].rect == CGRect(x: 0, y: 0, width: 500, height: 400))
        #expect(zones[1].rect == CGRect(x: 500, y: 0, width: 500, height: 400))
        #expect(zones[2].rect == CGRect(x: 0, y: 400, width: 500, height: 400))
        #expect(zones[3].rect == CGRect(x: 500, y: 400, width: 500, height: 400))
    }

    @Test("las zonas teselan el área (suma de áreas = área total)")
    func zonesTileBounds() {
        let lines = [
            GridLine(orientation: .vertical, position: 300),
            GridLine(orientation: .vertical, position: 700),
            GridLine(orientation: .horizontal, position: 500)
        ]
        let zones = ZoneCalculator.zones(in: bounds, lines: lines)
        let totalArea = zones.reduce(CGFloat.zero) { $0 + $1.rect.width * $1.rect.height }
        #expect(zones.count == 6)
        #expect(totalArea == bounds.width * bounds.height)
    }

    @Test("las líneas fuera del área o sobre el borde se ignoran")
    func ignoresOutOfBoundsLines() {
        let lines = [
            GridLine(orientation: .vertical, position: 0),
            GridLine(orientation: .vertical, position: 1000),
            GridLine(orientation: .vertical, position: 1500),
            GridLine(orientation: .horizontal, position: -50)
        ]
        let zones = ZoneCalculator.zones(in: bounds, lines: lines)
        #expect(zones.count == 1)
        #expect(zones.first?.rect == bounds)
    }
}
