//
//  GridLine.swift
//  ZoneSnap
//
//  Domain — línea divisoria del editor de zonas.
//

import CoreGraphics
import Foundation

/// Orientación de una línea divisoria del editor de zonas.
enum LineOrientation: String, Codable, Sendable, Hashable {
    /// Divide en columnas; su posición es una coordenada `x`.
    case vertical
    /// Divide en filas; su posición es una coordenada `y`.
    case horizontal
}

/// Una línea divisoria que el usuario coloca en el editor para partir el área
/// del monitor en zonas.
///
/// `position` está en el espacio local del monitor (puntos, origen
/// arriba-izquierda): la coordenada `x` para verticales, `y` para horizontales.
struct GridLine: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    var orientation: LineOrientation
    var position: CGFloat

    init(id: UUID = UUID(), orientation: LineOrientation, position: CGFloat) {
        self.id = id
        self.orientation = orientation
        self.position = position
    }
}
