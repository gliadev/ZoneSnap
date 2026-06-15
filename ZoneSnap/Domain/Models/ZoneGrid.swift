//
//  ZoneGrid.swift
//  ZoneSnap
//
//  Domain — conjunto ordenado de zonas.
//

import CoreGraphics
import Foundation

/// Conjunto ordenado de zonas que forman una rejilla para un monitor o layout.
///
/// El orden del array define la numeración (zona 1, 2, 3…) usada por los
/// atajos numéricos y por la navegación `⌃⌥←` / `⌃⌥→`.
struct ZoneGrid: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    var zones: [Zone]

    init(id: UUID = UUID(), zones: [Zone] = []) {
        self.id = id
        self.zones = zones
    }
}

extension ZoneGrid {
    /// Primera zona (en orden) que contiene el punto dado.
    func zone(at point: CGPoint) -> Zone? {
        zones.first { $0.contains(point) }
    }

    /// Zona cuyo centro está más cerca del punto dado. Útil para snapping (F4).
    func nearestZone(to point: CGPoint) -> Zone? {
        zones.min { lhs, rhs in
            hypot(lhs.center.x - point.x, lhs.center.y - point.y) <
            hypot(rhs.center.x - point.x, rhs.center.y - point.y)
        }
    }

    /// Zona siguiente a la indicada, con wrap-around.
    ///
    /// Si `id` no pertenece a la rejilla, devuelve la primera zona. Devuelve
    /// `nil` solo si la rejilla está vacía.
    func zone(after id: Zone.ID) -> Zone? {
        guard !zones.isEmpty else { return nil }
        guard let index = zones.firstIndex(where: { $0.id == id }) else { return zones.first }
        return zones[(index + 1) % zones.count]
    }

    /// Zona anterior a la indicada, con wrap-around.
    func zone(before id: Zone.ID) -> Zone? {
        guard !zones.isEmpty else { return nil }
        guard let index = zones.firstIndex(where: { $0.id == id }) else { return zones.last }
        return zones[(index - 1 + zones.count) % zones.count]
    }
}
