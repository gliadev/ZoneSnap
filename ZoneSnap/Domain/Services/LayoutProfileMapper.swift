//
//  LayoutProfileMapper.swift
//  ZoneSnap
//
//  Domain — conversión entre líneas en píxeles y líneas normalizadas.
//

import CoreGraphics
import Foundation

/// Convierte líneas entre el espacio en puntos de un monitor y el espacio
/// normalizado (`0...1`) de un `LayoutProfile`. Lógica pura.
enum LayoutProfileMapper {
    /// Líneas en puntos (dentro de `bounds`) → líneas normalizadas.
    static func normalize(_ lines: [GridLine], in bounds: CGRect) -> [NormalizedLine] {
        lines.map { line in
            let fraction = line.orientation == .vertical
                ? (line.position - bounds.minX) / bounds.width
                : (line.position - bounds.minY) / bounds.height
            return NormalizedLine(orientation: line.orientation, position: fraction)
        }
    }

    /// Líneas normalizadas → líneas en puntos dentro de `bounds` (el monitor
    /// donde se aplica el perfil).
    static func denormalize(_ lines: [NormalizedLine], in bounds: CGRect) -> [GridLine] {
        lines.map { line in
            let position = line.orientation == .vertical
                ? bounds.minX + line.position * bounds.width
                : bounds.minY + line.position * bounds.height
            return GridLine(orientation: line.orientation, position: position)
        }
    }
}
