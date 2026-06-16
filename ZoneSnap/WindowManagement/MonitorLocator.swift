//
//  MonitorLocator.swift
//  ZoneSnap
//
//  WindowManagement — elige el monitor donde está una ventana.
//

import CoreGraphics
import Foundation

/// Localiza el monitor que contiene un punto (p. ej. el centro de una ventana),
/// entre los monitores conocidos por su rect global. Lógica pura y testeable.
enum MonitorLocator {
    /// Monitor a cuyo rect global pertenece `point`; si ninguno lo contiene,
    /// el más cercano por distancia. `nil` si no hay monitores.
    static func monitor(
        containing point: CGPoint,
        in monitors: [(id: Monitor.ID, frame: CGRect)]
    ) -> Monitor.ID? {
        if let hit = monitors.first(where: { $0.frame.contains(point) }) {
            return hit.id
        }
        return monitors.min { distance(from: point, to: $0.frame) < distance(from: point, to: $1.frame) }?.id
    }

    /// Distancia del punto al rectángulo (0 si está dentro).
    private static func distance(from point: CGPoint, to rect: CGRect) -> CGFloat {
        let clampedX = min(max(point.x, rect.minX), rect.maxX)
        let clampedY = min(max(point.y, rect.minY), rect.maxY)
        return hypot(point.x - clampedX, point.y - clampedY)
    }
}
