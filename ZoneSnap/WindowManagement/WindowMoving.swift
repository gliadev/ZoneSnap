//
//  WindowMoving.swift
//  ZoneSnap
//
//  WindowManagement — puerto para mover ventanas.
//

import ApplicationServices
import CoreGraphics

/// Puerto: mueve y redimensiona ventanas (propias o ajenas).
///
/// El `frame` está en coordenadas globales top-left (las de la Accessibility
/// API). La implementación real (`AXWindowMover`) usa `AXUIElement`.
protocol WindowMoving: Sendable {
    /// Mueve la ventana enfocada de la app con el PID dado al frame indicado.
    func moveFocusedWindow(ofPID pid: pid_t, to frame: CGRect) throws
}

/// Errores al mover ventanas vía Accessibility API.
enum WindowMoverError: Error, Equatable {
    /// La app no tiene una ventana enfocada accesible.
    case noFocusedWindow
    /// Una operación de Accessibility falló (con su código de error).
    case axFailure(AXError)
}
