//
//  WindowFrameCalculator.swift
//  ZoneSnap
//
//  WindowManagement — cálculo del frame destino de una ventana.
//

import CoreGraphics

/// Calcula el rectángulo destino al que mover una ventana. Lógica pura y
/// testeable: la obtención del origen global del monitor y la llamada a la
/// Accessibility API viven en los adapters.
enum WindowFrameCalculator {
    /// Rectángulo que engloba a todas las zonas dadas (bounding box), en el
    /// espacio local del monitor. Permite colocar una ventana sobre varias
    /// zonas seleccionadas (p. ej. 5 + 6 + 8 + 9). `nil` si no hay zonas.
    static func boundingRect(of zones: [Zone]) -> CGRect? {
        guard let first = zones.first?.rect else { return nil }
        return zones.dropFirst().reduce(first) { $0.union($1.rect) }
    }

    /// Convierte un rectángulo local del monitor (top-left, origen 0,0) a
    /// coordenadas globales top-left, desplazándolo por el origen global del
    /// monitor. Conserva el tamaño.
    static func globalFrame(localRect: CGRect, monitorOrigin: CGPoint) -> CGRect {
        localRect.offsetBy(dx: monitorOrigin.x, dy: monitorOrigin.y)
    }
}
