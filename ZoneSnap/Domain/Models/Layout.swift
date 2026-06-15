//
//  Layout.swift
//  ZoneSnap
//
//  Domain — arreglo de zonas con nombre (preset o personalizado).
//

import Foundation

/// Arreglo de zonas con nombre: un preset (16:9, 21:9…) o una configuración
/// personalizada por el usuario. Reutilizable entre monitores.
struct Layout: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    var name: String
    var grid: ZoneGrid

    init(id: UUID = UUID(), name: String, grid: ZoneGrid) {
        self.id = id
        self.name = name
        self.grid = grid
    }
}
