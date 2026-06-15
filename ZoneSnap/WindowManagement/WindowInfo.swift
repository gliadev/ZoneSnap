//
//  WindowInfo.swift
//  ZoneSnap
//
//  WindowManagement — modelo de una ventana del sistema.
//

import CoreGraphics
import Foundation

/// Información de una ventana del sistema, tal como la reporta el window server.
///
/// `frame` está en coordenadas globales de CoreGraphics (origen arriba-izquierda,
/// `y` creciente hacia abajo) — las mismas que usan `CGWindowListCopyWindowInfo`
/// y la Accessibility API. Para mostrarla sobre `NSScreen` hay que convertirla
/// con `CoordinateConverter`.
struct WindowInfo: Identifiable, Sendable, Hashable {
    /// Identificador de ventana del window server (`kCGWindowNumber`).
    let id: CGWindowID

    /// Nombre de la app propietaria (`kCGWindowOwnerName`).
    let ownerName: String?

    /// Título de la ventana (`kCGWindowName`); a menudo vacío sin permiso de grabación.
    let title: String?

    /// PID del proceso propietario (`kCGWindowOwnerPID`).
    let ownerPID: pid_t

    /// Marco en coordenadas globales de CoreGraphics (top-left).
    let frame: CGRect

    /// Capa de la ventana (`kCGWindowLayer`); 0 = ventanas normales de apps.
    let layer: Int
}
