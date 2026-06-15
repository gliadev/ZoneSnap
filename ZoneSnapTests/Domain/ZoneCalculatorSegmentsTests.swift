//
//  ZoneCalculatorSegmentsTests.swift
//  ZoneSnapTests
//
//  Domain — tests de los segmentos de línea (frontera real entre zonas).
//

import Testing
import CoreGraphics
@testable import ZoneSnap

@Suite("ZoneCalculator — segmentos de línea")
struct ZoneCalculatorSegmentsTests {
    @Test("sin fusiones, la línea es un único segmento completo")
    func fullSegmentNoMerges() {
        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let line = GridLine(orientation: .vertical, position: 500)
        let segments = ZoneCalculator.lineSegments(for: line, in: bounds, lines: [line], merges: [])
        #expect(segments == [0...800])
    }

    @Test("fusionar arriba deja la línea solo en el segmento de abajo")
    func partialSegmentAfterMerge() {
        let bounds = CGRect(x: 0, y: 0, width: 900, height: 800)
        let lines = [
            GridLine(orientation: .vertical, position: 300),
            GridLine(orientation: .vertical, position: 600),
            GridLine(orientation: .horizontal, position: 400)
        ]
        // Fusiona las celdas de arriba col0+col1 → la línea x=300 deja de ser
        // frontera en la fila de arriba (ambas en la misma zona).
        let merges = [[GridCell(row: 0, col: 0), GridCell(row: 0, col: 1)]]
        let segments = ZoneCalculator.lineSegments(for: lines[0], in: bounds, lines: lines, merges: merges)
        #expect(segments == [400...800])
    }

    @Test("la línea fuera de la fusión sigue completa")
    func adjacentLineStaysFull() {
        let bounds = CGRect(x: 0, y: 0, width: 900, height: 800)
        let lines = [
            GridLine(orientation: .vertical, position: 300),
            GridLine(orientation: .vertical, position: 600),
            GridLine(orientation: .horizontal, position: 400)
        ]
        let merges = [[GridCell(row: 0, col: 0), GridCell(row: 0, col: 1)]]
        // x=600 separa la zona fusionada (arriba) de col2, y abajo col1|col2 → completa.
        let segments = ZoneCalculator.lineSegments(for: lines[1], in: bounds, lines: lines, merges: merges)
        #expect(segments == [0...800])
    }
}
