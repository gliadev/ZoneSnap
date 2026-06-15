//
//  AXWindowMover.swift
//  ZoneSnap
//
//  WindowManagement — adapter que mueve ventanas vía AXUIElement.
//

import ApplicationServices
import CoreGraphics

/// Implementación de `WindowMoving` con la Accessibility API.
///
/// Requiere permiso de Accesibilidad (gestionado por `AccessibilityAuthorizing`)
/// y que la app NO esté en sandbox. No es unit-testable (depende del window
/// server y de permisos); verificación manual. El cálculo del frame vive aparte
/// en `WindowFrameCalculator`.
struct AXWindowMover: WindowMoving {
    func moveFocusedWindow(ofPID pid: pid_t, to frame: CGRect) throws {
        let app = AXUIElementCreateApplication(pid)

        var focused: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &focused)
        guard result == .success, let windowRef = focused else {
            throw WindowMoverError.noFocusedWindow
        }
        let window = windowRef as! AXUIElement

        var origin = frame.origin
        var size = frame.size
        guard
            let positionValue = AXValueCreate(.cgPoint, &origin),
            let sizeValue = AXValueCreate(.cgSize, &size)
        else {
            throw WindowMoverError.axFailure(.failure)
        }

        try set(positionValue, attribute: kAXPositionAttribute, on: window)
        try set(sizeValue, attribute: kAXSizeAttribute, on: window)
    }

    /// Fija un `AXValue` ya construido en un atributo de la ventana.
    private func set(_ value: AXValue, attribute: String, on element: AXUIElement) throws {
        let error = AXUIElementSetAttributeValue(element, attribute as CFString, value)
        guard error == .success else {
            throw WindowMoverError.axFailure(error)
        }
    }
}
