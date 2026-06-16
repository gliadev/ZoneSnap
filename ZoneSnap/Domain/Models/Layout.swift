//
//  Layout.swift
//  ZoneSnap
//
//  Domain — arreglo de zonas con nombre (preset o personalizado).
//

import Foundation

/// Arreglo de zonas con nombre: un preset o una configuración personalizada por
/// el usuario. Reutilizable entre monitores.
///
/// Además de las zonas resultantes (`grid`), guarda el **árbol de subdivisión**
/// (`tree`, modelo BSP) para poder reabrir y seguir editando con la estructura
/// intacta. Los consumidores (overlay, snapper) usan `grid.zones`.
struct Layout: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    var name: String
    var grid: ZoneGrid
    /// Árbol de subdivisión del editor. Las zonas resultantes viven en `grid.zones`.
    var tree: ZoneNode?

    init(id: UUID = UUID(), name: String, grid: ZoneGrid, tree: ZoneNode? = nil) {
        self.id = id
        self.name = name
        self.grid = grid
        self.tree = tree
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, grid, tree
    }

    /// Decodificación tolerante: los layouts antiguos sin `tree` (y los del
    /// modelo de líneas, ya retirado) se leen sin árbol en lugar de fallar.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        grid = try container.decode(ZoneGrid.self, forKey: .grid)
        tree = try container.decodeIfPresent(ZoneNode.self, forKey: .tree)
    }
}
