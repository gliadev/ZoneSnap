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
/// Requiere permiso de Accesibilidad (gestionado por `AccessibilityAuthorizing`).
/// Compatible con App Sandbox: la Accessibility API para controlar ventanas de
/// otras apps la gobierna el permiso de Accesibilidad (TCC), no el sandbox — por
/// eso ZoneSnap puede distribuirse en el Mac App Store (cf. Magnet, Moom, Swish).
/// No es unit-testable (depende del window server y de permisos); verificación
/// manual. El cálculo del frame vive aparte en `WindowFrameCalculator`.
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

    func focusedWindowFrame(ofPID pid: pid_t) throws -> CGRect {
        let app = AXUIElementCreateApplication(pid)

        var focused: CFTypeRef?
        guard
            AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &focused) == .success,
            let windowRef = focused
        else {
            throw WindowMoverError.noFocusedWindow
        }
        let window = windowRef as! AXUIElement

        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard
            AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef) == .success,
            AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef) == .success,
            let positionValue = positionRef, CFGetTypeID(positionValue) == AXValueGetTypeID(),
            let sizeValue = sizeRef, CFGetTypeID(sizeValue) == AXValueGetTypeID()
        else {
            throw WindowMoverError.axFailure(.failure)
        }

        var origin = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(positionValue as! AXValue, .cgPoint, &origin)
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
        return CGRect(origin: origin, size: size)
    }

    /// Fija un `AXValue` ya construido en un atributo de la ventana.
    private func set(_ value: AXValue, attribute: String, on element: AXUIElement) throws {
        let error = AXUIElementSetAttributeValue(element, attribute as CFString, value)
        guard error == .success else {
            throw WindowMoverError.axFailure(error)
        }
    }
}
