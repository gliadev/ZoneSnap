//
//  SystemAccessibilityAuthorizer.swift
//  ZoneSnap
//
//  WindowManagement — adapter del permiso de Accesibilidad.
//

import ApplicationServices

/// Adapter: comprueba y solicita el permiso de Accesibilidad del sistema, que
/// ZoneSnap necesita para mover ventanas ajenas vía `AXUIElement` (F2b).
///
/// Verificación manual: el diálogo del sistema solo aparece con una app firmada
/// y ejecutándose.
struct SystemAccessibilityAuthorizer: AccessibilityAuthorizing {
    var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    @discardableResult
    func requestAccess() -> Bool {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
