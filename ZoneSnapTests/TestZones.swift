//
//  TestZones.swift
//  ZoneSnapTests
//
//  Soporte de tests — fabrica zonas en rejilla uniforme con el árbol BSP.
//

import CoreGraphics
import Foundation
@testable import ZoneSnap

/// Helper para construir conjuntos de zonas en rejilla uniforme (sin depender de
/// la UI ni del editor), usado por tests de subsistemas que solo necesitan unas
/// zonas de ejemplo.
enum TestZones {
    static func grid(_ bounds: CGRect, columns: Int, rows: Int) -> [Zone] {
        let root = ZoneNode.leaf(id: UUID())
        let tree = BSPCalculator.subdivide(root, leaf: root.id, columns: columns, rows: rows)
        return BSPCalculator.zones(of: tree, in: bounds)
    }
}
