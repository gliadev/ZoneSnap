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
    /// Área del monitor cubierta por el overlay.
    var bounds: CGRect = .zero

    /// Zonas a iluminar.
    var zones: [Zone] = []

    /// Zona resaltada (la que hay bajo el cursor), si alguna.
    var highlightedZoneID: Zone.ID?

    /// Actualiza la zona resaltada según un punto en coordenadas locales del
    /// monitor (la que contiene el cursor).
    func highlightZone(at point: CGPoint) {
        highlightedZoneID = ZoneGrid(zones: zones).zone(at: point)?.id
    }

    /// Configura el overlay para un monitor y sus zonas, sin resaltado.
    func configure(bounds: CGRect, zones: [Zone]) {
        self.bounds = bounds
        self.zones = zones
        highlightedZoneID = nil
    }
}
