//
//  ZoneCalculator.swift
//  ZoneSnap
//
//  Domain — cálculo de la rejilla de zonas a partir de líneas y fusiones.
//

import CoreGraphics
import Foundation

/// Calcula la rejilla de zonas resultante de partir un área con líneas
/// divisorias y, opcionalmente, fusionar grupos de celdas. Lógica pura del
/// Domain, sin dependencias de UI.
///
/// Trabaja en el espacio local del monitor (puntos, origen arriba-izquierda).
/// Las identidades de las zonas son deterministas por la celda superior-izquierda
/// que ocupan, así que se mantienen estables al recalcular (sin parpadeo).
enum ZoneCalculator {
    /// Celdas base de la rejilla (sin fusiones), con su posición y rectángulo.
    static func cells(in bounds: CGRect, lines: [GridLine]) -> [(cell: GridCell, rect: CGRect)] {
        let (xs, ys) = edges(in: bounds, lines: lines)
        var result: [(GridCell, CGRect)] = []
        for row in 0..<(ys.count - 1) {
            for col in 0..<(xs.count - 1) {
                let rect = CGRect(
                    x: xs[col],
                    y: ys[row],
                    width: xs[col + 1] - xs[col],
                    height: ys[row + 1] - ys[row]
                )
                result.append((GridCell(row: row, col: col), rect))
            }
        }
        return result
    }

    /// Zonas resultantes: cada grupo de `merges` se une en una sola zona
    /// (bounding box de sus celdas); el resto de celdas son zonas individuales.
    /// Orden de lectura (arriba→abajo, izquierda→derecha).
    static func zones(in bounds: CGRect, lines: [GridLine], merges: [[GridCell]] = []) -> [Zone] {
        let rectByCell = Dictionary(uniqueKeysWithValues: cells(in: bounds, lines: lines).map { ($0.cell, $0.rect) })
        let groups = merges.map(Set.init).filter { !$0.isEmpty }
        let consumed = groups.reduce(into: Set<GridCell>()) { $0.formUnion($1) }

        var zones: [Zone] = []

        for group in groups {
            let rects = group.compactMap { rectByCell[$0] }
            guard
                let union = boundingBox(of: rects),
                let anchor = group.min(by: cellPrecedes)
            else { continue }
            zones.append(Zone(id: zoneID(for: anchor), rect: union))
        }

        for (cell, rect) in cells(in: bounds, lines: lines) where !consumed.contains(cell) {
            zones.append(Zone(id: zoneID(for: cell), rect: rect))
        }

        return zones.sorted { ($0.rect.minY, $0.rect.minX) < ($1.rect.minY, $1.rect.minX) }
    }

    /// Segmentos a lo largo de una línea donde realmente separa dos zonas
    /// distintas (con fusiones, una línea puede no ser frontera en algún tramo).
    /// Para verticales devuelve rangos en `y`; para horizontales, en `x`.
    static func lineSegments(
        for line: GridLine,
        in bounds: CGRect,
        lines: [GridLine],
        merges: [[GridCell]]
    ) -> [ClosedRange<CGFloat>] {
        let (xs, ys) = edges(in: bounds, lines: lines)
        let zoneOf = zoneResolver(merges: merges)

        switch line.orientation {
        case .vertical:
            guard let edge = xs.firstIndex(of: line.position), edge > 0, edge < xs.count - 1 else { return [] }
            let bands = (0..<(ys.count - 1)).compactMap { row -> (CGFloat, CGFloat)? in
                zoneOf(GridCell(row: row, col: edge - 1)) != zoneOf(GridCell(row: row, col: edge))
                    ? (ys[row], ys[row + 1]) : nil
            }
            return mergeContiguous(bands)

        case .horizontal:
            guard let edge = ys.firstIndex(of: line.position), edge > 0, edge < ys.count - 1 else { return [] }
            let bands = (0..<(xs.count - 1)).compactMap { col -> (CGFloat, CGFloat)? in
                zoneOf(GridCell(row: edge - 1, col: col)) != zoneOf(GridCell(row: edge, col: col))
                    ? (xs[col], xs[col + 1]) : nil
            }
            return mergeContiguous(bands)
        }
    }

    /// UUID determinista derivado de la celda (su posición fila/columna).
    static func zoneID(for cell: GridCell) -> UUID {
        let index = cell.row * 100_000 + cell.col
        let hex = String(index, radix: 16)
        let padded = String(repeating: "0", count: max(0, 12 - hex.count)) + hex
        return UUID(uuidString: "00000000-0000-0000-0000-\(padded)") ?? UUID()
    }

    // MARK: - Privado

    private static func edges(in bounds: CGRect, lines: [GridLine]) -> (xs: [CGFloat], ys: [CGFloat]) {
        let verticals = lines
            .filter { $0.orientation == .vertical && $0.position > bounds.minX && $0.position < bounds.maxX }
            .map(\.position)
        let horizontals = lines
            .filter { $0.orientation == .horizontal && $0.position > bounds.minY && $0.position < bounds.maxY }
            .map(\.position)
        return (([bounds.minX, bounds.maxX] + verticals).sorted(), ([bounds.minY, bounds.maxY] + horizontals).sorted())
    }

    /// Resuelve la zona (id) a la que pertenece una celda, según las fusiones.
    private static func zoneResolver(merges: [[GridCell]]) -> (GridCell) -> UUID {
        var map: [GridCell: UUID] = [:]
        for group in merges.map(Set.init).filter({ !$0.isEmpty }) {
            guard let anchor = group.min(by: cellPrecedes) else { continue }
            let id = zoneID(for: anchor)
            for cell in group { map[cell] = id }
        }
        return { map[$0] ?? zoneID(for: $0) }
    }

    /// Une bandas contiguas (que se tocan) en rangos.
    private static func mergeContiguous(_ bands: [(CGFloat, CGFloat)]) -> [ClosedRange<CGFloat>] {
        guard var current = bands.first else { return [] }
        var result: [ClosedRange<CGFloat>] = []
        for band in bands.dropFirst() {
            if band.0 == current.1 {
                current.1 = band.1
            } else {
                result.append(current.0...current.1)
                current = band
            }
        }
        result.append(current.0...current.1)
        return result
    }

    private static func cellPrecedes(_ a: GridCell, _ b: GridCell) -> Bool {
        (a.row, a.col) < (b.row, b.col)
    }

    private static func boundingBox(of rects: [CGRect]) -> CGRect? {
        guard let first = rects.first else { return nil }
        return rects.dropFirst().reduce(first) { $0.union($1) }
    }
}
