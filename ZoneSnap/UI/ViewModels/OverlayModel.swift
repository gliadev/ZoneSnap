//
//  OverlayModel.swift
//  ZoneSnap
//
//  UI — estado del overlay que ilumina las zonas sobre el monitor.
//

import CoreGraphics
import Foundation
import Observation

/// Estado del overlay de zonas que se muestra sobre el monitor mientras se
/// arrastra una ventana. Trabaja en el espacio local del monitor (puntos,
/// origen arriba-izquierda).
@MainActor
@Observable
final class OverlayModel {
    /// Distancia al borde (puntos) para considerar que el cursor "toca" una
    /// línea divisoria y resaltar las zonas de ambos lados (span).
    static let spanThreshold: CGFloat = 35

    /// Área del monitor cubierta por el overlay.
    var bounds: CGRect = .zero

    /// Zonas a iluminar.
    var zones: [Zone] = []

    /// Zonas resaltadas (1 = una zona; 2+ = span al estar sobre una divisoria).
    var highlightedZoneIDs: Set<Zone.ID> = []

    /// Configura el overlay para un monitor y sus zonas, sin resaltado.
    func configure(bounds: CGRect, zones: [Zone]) {
        self.bounds = bounds
        self.zones = zones
        highlightedZoneIDs = []
    }

    /// Resalta la(s) zona(s) bajo el punto: la que lo contiene y, si está cerca
    /// de una línea divisoria, también las zonas adyacentes (span).
    func highlightZones(at point: CGPoint, threshold: CGFloat = OverlayModel.spanThreshold) {
        highlightedZoneIDs = Set(
            zones
                .filter { $0.rect.insetBy(dx: -threshold, dy: -threshold).contains(point) }
                .map(\.id)
        )
    }

    /// Rectángulo destino del span: bounding box de las zonas resaltadas, o `nil`.
    var highlightedRect: CGRect? {
        WindowFrameCalculator.boundingRect(of: zones.filter { highlightedZoneIDs.contains($0.id) })
    }
}
