//
//  Zone.swift
//  ZoneSnap
//
//  Domain — modelo de una zona individual de la pantalla.
//

import CoreGraphics
import Foundation

/// Una zona rectangular de la pantalla a la que se puede acoplar una ventana.
///
/// `Zone` es un value type puro del Domain: sin dependencias de UI ni de
/// persistencia. Su identidad (`id`) es un `UUID` estable que sobrevive a
/// cambios de `rect` o `name`, lo que la hace segura para `ForEach` y para
/// los tests.
struct Zone: Identifiable, Codable, Sendable, Hashable {
    /// Identidad estable de la zona. Se genera una vez y se persiste.
    let id: UUID

    /// Rectángulo de la zona en coordenadas de la pantalla (puntos).
    var rect: CGRect

    /// Nombre opcional legible (p. ej. "Izquierda", "Editor").
    var name: String?

    init(id: UUID = UUID(), rect: CGRect, name: String? = nil) {
        self.id = id
        self.rect = rect
        self.name = name
    }
}

extension Zone {
    /// Centro geométrico de la zona, útil para snapping y navegación.
    var center: CGPoint {
        CGPoint(x: rect.midX, y: rect.midY)
    }

    /// Indica si la zona contiene el punto dado.
    func contains(_ point: CGPoint) -> Bool {
        rect.contains(point)
    }
}
