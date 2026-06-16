//
//  KeyboardShortcut.swift
//  ZoneSnap
//
//  Domain — atajos de teclado del gestor de zonas.
//

import Foundation

/// Dirección de navegación entre zonas.
enum NavigationDirection: Equatable, Sendable {
    case next
    case previous
}

/// Acción que dispara un atajo de teclado sobre la ventana activa.
enum ShortcutAction: Equatable, Sendable {
    /// Mover la ventana activa a la zona con ese número (1-based, orden de lectura).
    case moveToZone(Int)
    /// Mover la ventana activa a la zona siguiente/anterior (con wrap-around).
    case navigate(NavigationDirection)
}

/// Tecla relevante para los atajos, independiente de AppKit (testeable). El
/// cableado traduce el `NSEvent` real a este tipo.
enum ShortcutKey: Equatable, Sendable {
    /// Dígito de fila superior (1…9).
    case digit(Int)
    case arrowLeft
    case arrowRight
}
