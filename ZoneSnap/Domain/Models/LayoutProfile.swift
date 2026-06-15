//
//  LayoutProfile.swift
//  ZoneSnap
//
//  Domain — perfil de distribución reutilizable entre monitores.
//

import CoreGraphics
import Foundation

/// Línea divisoria en coordenadas normalizadas (fracción `0...1` del lado del
/// monitor). Resolución-independiente: permite aplicar el mismo perfil a
/// monitores de distinto tamaño.
struct NormalizedLine: Codable, Sendable, Hashable {
    var orientation: LineOrientation
    /// Posición como fracción del lado correspondiente (x para verticales,
    /// y para horizontales), en `0...1`.
    var position: CGFloat

    init(orientation: LineOrientation, position: CGFloat) {
        self.orientation = orientation
        self.position = position
    }
}

/// Perfil de distribución con nombre (p. ej. "dev", "cine"). Guarda las líneas
/// normalizadas para poder aplicarse a cualquier monitor.
struct LayoutProfile: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    var name: String
    var lines: [NormalizedLine]

    init(id: UUID = UUID(), name: String, lines: [NormalizedLine]) {
        self.id = id
        self.name = name
        self.lines = lines
    }
}
