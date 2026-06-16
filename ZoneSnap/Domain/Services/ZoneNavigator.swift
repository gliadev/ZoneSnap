//
//  ZoneNavigator.swift
//  ZoneSnap
//
//  Domain — resuelve la zona destino de una acción de atajo.
//

import Foundation

/// Calcula a qué zona debe ir la ventana activa según la acción del atajo, la
/// lista de zonas del monitor y la zona donde está ahora la ventana. Lógica pura.
enum ZoneNavigator {
    static func destination(for action: ShortcutAction, in zones: [Zone], current: Zone.ID?) -> Zone? {
        switch action {
        case let .moveToZone(number):
            let index = number - 1
            return zones.indices.contains(index) ? zones[index] : nil

        case let .navigate(direction):
            guard let current else { return zones.first }
            let grid = ZoneGrid(zones: zones)
            return direction == .next ? grid.zone(after: current) : grid.zone(before: current)
        }
    }
}
