//
//  LayoutProfile.swift
//  ZoneSnap
//
//  Domain — perfil de distribución reutilizable entre monitores.
//

import Foundation

/// Perfil de distribución con nombre (p. ej. "dev", "cine"). Guarda el árbol de
/// subdivisión (`ZoneNode`): como sus `ratios` son relativos, el mismo perfil se
/// adapta a cualquier monitor sin conversión, sea cual sea su resolución.
struct LayoutProfile: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    var name: String
    var tree: ZoneNode

    init(id: UUID = UUID(), name: String, tree: ZoneNode) {
        self.id = id
        self.name = name
        self.tree = tree
    }
}
