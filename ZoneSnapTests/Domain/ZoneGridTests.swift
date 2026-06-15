//
//  ZoneGridTests.swift
//  ZoneSnapTests
//
//  Domain — tests de la rejilla de zonas.
//

import Testing
import Foundation
import CoreGraphics
@testable import ZoneSnap

@Suite("ZoneGrid")
struct ZoneGridTests {
    private func makeGrid() -> (grid: ZoneGrid, left: Zone, right: Zone) {
        let left = Zone(rect: CGRect(x: 0, y: 0, width: 100, height: 200), name: "Izquierda")
        let right = Zone(rect: CGRect(x: 100, y: 0, width: 100, height: 200), name: "Derecha")
        return (ZoneGrid(zones: [left, right]), left, right)
    }

    @Test("zone(at:) devuelve la zona que contiene el punto")
    func zoneAtPoint() {
        let (grid, left, right) = makeGrid()
        #expect(grid.zone(at: CGPoint(x: 50, y: 100))?.id == left.id)
        #expect(grid.zone(at: CGPoint(x: 150, y: 100))?.id == right.id)
    }

    @Test("nearestZone elige la zona por distancia al centro")
    func nearest() {
        let (grid, _, right) = makeGrid()
        #expect(grid.nearestZone(to: CGPoint(x: 199, y: 100))?.id == right.id)
    }

    @Test("navegación siguiente/anterior con wrap-around")
    func navigationWraps() {
        let (grid, left, right) = makeGrid()
        #expect(grid.zone(after: left.id)?.id == right.id)
        #expect(grid.zone(after: right.id)?.id == left.id)
        #expect(grid.zone(before: left.id)?.id == right.id)
        #expect(grid.zone(before: right.id)?.id == left.id)
    }

    @Test("una rejilla vacía no rompe la navegación")
    func emptyGrid() {
        let grid = ZoneGrid()
        #expect(grid.zone(at: .zero) == nil)
        #expect(grid.nearestZone(to: .zero) == nil)
        #expect(grid.zone(after: UUID()) == nil)
        #expect(grid.zone(before: UUID()) == nil)
    }
}
