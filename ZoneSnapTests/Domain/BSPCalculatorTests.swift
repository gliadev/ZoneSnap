//
//  BSPCalculatorTests.swift
//  ZoneSnapTests
//
//  Domain — tests del árbol de subdivisión de zonas (modelo BSP).
//

import CoreGraphics
import Foundation
import Testing
@testable import ZoneSnap

@Suite("BSPCalculator — árbol de zonas")
struct BSPCalculatorTests {
    private let area = CGRect(x: 0, y: 0, width: 100, height: 100)

    private func approxEqual(_ a: CGRect, _ b: CGRect, tolerance: CGFloat = 0.001) -> Bool {
        abs(a.minX - b.minX) < tolerance && abs(a.minY - b.minY) < tolerance
            && abs(a.width - b.width) < tolerance && abs(a.height - b.height) < tolerance
    }

    // MARK: - Evaluación

    @Test("una hoja sola es una zona igual al área")
    func singleLeaf() {
        let id = UUID()
        let zones = BSPCalculator.zones(of: .leaf(id: id), in: area)
        #expect(zones.count == 1)
        #expect(zones[0].id == id)
        #expect(approxEqual(zones[0].rect, area))
    }

    @Test("un split vertical reparte el ancho proporcionalmente")
    func verticalSplitWidths() {
        let tree = ZoneNode.split(id: UUID(), axis: .vertical, ratios: [3, 1],
                                  children: [.leaf(id: UUID()), .leaf(id: UUID())])
        let zones = BSPCalculator.zones(of: tree, in: area)
        #expect(zones.count == 2)
        #expect(approxEqual(zones[0].rect, CGRect(x: 0, y: 0, width: 75, height: 100)))
        #expect(approxEqual(zones[1].rect, CGRect(x: 75, y: 0, width: 25, height: 100)))
    }

    @Test("un split horizontal reparte el alto y respeta el orden de lectura")
    func horizontalSplitReadingOrder() {
        let tree = ZoneNode.split(id: UUID(), axis: .horizontal, ratios: [1, 1],
                                  children: [.leaf(id: UUID()), .leaf(id: UUID())])
        let zones = BSPCalculator.zones(of: tree, in: area)
        #expect(zones.count == 2)
        #expect(zones[0].rect.minY == 0)
        #expect(zones[1].rect.minY == 50)
    }

    // MARK: - Subdivisión local

    @Test("subdividir una hoja en 2×2 produce 4 zonas")
    func subdivideGrid() {
        let leaf = UUID()
        let result = BSPCalculator.subdivide(.leaf(id: leaf), leaf: leaf, columns: 2, rows: 2)
        let zones = BSPCalculator.zones(of: result, in: area)
        #expect(zones.count == 4)
        let total = zones.reduce(CGFloat.zero) { $0 + $1.rect.width * $1.rect.height }
        #expect(abs(total - area.width * area.height) < 0.001) // teselan el área
    }

    @Test("subdividir una zona NO toca el resto del árbol (local)")
    func subdivideIsLocal() {
        let a = UUID(), b = UUID()
        let tree = ZoneNode.split(id: UUID(), axis: .vertical, ratios: [1, 1],
                                  children: [.leaf(id: a), .leaf(id: b)])
        // Subdividimos solo la zona b en 2 filas.
        let result = BSPCalculator.subdivide(tree, leaf: b, columns: 1, rows: 2)
        let zones = BSPCalculator.zones(of: result, in: area)
        #expect(zones.count == 3)
        // La zona a sigue intacta: misma identidad y mismo rect.
        let zoneA = zones.first { $0.id == a }
        #expect(zoneA != nil)
        #expect(approxEqual(zoneA!.rect, CGRect(x: 0, y: 0, width: 50, height: 100)))
    }

    @Test("1×1 no subdivide nada")
    func subdivideNoop() {
        let leaf = UUID()
        let result = BSPCalculator.subdivide(.leaf(id: leaf), leaf: leaf, columns: 1, rows: 1)
        #expect(result.id == leaf)
        #expect(result.isLeaf)
    }

    // MARK: - Columnas/filas locales a la selección

    @Test("setColumns añade una columna a la franja de la hoja (padre vertical)")
    func setColumnsAddsToParent() {
        let a = UUID(), b = UUID()
        let tree = ZoneNode.split(id: UUID(), axis: .vertical, ratios: [1, 1],
                                  children: [.leaf(id: a), .leaf(id: b)])
        let result = BSPCalculator.setColumns(tree, forLeaf: a, to: 3)
        let zones = BSPCalculator.zones(of: result, in: area)
        #expect(zones.count == 3)
        // Conserva las hojas existentes a y b.
        #expect(zones.contains { $0.id == a })
        #expect(zones.contains { $0.id == b })
    }

    @Test("setColumns a 1 colapsa la franja en una sola zona")
    func setColumnsCollapses() {
        let a = UUID(), b = UUID()
        let tree = ZoneNode.split(id: UUID(), axis: .vertical, ratios: [1, 1],
                                  children: [.leaf(id: a), .leaf(id: b)])
        let result = BSPCalculator.setColumns(tree, forLeaf: a, to: 1)
        #expect(BSPCalculator.zones(of: result, in: area).count == 1)
    }

    @Test("setRows sobre una hoja con padre vertical subdivide solo esa hoja")
    func setRowsSubdividesLeaf() {
        let a = UUID(), b = UUID()
        let tree = ZoneNode.split(id: UUID(), axis: .vertical, ratios: [1, 1],
                                  children: [.leaf(id: a), .leaf(id: b)])
        let result = BSPCalculator.setRows(tree, forLeaf: a, to: 2)
        let zones = BSPCalculator.zones(of: result, in: area)
        #expect(zones.count == 3) // a partida en 2 filas + b
        #expect(zones.contains { $0.id == b }) // b intacta
    }

    @Test("setColumns sobre la raíz hoja la subdivide en columnas")
    func setColumnsRootLeaf() {
        let root = UUID()
        let result = BSPCalculator.setColumns(.leaf(id: root), forLeaf: root, to: 4)
        #expect(BSPCalculator.zones(of: result, in: area).count == 4)
    }

    // MARK: - Unir (colapsar)

    @Test("collapseParent une la franja que contiene la hoja en una zona")
    func collapseParentUnites() {
        let a = UUID(), b = UUID(), c = UUID()
        let tree = ZoneNode.split(id: UUID(), axis: .vertical, ratios: [1, 1, 1],
                                  children: [.leaf(id: a), .leaf(id: b), .leaf(id: c)])
        let result = BSPCalculator.collapseParent(tree, ofLeaf: b)
        #expect(BSPCalculator.zones(of: result, in: area).count == 1)
    }

    // MARK: - Mover fronteras

    @Test("moveBoundary cambia el reparto de los dos hijos colindantes")
    func moveBoundaryResizes() {
        let split = UUID()
        let tree = ZoneNode.split(id: split, axis: .vertical, ratios: [1, 1],
                                  children: [.leaf(id: UUID()), .leaf(id: UUID())])
        let result = BSPCalculator.moveBoundary(tree, split: split, boundary: 0, toFraction: 0.3)
        let zones = BSPCalculator.zones(of: result, in: area)
        #expect(abs(zones[0].rect.width - 30) < 0.001)
        #expect(abs(zones[1].rect.width - 70) < 0.001)
    }

    @Test("moveBoundary respeta el margen mínimo")
    func moveBoundaryClampsToMargin() {
        let split = UUID()
        let tree = ZoneNode.split(id: split, axis: .vertical, ratios: [1, 1],
                                  children: [.leaf(id: UUID()), .leaf(id: UUID())])
        let result = BSPCalculator.moveBoundary(tree, split: split, boundary: 0, toFraction: 0, minFraction: 0.1)
        let zones = BSPCalculator.zones(of: result, in: area)
        #expect(abs(zones[0].rect.width - 10) < 0.001) // empujado al margen, no a 0
    }

    // MARK: - Persistencia

    @Test("round-trip Codable conserva el árbol")
    func codableRoundTrip() throws {
        let tree = ZoneNode.split(id: UUID(), axis: .horizontal, ratios: [2, 1],
                                  children: [
                                    .leaf(id: UUID()),
                                    .split(id: UUID(), axis: .vertical, ratios: [1, 1],
                                           children: [.leaf(id: UUID()), .leaf(id: UUID())])
                                  ])
        let data = try JSONEncoder().encode(tree)
        let decoded = try JSONDecoder().decode(ZoneNode.self, from: data)
        #expect(decoded == tree)
    }
}
