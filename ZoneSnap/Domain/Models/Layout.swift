//
//  Layout.swift
//  ZoneSnap
//
//  Domain — arreglo de zonas con nombre (preset o personalizado).
//

import Foundation

/// Arreglo de zonas con nombre: un preset (16:9, 21:9…) o una configuración
/// personalizada por el usuario. Reutilizable entre monitores.
///
/// Además de las zonas resultantes (`grid`), guarda el **modelo del editor**
/// (`lines` + `merges`) para poder reabrir y seguir editando con las fusiones
/// intactas. Los consumidores (overlay, snapper) usan `grid.zones`.
struct Layout: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    var name: String
    var grid: ZoneGrid
    var lines: [GridLine]
    var merges: [[GridCell]]
    /// Árbol de subdivisión (modelo BSP) para reabrir el editor con la
    /// estructura intacta. Las zonas resultantes viven en `grid.zones`.
    var tree: ZoneNode?

    init(id: UUID = UUID(), name: String, grid: ZoneGrid, lines: [GridLine] = [], merges: [[GridCell]] = [], tree: ZoneNode? = nil) {
        self.id = id
        self.name = name
        self.grid = grid
        self.lines = lines
        self.merges = merges
        self.tree = tree
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, grid, lines, merges, tree
    }

    /// Decodificación tolerante: los layouts antiguos sin `lines`/`merges`/`tree`
    /// se leen con esos campos vacíos en lugar de fallar.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        grid = try container.decode(ZoneGrid.self, forKey: .grid)
        lines = try container.decodeIfPresent([GridLine].self, forKey: .lines) ?? []
        merges = try container.decodeIfPresent([[GridCell]].self, forKey: .merges) ?? []
        tree = try container.decodeIfPresent(ZoneNode.self, forKey: .tree)
    }
}
