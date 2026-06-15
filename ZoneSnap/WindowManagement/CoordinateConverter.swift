//
//  CoordinateConverter.swift
//  ZoneSnap
//
//  WindowManagement — conversión entre espacios de coordenadas.
//

import CoreGraphics

/// Convierte rectángulos entre el espacio de AppKit (origen abajo-izquierda,
/// `y` hacia arriba — `NSScreen`) y el espacio global de CoreGraphics /
/// Accessibility (origen arriba-izquierda, `y` hacia abajo — `CGWindowList`,
/// `AXUIElement`).
///
/// La referencia es la altura total del display principal (aquel cuyo origen es
/// `(0,0)` en AppKit). La transformación es involutiva: aplicarla dos veces
/// devuelve el rectángulo original, por eso ambas direcciones comparten fórmula.
struct CoordinateConverter: Sendable, Equatable {
    /// Altura del display principal en puntos.
    let primaryHeight: CGFloat

    /// AppKit (bottom-left) → CoreGraphics / AX (top-left).
    func toTopLeft(_ rect: CGRect) -> CGRect {
        flippingVertically(rect)
    }

    /// CoreGraphics / AX (top-left) → AppKit (bottom-left).
    func toBottomLeft(_ rect: CGRect) -> CGRect {
        flippingVertically(rect)
    }

    /// Refleja el rectángulo respecto a la altura del display principal,
    /// preservando `x`, ancho y alto.
    private func flippingVertically(_ rect: CGRect) -> CGRect {
        CGRect(
            x: rect.minX,
            y: primaryHeight - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }
}
