//
//  ZoneCalculator.swift
//  ZoneSnap
//
//  Domain — cálculo de la rejilla de zonas a partir de líneas divisorias.
//

import CoreGraphics
import Foundation

/// Calcula la rejilla de zonas resultante de partir un área con líneas
/// divisorias. Lógica pura del Domain, sin dependencias de UI.
///
/// Trabaja en el espacio local del monitor (puntos, origen arriba-izquierda).
/// Las líneas fuera del área (o sobre sus bordes) se ignoran para no generar
/// zonas degeneradas. Las zonas se devuelven en orden de lectura: de arriba a
/// abajo y de izquierda a derecha.
///
/// Las identidades de las zonas son **deterministas por posición** (índice de
/// lectura): así, al recalcular durante un arrastre, cada celda conserva su id y
/// SwiftUI no re-crea las vistas (sin parpadeo).
enum ZoneCalculator {
    static func zones(in bounds: CGRect, lines: [GridLine]) -> [Zone] {
        let verticals = lines
            .filter { $0.orientation == .vertical && $0.position > bounds.minX && $0.position < bounds.maxX }
            .map(\.position)
        let horizontals = lines
            .filter { $0.orientation == .horizontal && $0.position > bounds.minY && $0.position < bounds.maxY }
            .map(\.position)

        let xs = ([bounds.minX, bounds.maxX] + verticals).sorted()
        let ys = ([bounds.minY, bounds.maxY] + horizontals).sorted()

        var zones: [Zone] = []
        var index = 0
        for row in 0..<(ys.count - 1) {
            for col in 0..<(xs.count - 1) {
                let rect = CGRect(
                    x: xs[col],
                    y: ys[row],
                    width: xs[col + 1] - xs[col],
                    height: ys[row + 1] - ys[row]
                )
                zones.append(Zone(id: zoneID(at: index), rect: rect))
                index += 1
            }
        }
        return zones
    }

    /// UUID determinista derivado del índice de lectura de la celda.
    private static func zoneID(at index: Int) -> UUID {
        let hex = String(index, radix: 16)
        let padded = String(repeating: "0", count: max(0, 12 - hex.count)) + hex
        return UUID(uuidString: "00000000-0000-0000-0000-\(padded)") ?? UUID()
    }
}
