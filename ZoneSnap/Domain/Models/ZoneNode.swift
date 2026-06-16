//
//  ZoneNode.swift
//  ZoneSnap
//
//  Domain — árbol de subdivisión de zonas (modelo BSP generalizado a N hijos).
//

import CoreGraphics
import Foundation

/// Eje por el que un *split* reparte su área entre los hijos.
enum SplitAxis: String, Codable, Sendable, Hashable {
    /// Divide en columnas (corta en `x`): los hijos se reparten el ancho.
    case vertical
    /// Divide en filas (corta en `y`): los hijos se reparten el alto.
    case horizontal
}

/// Nodo del árbol de subdivisión de zonas.
///
/// Una **hoja** (`leaf`) es una zona final. Un **split** reparte su área entre
/// varios hijos a lo largo de un eje, según `ratios` (pesos relativos; se
/// normalizan al evaluar, no hace falta que sumen 1).
///
/// Es un modelo *guillotina*: cada corte atraviesa por completo el área del
/// nodo, así que **subdividir una zona es local** y no afecta al resto del
/// árbol. Esto es justo lo que el editor necesita para meter columnas/filas sin
/// romper el diseño existente.
indirect enum ZoneNode: Identifiable, Codable, Sendable, Hashable {
    case leaf(id: UUID)
    case split(id: UUID, axis: SplitAxis, ratios: [CGFloat], children: [ZoneNode])

    /// Identidad del nodo (estable al recalcular y persistible).
    var id: UUID {
        switch self {
        case let .leaf(id): id
        case let .split(id, _, _, _): id
        }
    }

    var isLeaf: Bool {
        if case .leaf = self { true } else { false }
    }
}
